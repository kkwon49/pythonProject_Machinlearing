import 'dart:typed_data';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/signals.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_new/apps/app_functions/app_function.dart';

class SmartMask extends StatefulWidget implements AbstractApp {
  static const List<Device> devices = [
    Device([
      Measurement(
        Signal(
          SignalType.pressure,
          serviceUuid: "228bae90-35fd-875f-39fe-b2a394d28057",
          charUuid: "228bae91-35fd-875f-39fe-b2a394d28057",
        ),
        bitLength: 32,
        sampleRate: 1,
        conversion: 1 / 134217728,
        channels: 4,
        endian: Endian.little,
      ),
      Measurement(
          Signal(
            SignalType.pressure,
            serviceUuid: "228bae90-35fd-875f-39fe-b2a394d28057",
            charUuid: "228bae92-35fd-875f-39fe-b2a394d28057",
          ),
          sampleRate: 1,
          conversion: 1 / 134217728,
          channels: 4,
          bitLength: 32,
          endian: Endian.little),
    ])
  ];

  @override
  String get name => "Smart Mask";

  @override
  final AppData appData;

  // Constructor
  const SmartMask(this.appData, {Key? key}) : super(key: key);

  @override
  State<SmartMask> createState() => _SmartMaskState();

  @override
  bool get navigateOnNewConnection => true;
}

class _SmartMaskState extends State<SmartMask> with FileSaving, Plotting {
  // Class variables
  final double _radius = 150.0;
  late final Widget _sqaure;

  @override
  AppData get appData => widget.appData;

  @override
  String get projectName => widget.name;

  @override
  bool get wantCloudSaving => false;

  @override
  bool get wantLocalSaving => true;

  @override
  void initState() {
    super.initState();
    startSaving();
    _sqaure = _makeSquare();
  }

  @override
  void dispose() {
    stopSaving();
    super.dispose();
  }

  Positioned _sqaureAtAngle(double angle) {
    double y = _radius * sin(pi / 180 * angle);
    double x = _radius * cos(pi / 180 * angle);
    return Positioned(
        child: _sqaure, right: _radius - x - 15, top: _radius - y - 15);
  }

  Widget _makeSquare() {
    return Container(
      width: 30.0,
      height: 30.0,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.rectangle,
      ),
    );
  }

  Widget _makeCenter() {
    return Container(
      alignment: Alignment.center,
      width: 2 * _radius,
      height: 2 * _radius,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        clipBehavior: Clip.none,
        children: [
          _sqaureAtAngle(60),
          _sqaureAtAngle(20),
          _sqaureAtAngle(-20),
          _sqaureAtAngle(-60),
          _sqaureAtAngle(60 + 180),
          _sqaureAtAngle(20 + 180),
          _sqaureAtAngle(-20 + 180),
          _sqaureAtAngle(-60 + 180)
        ],
      ),
    );
  }

  Widget _plotPressure(Measurement m,
      {required int channel, EdgeInsets? padding}) {
    return Padding(
        padding: padding ?? const EdgeInsets.all(0),
        child: makePlot(m, includeYLabels: true, channel: channel));
  }

  List<Widget> _plotMaskPressures(Measurement pressureSide,
      {EdgeInsets? padding}) {
    return List.generate(
      4,
      (i) => Expanded(
        child: _plotPressure(pressureSide, channel: i, padding: padding),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Measurement leftPressures = SmartMask.devices[0].measurements[0];
    Measurement rightPressures = SmartMask.devices[0].measurements[1];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _plotMaskPressures(
              leftPressures,
              padding: const EdgeInsets.only(left: 20),
            ),
          ),
        ),
        Expanded(
          child: Center(child: _makeCenter()),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _plotMaskPressures(rightPressures),
          ),
        ),
      ],
    );
  }
}
