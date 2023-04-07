import 'dart:typed_data';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/apps/device.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';

class FdcPressureSensor extends StatefulWidget implements AbstractApp {
  static const List<Device> devices = [
    Device([
      Measurement(
        Signal(
          SignalType.pressure,
          serviceUuid: "228bae90-35fd-875f-39fe-b2a394d28057",
          charUuid: "228bae91-35fd-875f-39fe-b2a394d28057",
        ),
        bitLength: 32,
        sampleRate: 10,
        conversion: 1 / 134217728,
        channels: 4,
        endian: Endian.little,
      ),
    ])
  ];

  @override
  String get name => "Ira's Pressure Sensor";

  @override
  bool get navigateOnNewConnection => true;

  @override
  final AppData appData;

  const FdcPressureSensor(this.appData, {Key? key}) : super(key: key);

  @override
  State<FdcPressureSensor> createState() => _FdcPressureSensorState();
}

class _FdcPressureSensorState extends State<FdcPressureSensor>
    with FileSaving, Plotting {
  @override
  AppData get appData => throw UnimplementedError();

  @override
  String get projectName => widget.name;

  @override
  Widget build(BuildContext context) {
    return makePlot(FdcPressureSensor.devices[0].measurements[0]);
    // return Column(
    //   children: List.generate(
    //     FdcPressureSensor.devices[0].measurements[0].channels,
    //     (i) => makePlot(
    //       FdcPressureSensor.devices[0].measurements[0],
    //       channel: i,
    //       title: "Channel $i",
    //     ),
    //   ),
    // );
  }
}
