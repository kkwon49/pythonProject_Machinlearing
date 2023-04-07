import 'dart:async';
import 'dart:collection';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'buffers/buffers.dart';

class _ConnectionData {
  final Connection connection;
  final Map<Measurement, List<NotifyingStreamBuffer>> notifierMap = {};
  final Map<NotifyingStreamBuffer, Measurement> measurementMap = {};
  final List<DataStream> dataStreams;
  final Map<NotifyingStreamBuffer, DataStream> _streamMap = {};

  Duration? getStartSinceEpoch(NotifyingStreamBuffer notifier) {
    return _streamMap[notifier]?.startTime;
  }

  bool contains(NotifyingStreamBuffer buffer) =>
      measurementMap.containsKey(buffer);

  // int getChannel(NotifyingStreamBuffer notifier) {
  //   DataStream ds = _streamMap[notifier]!;
  //   return ds.streams.indexOf(notifier.stream);
  // }

  _ConnectionData(this.connection, this.dataStreams) {
    for (DataStream ds in dataStreams) {
      notifierMap[ds.measurement] = [];
      for (Stream<List<DataPoint>> s in ds.streams) {
        // initialize buffer
        NotifyingStreamBuffer b = NotifyingStreamBuffer(s);

        // add buffer to this measurement's list of buffers
        notifierMap[ds.measurement]!.add(b);

        // link buffer to a measurement
        measurementMap[b] = ds.measurement;

        // save reference to the buffer's original datastream
        _streamMap[b] = ds;
      }
    }

    // start buffers after all are made
    for (var buffers in notifierMap.values) {
      for (var b in buffers) {
        b.start();
      }
    }

    connection.device.state.listen((event) {
      if (event == BluetoothDeviceState.disconnected ||
          event == BluetoothDeviceState.disconnecting) {
        for (var buffers in notifierMap.values) {
          for (var b in buffers) {
            b.stop();
          }
        }
      }
    });
  }
}

class AppData {
  final Map<Connection, _ConnectionData> _connectionData = {};

  AppData();

  AppData.single(Connection connection, List<DataStream> dataStreams) {
    _connectionData[connection] = _ConnectionData(connection, dataStreams);
  }

  /// Constructor for multiple `Connection` objects.
  AppData.multiple(Map<Connection, List<DataStream>> connections) {
    connections.forEach((c, ds) => _connectionData[c] = _ConnectionData(c, ds));
  }

  Duration? getStartSinceEpoch(NotifyingStreamBuffer notifier) {
    // return notifierMap[notifier]?.startTime;
    return _connectionData.values
        .singleWhere((cd) => cd.contains(notifier))
        .getStartSinceEpoch(notifier);
  }

  Map<Measurement, List<NotifyingStreamBuffer>> get notifierMap =>
      _connectionData.values.fold(
        {},
        (accumulatedMap, cData) => accumulatedMap..addAll(cData.notifierMap),
      );

  List<BluetoothService> get services => _connectionData.keys
      .map((e) => e.services)
      .expand((element) => element)
      .toList();

  List<DataStream> get dataStreams => _connectionData.values
      .map((e) => e.dataStreams)
      .expand((element) => element)
      .toList();

  List<Connection> get connections => _connectionData.keys.toList();

  add(Connection connection, List<DataStream> dataStreams) {
    _connectionData[connection] = _ConnectionData(connection, dataStreams);
  }

  bool remove(Connection connection) {
    return _connectionData.remove(connection) != null;
  }
}
