import 'dart:typed_data';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:fl_new/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:provider/provider.dart';

class PpgChoaPatch extends StatefulWidget implements AbstractApp {
  static const Signal _ecg = Signal(
    SignalType.ecg,
    serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000eef1-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _ppg = Signal(
    SignalType.ppg,
    serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baec1-35fd-875f-39fe-b2a394d28057",
  );

  static const Signal _acc = Signal(
    SignalType.acceleration,
    serviceUuid: "228ba3a0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000a3a5-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _temperature = Signal(
    SignalType.temperature,
    serviceUuid: "228b0fe0-35fd-875f-39fe-b2a394d28057",
    charUuid: "00000fe2-0000-1000-8000-00805f9b34fb",
  );

  static const List<Device> devices = [
    Device(
      [
        Measurement(
          _ecg,
          bitLength: 24,
          sampleRate: 250,
          endian: Endian.big,
          conversion: 1 / 8388607.0 * 2.42,
          reversePolarity: true,
          key: ValueKey(0),
        ),
        Measurement(
          _ppg,
          sampleRate: 50,
          bitLength: 18,
          endian: Endian.big,
          conversion: 1 / 262144.0 * 16384.0,
          channels: 2,
          key: ValueKey(1),
        ),
        Measurement(
          _temperature,
          sampleRate: 1,
          bitLength: 16,
          endian: Endian.little,
          conversion: 1 / 32768.0 * 256.0,
          key: ValueKey(2),
        ),
        Measurement(
          _acc,
          signed: true,
          channels: 3,
          sampleRate: 250,
          bitLength: 24,
          endian: Endian.big,
          conversion: 1 / 16.0 / 524288.0 * 2.048,
          key: ValueKey(3),
        ),
      ],
    ),
  ];

  @override
  String get name => 'PPG CHOA Patch';

  @override
  bool get navigateOnNewConnection => false;

  @override
  final AppData appData;

  const PpgChoaPatch(this.appData, {Key? key}) : super(key: key);

  @override
  State<PpgChoaPatch> createState() => _PpgChoaPatch();
}

class _PpgChoaPatch extends State<PpgChoaPatch>
    with Plotting, CloudComputation, FileSaving, WaveformStream {
  @override
  void initState() {
    super.initState();
    // startStreaming();
  }

  @override
  void dispose() {
    // stopStreaming();
    super.dispose();
  }

  @override
  String get projectName => widget.name;

  @override
  AppData get appData => widget.appData;

  @override
  bool get wantCloudSaving => false;

  @override
  bool get wantLocalSaving => true;

  @override
  String get routingName => "GT_CHOA";

  Widget _makeCloudGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.heartRate,
                  PpgChoaPatch.devices[0].measurements[0],
                ),
              ),
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.respirationRate,
                  PpgChoaPatch.devices[0].measurements[0],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.bloodOxygen,
                  PpgChoaPatch.devices[0].measurements[1],
                ),
              ),
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.temperature,
                  PpgChoaPatch.devices[0].measurements[2],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  List<Widget> _buildScreenChildren() {
    return [
      Flexible(
        flex: 2,
        child: Column(
          children: [
            Expanded(
              child: makePlot(
                PpgChoaPatch.devices[0].measurements[1],
                channel: 0,
                timeSpan: const Duration(
                  seconds: 5,
                ),
              ),
            ),
            Expanded(
              child: makePlot(
                PpgChoaPatch.devices[0].measurements[1],
                channel: 1,
                timeSpan: const Duration(seconds: 5),
              ),
            ),
            Expanded(
              child: makePlot(
                PpgChoaPatch.devices[0].measurements[0],
                channel: 0,
                timeSpan: const Duration(
                  seconds: 5,
                ),
              ),
            ),
          ],
        ),
      ),
      Flexible(
        child: _makeCloudGrid(),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return Row(children: _buildScreenChildren());
        }
        return Column(children: _buildScreenChildren());
      },
    );
  }
}
