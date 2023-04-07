import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'dart:math';

typedef Packet = List<int>;

class Timestamp {
  static final Timestamp _singleton = Timestamp._internal();
  Duration? offset;

  Timestamp._internal() {
    _setOffset();
    Timer.periodic(
      const Duration(minutes: 10),
      (_) => _setOffset(),
    );
  }

  Future<void> _setOffset() async {
    DateTime now = DateTime.now();

    int? offsetMillis;
    try {
      /// try getting system time's offset from NTP server
      offsetMillis = await NTP.getNtpOffset(localTime: now.toLocal());
    } on SocketException {
      // no connection established with server
      offsetMillis = null;
    }

    if (offsetMillis != null) {
      offset = Duration(milliseconds: offsetMillis);
    }
  }

  factory Timestamp() {
    return _singleton;
  }

  /// Returns a `DateTime` instance corrected for local time drift from
  /// current time.
  ///
  /// If a `DateTime` (non-nullable) must be used,
  /// `DateTime.now()` should be used instead, as this function cannot be
  ///  guaranteed to return.
  DateTime? now() {
    if (offset != null) {
      return DateTime.now().add(offset!);
    }
    return null;
  }
}

/// Returns current system time adjusted to better match true time. See
/// https://en.wikipedia.org/wiki/Network_Time_Protocol.
Future<DateTime> getAdjustedSystemTime() async {
  DateTime now = DateTime.now();
  Duration offset = await getSystemOffset();
  return now..add(offset);
}

Future<Duration> getSystemOffset() async {
  DateTime now = DateTime.now();
  int millisOffset = await NTP.getNtpOffset(localTime: now.toLocal());
  return Duration(milliseconds: millisOffset);
}

/// A `DataPoint` oject represents a single time-stamped measurement.
class DataPoint {
  final double x;
  double y;
  bool useIsoSerialization = true;

  DataPoint.fromEpoch(this.y)
      : x = (DateTime.now().millisecondsSinceEpoch / 1000).toDouble();

  DataPoint(this.x, this.y);

  String toIso() {
    return DateTime.fromMillisecondsSinceEpoch((x * 1000).toInt())
        .toUtc()
        .toIso8601String();
  }

  String toJson() {
    String timestamp;
    if (useIsoSerialization) {
      timestamp = toIso();
    } else {
      timestamp = x.toString();
    }
    return '{"$timestamp" : $y}';
  }

  void negate() => y = -y;

  @override
  bool operator ==(Object other) =>
      other is DataPoint &&
      other.runtimeType == runtimeType &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => hashValues(x, y);
}

/// A `DataStream` instance abstracts the identification, control, and
/// interfacing needed to handle `stream`s carrying data for plotting.
/// Each `stream` in a `DataStream` object's `streams` attribute is a
/// channel of the `measurement` passed when the object was created. Each
/// channel periodically emits fixed-length DataPoint lists containing
/// time-stamped data for the specified `measurement`.
class DataStream {
  final Measurement measurement;
  final Stream<Packet> inStream; // a single characteristic from device
  final int _byteLength;
  final List<StreamController<List<DataPoint>>> _controllers;
  final Connection connection;
  late final Duration startTime;
  late final int _bitmask;
  late final List<Stream<List<DataPoint>>> streams; // output channels
  late final List<double> _trailingTimes;

  DataStream(this.inStream,
      {required this.measurement,
      required this.connection,
      DateTime? startOverride})
      : _trailingTimes = List.filled(measurement.channels, 0.0),
        _byteLength = (measurement.bitLength / 8).ceil(),
        _controllers = List.generate(
          measurement.channels,
          (_) => StreamController.broadcast(),
        ) {
    if (startOverride == null) {
      startTime = _timeSinceEpoch();
    } else {
      int startMillis = startOverride.millisecondsSinceEpoch;
      startTime = Duration(milliseconds: startMillis);
    }

    // make bitmask
    String stringMask = List.filled(measurement.bitLength, 1).join();
    _bitmask = int.parse(stringMask, radix: 2);

    // make output streams
    streams = _makeStreams();
  }

