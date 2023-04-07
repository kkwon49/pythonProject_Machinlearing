import 'dart:typed_data';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/apps.dart';

class PressureSensor extends StatefulWidget implements AbstractApp {
  static const Signal _pressure = Signal(
    SignalType.ecg,
    serviceUuid: "228ba730-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000a731-0000-1000-8000-00805f9b34fb",
  );

  static double shiftY(double value) => ((value / 4096 * 3.3) - 0.3) * 100 / 3;

  static const List<Device> devices = [
    Device([
      Measurement(
        _pressure,
        bitLength: 12,
        endian: Endian.little,
        sampleRate: 1,
        yMap: shiftY,
      )
    ]),
  ];

  @override
  String get name => 'Pressure Sensor';

  @override
  bool get navigateOnNewConnection => false;

  @override
  final AppData appData;

  const PressureSensor(this.appData, {Key? key}) : super(key: key);

  @override
  State<PressureSensor> createState() => _PressureSensorState();
}

class _PressureSensorState extends State<PressureSensor> with Plotting {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() => super.dispose();

  @override
  AppData get appData => widget.appData;

  @override
  Widget build(BuildContext context) {
    return makePlot(
      PressureSensor.devices.first.measurements.first,
      includeYLabels: true,
      yMax: 50,
      yMin: -1,
    );
  }
}
