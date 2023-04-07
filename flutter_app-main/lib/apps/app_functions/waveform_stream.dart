import 'dart:io';

import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/app_connection_model.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../buffers/buffers.dart';

const String _username = "gtChoa";
const String _password = "G0Jackets";

/// For streaming to GTRI server, currently only supported by CHOA.
mixin WaveformStream<T extends StatefulWidget> on State<T>
    implements AppFunction {
  static const Duration _sendPeriod = Duration(seconds: 5);
  final List<_WaveformStream> _waveformStreams = [];
  bool _started = false;
  late final VoidCallback _dispose;

  @override
  @protected
  AppData get appData;

  @protected
  String get routingName;

  @protected
  bool get wantStreaming => false;

  @protected
  List<Measurement> get ignoredMeasurements => [];

  void _initialize() {
    ConnectionGroup connectionGroup =
        Provider.of<ConnectionGroup>(context, listen: false);

    final onGroupUpdate = () => _updateFromGroup(connectionGroup);
    connectionGroup.addListener(onGroupUpdate);
    _dispose = () => connectionGroup.removeListener(onGroupUpdate);
    _updateFromGroup(connectionGroup);
  }

  /// Starts streaming to the cloud if not already doing so. Should only be
  /// called in stateful widget `build` methods.
  @protected
  void startStreaming() async {
    if (!_started) {
      _initialize();
      // begin updating with group device connections/disconnections
      // ConnectionGroup connectionGroup = Provider.of<ConnectionGroup>(context);
      // connectionGroup.addListener(() => _updateFromGroup(connectionGroup));

      // // make streams for connected group devices and enable streaming
      // _updateFromGroup(connectionGroup);
      for (_WaveformStream waveformStream in _waveformStreams) {
        waveformStream.start();
      }
      _started = true;
    }
  }

  /// Stops streaming to the cloud if already doing so. Should only be
  /// called in stateful widget `build` methods.
  @protected
  void stopStreaming() async {
    if (_started) {
      // stop updating with group
      // ConnectionGroup connectionGroup = Provider.of<ConnectionGroup>(context);
      // connectionGroup.removeListener(() => _updateFromGroup(connectionGroup));

      _dispose();

      // stop current streams from continuing to stream
      for (_WaveformStream waveformStream in _waveformStreams) {
        waveformStream.stop();
        _waveformStreams.remove(waveformStream);
      }
      _started = false;
    }
  }

  /// Updates `_waveformStreams` to reflect the currently connected devices
  /// in this `connectionGroup`.
  void _updateFromGroup(ConnectionGroup connectionGroup) {
    _waveformStreams.clear();

    final compatibleMeasurement = connectionGroup.connectedMeasurements.where(
      (measurement) =>
          !ignoredMeasurements.contains(measurement) &&
          (measurement.signal.type == SignalType.ppg ||
              measurement.signal.type == SignalType.ecg),
    );

    for (Measurement measurement in compatibleMeasurement) {
      final newBuffer = FunctionBuffer(
        appData,
        measurement,
        rollover: _sendPeriod,
      );

      final relevantConnection = connectionGroup.getConnection(measurement)!;

      _WaveformStream _waveformStream = _WaveformStream(
        newBuffer,
        connection: relevantConnection,
        projectName: routingName,
      );

      _waveformStreams.add(_waveformStream);
    }
  }
}

/// `_WaveformStream`s send data to the cloud using the `send` instance method
/// if streaming is currently permitted. Streaming is disabled upon
/// initialization by default, but this can be overridden with the
/// `startImmediately` constructor argument. Streaming can be controlled after
/// initialization with the `wantStreaming` setter or the `toggleStream` instance method.
class _WaveformStream extends BufferedFunction {
  static const _url = "messaging.dev.hips.gtri.org";
  static const _port = "1883";

  late final String _topic;
  final Connection connection;
  MqttClient? _client;
  final String projectName;
  int? _patientId;
  bool _stream;
  final String _measurementId;

  final Duration sendInterval = const Duration(seconds: 1);

  _WaveformStream(
    super.buffer, {
    required this.connection,
    required this.projectName,
    super.startImmediately,
  })  : assert(
          buffer.measurement.signal.type == SignalType.ppg ||
              buffer.measurement.signal.type == SignalType.ecg,
          "Only ECG, PPG supported",
        ),
        _measurementId = buffer.measurement.signal.type.name.toLowerCase(),
        _stream = startImmediately {
    _topic = "oban/${connection.device.id}/$_measurementId/json";
    _resolveClient();
  }

  void _resolveClient() async {
    final settings = await SharedPreferences.getInstance();
    _patientId = settings.getInt('patientNumber') ?? 100;

    _client = MqttServerClient(_url, _port);
    _client
      ?..keepAlivePeriod = 20 // seconds
      ..connectTimeoutPeriod = 3000 // milliseconds
      ..autoReconnect = true
      ..connectionMessage =
          MqttConnectMessage().authenticateAs(_username, _password);

    try {
      await _client?.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      _client?.disconnect();
      return;
    } on SocketException catch (e) {
      // Raised by the socket layer
      _client?.disconnect();
      return;
    }

    _client?.subscribe(_topic, MqttQos.exactlyOnce);
  }

  void _bufferCallback() => send(buffer.mostRecent);

  @override
  bool get started => _stream;

  @override
  void start() {
    buffer.addListener(() => _bufferCallback());
    _stream = true;
  }

  @override
  void stop() {
    buffer.removeListener(() => _bufferCallback());
    _stream = false;
  }

  @override
  void toggle() {
    _stream ? stop() : start();
  }

  /// Formats the passed channel data `data`, which must not be empty.
  String _formatRequest(List<List<DataPoint>> data) {
    assert(data.isNotEmpty && data[0].isNotEmpty,
        "Cannot format empty data for streaming.");

    Map<String, dynamic> toSerialize = {};

    if (buffer.measurement.signal.type == SignalType.ecg) {
      // build payload entry for a single point in time
      toSerialize = {
        'id': _patientId,
        'time': data.first.first.x,
        'value': data.first.map((datapoint) => datapoint.y).toList(),
      };
    } else if (buffer.measurement.signal.type == SignalType.ppg) {
      final red = data[0];
      final ir = data[1];

      toSerialize = {
        'id': _patientId,
        'time': red.first.x,
        'red': red.map((datapoint) => datapoint.y).toList(),
        'ir': ir.map((datapoint) => datapoint.y).toList(),
      };
    }

    return jsonEncode(toSerialize);
  }

  /// Sends `data` to a cloud server. `data` contains the channels of a
  /// measurement in the first indexable position, and the contents of
  /// those channels in the second. Channels are assumed to be time-aligned,
  /// that is the `DataPoint`s in the i-th position for all channels have the
  /// same `x` (i.e. time) fields.
  Future<void> send(List<List<DataPoint>> data) async {
    if (_stream && _patientId != null && data.isNotEmpty) {
      // construct plaintext payload
      String payload = _formatRequest(data);
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      do {
        // auto reconnect if disconnected between sends
        _client?.doAutoReconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      } while (
          _client?.connectionStatus?.state == MqttConnectionState.connecting);

      if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
        // Publish if we are connected
        _client?.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
        print("Published to $_topic");
      } else {
        print("Failed to publish");
      }
    }
  }
}
