import 'dart:typed_data';
import 'dart:ui';
import 'package:fl_new/connections/signals.dart';
import 'package:flutter/cupertino.dart';
import '../connections/signals.dart';
import 'dart:math';

export 'data.dart' show DataStream, DataPoint, Packet, Timestamp;

/// Apps declare `Measurement`s to detail the parameters needed to parse each
/// measurement's corresponding `Signal` (i.e. BLE characteristic).
class Measurement {
  final Signal signal;
  final int channels;
  final int sampleRate;
  final Endian endian;
  final double conversion;
  final bool reversePolarity;
  final int bitLength;
  final bool signed;
  final double Function(double) yMap;
  final Key? key;

  static double _identity(double value) => value;

  const Measurement(this.signal,
      {required this.bitLength,
      required this.endian,
      required this.sampleRate,
      this.reversePolarity = false,
      this.signed = false,
      this.conversion = 1,
      this.channels = 1,
      this.yMap = _identity,
      this.key});

  @override
  bool operator ==(Object other) =>
      other is Measurement &&
      other.runtimeType == runtimeType &&
      other.signal == signal &&
      other.channels == channels &&
      other.sampleRate == sampleRate &&
      other.endian == endian &&
      other.conversion == conversion &&
      other.reversePolarity == reversePolarity &&
      other.bitLength == bitLength &&
      other.signed == signed &&
      other.yMap == yMap &&
      other.key == key;

  @override
  get hashCode => Object.hashAll([
        signal,
        channels,
        sampleRate,
        endian,
        conversion,
        reversePolarity,
        bitLength,
        signed,
        yMap,
        key
      ]);

  String get name => signal.name;
}
