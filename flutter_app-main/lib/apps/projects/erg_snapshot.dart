import 'dart:typed_data';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:fl_new/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ERGSnapshot extends StatefulWidget implements AbstractApp {
  static const _erg = Signal(
    SignalType.erg,
    serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000eef1-0000-1000-8000-00805f9b34fb",
  );

  static const List<Measurement> measurements = [
    Measurement(
      _erg,
      sampleRate: 1000,
      bitLength: 24,
      endian: Endian.big,
      conversion: 1,
      signed: true,
    ),
  ];

  @override
  final AppData appData;

  @override
  String get name => "ERG Snapshot";

  @override
  final ValueNotifier<bool> disconnect;

  @override
  final void Function(List<Widget>) registerWidgets;

  const ERGSnapshot(this.appData, this.disconnect, this.registerWidgets,
      {Key? key})
      : super(key: key);

  @override
  State<ERGSnapshot> createState() => _EEGSnapshotState();

  @override
  bool get navigateOnNewConnection => true;
}

class _EEGSnapshotState extends State<ERGSnapshot> with FileSaving, Plotting {
  @override
  String get projectName => widget.name;

  @override
  AppData get appData => widget.appData;

  @override
  bool get wantCloudSaving => true;

  @override
  bool get wantLocalSaving => true;

  @override
  void initState() {
    super.initState();
    startSaving();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 4,
        child: BorderedContainer(
          child: makePlot(ERGSnapshot.measurements[0]),
          label: "Waveform",
        ),
      ),
    ]);
  }
}
