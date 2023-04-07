import 'dart:typed_data';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/apps/app_functions/device_control.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:fl_new/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/apps.dart';

class EarPPG extends StatefulWidget implements AbstractApp {
  static const Signal _ppg = Signal(
    SignalType.ppg,
    serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baec1-35fd-875f-39fe-b2a394d28057",
  );

  static const Signal _misc = Signal(
    SignalType.other,
    serviceUuid: "228b0fe0-35fd-875f-39fe-b2a394d28057",
    charUuid: "00000fe2-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _ppgControl = Signal(
    SignalType.other,
    serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baecf-35fd-875f-39fe-b2a394d28057",
  );

  static const List<Device> devices = [
    Device([
      Measurement(_ppg,
          sampleRate: 50,
          bitLength: 18,
          endian: Endian.big,
          conversion: 1 / 262144.0 * 16384.0,
          channels: 2)
    ])
  ];

  static const List<Signal> signals = [_ppg, _misc];
  @override
  final AppData appData;

  @override
  String get name => "Ear PPG";

  @override
  bool get navigateOnNewConnection => false;

  const EarPPG(this.appData, {Key? key}) : super(key: key);

  @override
  State<EarPPG> createState() => _PostpartumMonitorState();
}

class _PostpartumMonitorState extends State<EarPPG>
    with FileSaving, Plotting, CloudComputation, DeviceControl {
  int? _redBrightness;
  int? _irBrightness;
  final Uuid _serv = EarPPG._ppgControl.serviceUuid;
  final Uuid _char = EarPPG._ppgControl.charUuid;
  late final DeviceControllable _endpoint;

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
    _endpoint = DeviceControllable(service: _serv, characteristic: _char);
    startSaving();
    _initializeBrightness();
  }

  Future<void> _initializeBrightness() async {
    List<int>? bytes = await read(endpoint: _endpoint);
    if (bytes != null && bytes.isNotEmpty) {
      setState(() {
        _redBrightness = bytes[0];
        _irBrightness = bytes[1];
      });
    }
  }

  Future<void> _adjustBrightness(double value, _PpgColor color) async {
    List<int>? currentBrightnesses = await read(endpoint: _endpoint);
    if (currentBrightnesses != null) {
      List<int> newBrightnesses = currentBrightnesses;
      if (color == _PpgColor.red) {
        // override red
        newBrightnesses[0] = value.round();
      } else {
        // override IR
        newBrightnesses[1] = value.round();
      }
      await write(newBrightnesses, endpoint: _endpoint);
    }
  }

  Widget _makeSlider(_PpgColor color) {
    final brightness = color == _PpgColor.red ? _redBrightness : _irBrightness;
    if (brightness == null) {
      return Slider(value: 0, onChanged: (value) {});
    }

    return _BrightnessSlider(
      onValueSelection: ((value) => _adjustBrightness(value, color)),
      initialValue: brightness.toDouble(),
      thumbColor: color.displayColor,
      activeColor: color.displayColor,
      inactiveColor: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          flex: 2,
          child: BorderedContainer(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            label: "LED Power Control",
            child: Row(
              children: [
                Expanded(
                  child: _makeSlider(_PpgColor.red),
                ),
                Expanded(
                  child: _makeSlider(_PpgColor.ir),
                )
              ],
            ),
          ),
        ),
        Flexible(
          flex: 4,
          child: makePlot(
            EarPPG.devices.first.measurements[0],
            channel: 0,
            title: "Red",
          ),
        ),
        Flexible(
          flex: 4,
          child: makePlot(
            EarPPG.devices.first.measurements[0],
            channel: 1,
            title: "IR",
          ),
        ),
      ],
    );
  }
}

enum _PpgColor {
  red(Colors.red),
  ir(Colors.black);

  final Color displayColor;
  const _PpgColor(this.displayColor);
}

class _BrightnessSlider extends StatefulWidget {
  final void Function(double value) onValueSelection;
  final double _max = 255;
  final double _min = 0;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double? initialValue;
  final int? divisions;
  const _BrightnessSlider({
    required this.onValueSelection,
    this.initialValue,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.divisions,
    Key? key,
  }) : super(key: key);

  @override
  State<_BrightnessSlider> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<_BrightnessSlider> {
  double _currentBrightness = 0;

  @override
  void initState() {
    _currentBrightness = widget.initialValue ?? widget._min;
    super.initState();
  }

  double _calcaultePercent() {
    return _currentBrightness / widget._max * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(children: [
        Flexible(
            child: Text(
          _calcaultePercent().round().toString() + "%",
          textScaleFactor: 1.3,
        )),
        Expanded(
          flex: 8,
          child: Slider(
              thumbColor: widget.thumbColor,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
              value: _currentBrightness.toDouble(),
              max: widget._max,
              min: widget._min,
              divisions: widget.divisions ?? widget._max.round(),
              onChanged: (double value) {
                setState(() {
                  _currentBrightness = value;
                });
              },
              onChangeEnd: (double value) {
                widget.onValueSelection(value);
              }),
        ),
      ]),
    );
  }
}
