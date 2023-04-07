import 'dart:typed_data';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:fl_new/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:provider/provider.dart';

class ChoaPatch extends StatefulWidget implements AbstractApp {
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
        // Measurement(
        //   _ppg,
        //   sampleRate: 50,
        //   bitLength: 18,
        //   endian: Endian.big,
        //   conversion: 1 / 262144.0 * 16384.0,
        //   channels: 2,
        //   key: ValueKey(1),
        // ),
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
    Device([
      Measurement(_ppg,
          sampleRate: 50,
          bitLength: 18,
          endian: Endian.big,
          conversion: 1 / 262144.0 * 16384.0,
          channels: 2,
          key: ValueKey(4))
    ])
  ];

  @override
  String get name => 'CHOA Patch';

  @override
  bool get navigateOnNewConnection => false;

  @override
  final AppData appData;

  const ChoaPatch(this.appData, {Key? key}) : super(key: key);

  @override
  State<ChoaPatch> createState() => _ChoaPatchState();
}

class _ChoaPatchState extends State<ChoaPatch>
    with Plotting, CloudComputation, FileSaving {
  BuildContext? _parentContext;

  @override
  void initState() {
    super.initState();
    startSaving();
  }

  @override
  void didChangeDependencies() {
    _parentContext ??= suitableParentContext(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    stopSaving(_parentContext);
    super.dispose();
  }

  @override
  String get projectName => widget.name;

  @override
  AppData get appData => widget.appData;

  @override
  bool get wantCloudSaving => true;

  @override
  bool get wantLocalSaving => true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: makePlot(ChoaPatch.devices[1].measurements[0],
                          channel: 0, title: "PPG Red"),
                    ),
                    Expanded(
                      child: makePlot(ChoaPatch.devices[1].measurements[0],
                          channel: 1, title: "PPG IR"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: makePlot(ChoaPatch.devices[0].measurements[0],
                    channel: 0, title: "ECG"),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.center,
            child: GridView.count(
              shrinkWrap: true,
              mainAxisSpacing: 30,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              children: <Widget>[
                makeCloudWidget(
                  ApiFunction.bloodOxygen,
                  ChoaPatch.devices[1].measurements[0],
                  outboundMemory: const Duration(seconds: 10),
                  outboundInterval: const Duration(seconds: 5),
                ),
                makeCloudWidget(
                  ApiFunction.temperature,
                  ChoaPatch.devices[0].measurements[1],
                  outboundInterval: const Duration(seconds: 10),
                  outboundMemory: const Duration(seconds: 10),
                ),
                makeCloudWidget(
                  ApiFunction.heartRate,
                  ChoaPatch.devices[0].measurements[0],
                  outboundInterval: const Duration(seconds: 7),
                  outboundMemory: const Duration(seconds: 10),
                ),
                makeCloudWidget(
                  ApiFunction.respirationRate,
                  ChoaPatch.devices[0].measurements[0],
                  outboundInterval: const Duration(seconds: 4),
                  outboundMemory: const Duration(seconds: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