  /// returns current time since epoch in milliseconds as a Duration.
  static Duration _timeSinceEpoch() {
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: currentTime);
  }

  /// helper method for constructor
  List<Stream<List<DataPoint>>> _makeStreams() {
    List<Stream<List<DataPoint>>> streams = [];

    StreamSubscription inStreamSubscription = inStream.listen((Packet packet) {
      // this callback handles all received packets
      Duration deltaT = _timeSinceEpoch() - startTime;
      // double timestamp = deltaT.inMilliseconds.toDouble() / 1000;
      // _processPacket(packet, timestamp);
      _processPacket(
          packet, DateTime.now().millisecondsSinceEpoch.toDouble() / 1000);
    });

    connection.stateNotifier.addListener(() {
      if (connection.disconnected) {
        inStreamSubscription.cancel();
      }
    });

    // assign each channel of the measurement to a stream
    for (var ch = 0; ch < measurement.channels; ch++) {
      streams.add(_controllers[ch].stream);
    }
    return streams;
  }

  /// Parses `packet`, handling the byte data to integer conversion and
  /// the distribution of value to the correct channel stream. `packetTime`
  /// is the number of seconds since beginning listening to `inStream` when
  /// the `packet` is received.
  void _processPacket(Packet packet, double packetTime) {
    for (var ch = 0; ch < measurement.channels; ch++) {
      double timestamp; // to be determined
      int bytesPerChannel =
          measurement.sampleRate * _byteLength * measurement.channels;

      var packetDuration = packet.length / bytesPerChannel;
      var possibleStart = _trailingTimes[ch] + 1 / measurement.sampleRate;
      var discrepancy = packetTime - possibleStart;

      // handle packet drop
      if (discrepancy >= packetDuration) {
        // packet drop: not aligned with previous
        timestamp = packetTime;
      } else if (discrepancy < 0 && discrepancy.abs() >= packetDuration) {
        // packet arrived before the predicted end of the previous: ignore this packet
        return;
      } else {
        // normal/slightly delayed start aligned with previous packet
        timestamp = possibleStart;
      }

      if (packet.isNotEmpty && !_controllers[ch].isClosed) {
        // process packet
        _controllers[ch].add(_parse(packet, ch, timestamp));
      }
    }
  }

  int _decode(ByteData data) {
    // Start with a 32-bit zero, and add shifted byte values to form correct
    // number. This wastes some memory, but gives flexibility in processing
    // variable byte-length BLE packets.
    int decoded = 0;
    for (int b = 0; b < _byteLength; b++) {
      int byteValue = data.getUint8(b);
      if (measurement.endian == Endian.big) {
        decoded += byteValue << 8 * (_byteLength - 1 - b);
      } else if (measurement.endian == Endian.little) {
        decoded += byteValue << 8 * b;
      } else {
        throw UnimplementedError("Endian other than big or little.");
      }
    }

    decoded = decoded & _bitmask;
    if (measurement.signed) {
      decoded = decoded.toSigned(measurement.bitLength);
    }

    return decoded;
  }

  /// Parses the `ch`-th channel of the `packet` received at `packetTime`
  /// milliseconds since epoch.
  List<DataPoint> _parse(Packet packet, int ch, double packetTime) {
    if (packet.isEmpty) {
      return <DataPoint>[];
    }

    TypedData rawBytes = Uint8List.fromList(packet);
    ByteData bytes = ByteData.view(rawBytes.buffer);
    int inputLength = bytes.lengthInBytes;
    int step =
        _byteLength * measurement.channels; // channel value-to-value distance

    // preallocate for speed: note that this creates a fixed-length list
    List<DataPoint> data =
        List.filled(inputLength ~/ step, DataPoint(0.0, 0.0));

    // i is index in byte array, pointing to the heads of target sub-arrays
    // i increments enough to land on the next instance of channel data within
    // this packet
    for (int i = ch * _byteLength; i < inputLength; i += step) {
      // index specific to this channel, i.e. a channel's zeroeth, first, etc. value
      int channelPos = i ~/ step;

      // get integer value from byte segment
      int decoded = _decode(ByteData.sublistView(rawBytes, i, i + _byteLength));

      // convert to meaningful units
      double y = decoded.toDouble() * measurement.conversion;

      if (measurement.reversePolarity) {
        y = -y;
      }

      if (measurement.yMap != null) {
        y = measurement.yMap(y);
      }

      // linearly interpolate time stamps
      double x = packetTime + (channelPos / measurement.sampleRate);

      // assign value to channel-specific position
      data[channelPos] = DataPoint(x, y);
    }

    // update time-keeping
    _trailingTimes[ch] = data.isEmpty ? _trailingTimes[ch] : data.last.x;

    return data;
  }
}
