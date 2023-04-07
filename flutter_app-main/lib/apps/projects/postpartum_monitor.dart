import 'dart:typed_data';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:provider/provider.dart';

class PostpartumMonitor extends StatefulWidget implements AbstractApp {
  static const Signal _ecg = Signal(
    SignalType.ecg,
    serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000eef1-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _ppg = Signal(
    SignalType.ppg,
    serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000aec1-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _temperature = Signal(
    SignalType.temperature,
    serviceUuid: "228b0fe0-35fd-875f-39fe-b2a394d28057",
    charUuid: "00000fe2-0000-1000-8000-00805f9b34fb",
  );

  static const List<Device> devices = [
    Device([
      Measurement(
        _ecg,
        bitLength: 24,
        sampleRate: 250,
        endian: Endian.big,
        conversion: 1 / 8388607.0 * 2.42,
      ),
      Measurement(
        _ppg,
        sampleRate: 50,
        bitLength: 18,
        endian: Endian.big,
        conversion: 1 / 262144.0 * 16384.0,
        channels: 2,
        reversePolarity: true,
      ),
      Measurement(
        _temperature,
        sampleRate: 1,
        bitLength: 16,
        endian: Endian.little,
        conversion: 1 / 32768.0 * 256.0,
      )
    ]),
  ];

  static const List<Signal> _signals = [_ecg, _ppg, _temperature];

  // static const Signature signature = Signature(_signals);

  @override
  final AppData appData;

  @override
  String get name => "Postpartum Monitor v2";

  const PostpartumMonitor(this.appData, {Key? key}) : super(key: key);

  @override
  State<PostpartumMonitor> createState() => _PostpartumMonitorState();

  @override
  bool get navigateOnNewConnection => true;
}

class _PostpartumMonitorState extends State<PostpartumMonitor>
    with FileSaving, Plotting, CloudComputation, WaveformStream {
  @override
  String get routingName => widget.name;

  @override
  String get projectName => widget.name;

  @override
  AppData get appData => widget.appData;

  @override
  bool get wantCloudSaving => false;

  @override
  bool get wantLocalSaving => true;

  @override
  void initState() {
    super.initState();
    startSaving();
    startStreaming();
  }

  @override
  void dispose() {
    stopSaving();
    stopStreaming();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: makePlot(
                    PostpartumMonitor.devices[0].measurements[1],
                    channel: 1,
                  ),
                  flex: 4),
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.bloodOxygen,
                  PostpartumMonitor.devices[0].measurements[1],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: makePlot(
                  PostpartumMonitor.devices[0].measurements[0],
                ),
                flex: 4,
              ),
              // Expanded(
              //   child: makeCloudWidget(ApiFunction.heartRate,
              //       PostpartumMonitor.devices.first.measurements[0],),
              // ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: makePlot(
                    PostpartumMonitor.devices[0].measurements[2],
                  ),
                  flex: 4),
              // Expanded(
              //   child: makeCloudWidget(ApiFunction.temperature,
              //       PostpartumMonitor.devices.first.measurements[2]),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
