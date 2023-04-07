import 'dart:typed_data';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';

class EthiopiaProject extends StatefulWidget implements AbstractApp {
  static const Signal _ecg = Signal(
    SignalType.ecg,
    serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000eef1-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _temperature = Signal(
    SignalType.temperature,
    serviceUuid: "228b0fe0-35fd-875f-39fe-b2a394d28057",
    charUuid: "00000fe2-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _ppg = Signal(
    SignalType.ppg,
    serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baec1-35fd-875f-39fe-b2a394d28057",
  );

  static const List<Device> devices = [
    Device([
      Measurement(
        _ecg,
        bitLength: 24,
        sampleRate: 250,
        endian: Endian.big,
        conversion: 1 / 8388607.0 * 2.42,
        reversePolarity: true,
      ),
      Measurement(
        _temperature,
        sampleRate: 1,
        bitLength: 16,
        endian: Endian.little,
        conversion: 1 / 32768.0 * 256.0,
      ),
    ]),
    Device([
      Measurement(_ppg,
          sampleRate: 50,
          bitLength: 18,
          endian: Endian.big,
          conversion: 1 / 262144.0 * 16384.0,
          channels: 2)
    ])
  ];

  @override
  String get name => 'Ethiopia Biopatch';

  @override
  final AppData appData;

  const EthiopiaProject(this.appData, {Key? key}) : super(key: key);

  @override
  State<EthiopiaProject> createState() => _EthiopiaProjectState();

  @override
  bool get navigateOnNewConnection => true;
}

class _EthiopiaProjectState extends State<EthiopiaProject>
    with Plotting, FileSaving, CloudComputation {
  @override
  void initState() {
    super.initState();
    startSaving();
  }

  @override
  void dispose() => super.dispose();

  @override
  String get projectName => widget.name;

  @override
  AppData get appData => widget.appData;

  @override
  bool get wantCloudSaving => false;

  @override
  bool get wantLocalSaving => true;

  Widget _makeCloudGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.heartRate,
                  EthiopiaProject.devices[0].measurements[0],
                ),
              ),
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.respirationRate,
                  EthiopiaProject.devices[0].measurements[0],
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
                  EthiopiaProject.devices[1].measurements[0],
                ),
              ),
              Expanded(
                child: makeCloudWidget(
                  ApiFunction.temperature,
                  EthiopiaProject.devices[0].measurements[1],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  List<Widget> _buildScreenChildren({int plotFlex = 1}) {
    return [
      Flexible(
        flex: plotFlex,
        child: Column(
          children: [
            Expanded(
              child: makePlot(EthiopiaProject.devices[1].measurements[0],
                  channel: 1,
                  timeSpan: const Duration(seconds: 5),
                  title: "PPG"),
            ),
            Expanded(
              child: makePlot(EthiopiaProject.devices[0].measurements[0],
                  channel: 0,
                  timeSpan: const Duration(seconds: 5),
                  title: "ECG"),
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
          return Row(children: _buildScreenChildren(plotFlex: 2));
        }
        return Column(children: _buildScreenChildren(plotFlex: 1));
      },
    );
  }
}
