import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/buffers/buffers.dart';
import 'package:fl_new/measurements/data.dart';
import 'package:fl_new/scan_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

export 'plotting.dart';
export 'cloud_computation.dart';
export 'file_saving.dart';
export 'waveform_stream.dart';

abstract class AppFunction {
  @protected
  AppData get appData;
}

abstract class BufferedFunction {
  final FunctionBuffer buffer;

  BufferedFunction(this.buffer, {bool startImmediately = false});

  bool get started;

  void start();

  void stop();

  void toggle();
}

List<DataPoint> _makeZeroList(int length) {
  return List.generate(length, (_) => DataPoint(0, 0), growable: false);
}

int _getDownsampleLength(int originalLength) {
  final downsampledLength = originalLength ~/ 2;
  if (downsampledLength < 1) {
    throw ArgumentError.value(originalLength, "insufficent length");
  }
  return downsampledLength;
}

Iterable<DataPoint> downsampleChannel(List<DataPoint> data) {
  final int newLength;
  try {
    newLength = _getDownsampleLength(data.length);
  } on ArgumentError {
    throw ArgumentError.value(data, "list of insufficent length to downsample");
  }

  return Iterable.generate(newLength, (i) => data[i * 2]);
}

List<List<DataPoint>> downsampleChannels(List<List<DataPoint>> data) {
  assert(data.map((e) => e.length).every((len) => len == data[0].length));

  final int downsampledLength;
  try {
    downsampledLength = _getDownsampleLength(data[0].length);
  } on ArgumentError {
    throw ArgumentError.value(data, "list of insufficent length to downsample");
  }

  final numChannels = data.length;
  final List<List<DataPoint>> downsampledData = List.generate(
    numChannels,
    (_) => _makeZeroList(downsampledLength),
    growable: false,
  );

  for (int i = 0; i < downsampledLength; i++) {
    for (int ch = 0; ch < numChannels; ch++) {
      downsampledData[ch][i] = data[ch][i * 2];
    }
  }

  return downsampledData;
}

BuildContext suitableParentContext(BuildContext childContext) =>
    childContext.findAncestorStateOfType<State<FindDevicesScreen>>()!.context;
