import 'dart:async';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/apps/app_functions/device_control.dart';
import 'package:fl_new/apps/app_functions/machine_learning.dart';
import 'package:fl_new/connections/app_connection_model.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:fl_new/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:collection/collection.dart';

enum _Activation {
  low(0),
  onset(1),
  high(2);

  final int value;
  const _Activation(this.value);
}

final Map<String, _Location> _locationMap = {
  "K8": _Location.bicep,
  "E2": _Location.tricep,
  "E3": _Location.shoulder,
  "K4": _Location.chest,
  "E8": _Location.back,
  "Va": _Location.backpack,
};

enum _Location {
  bicep("Bicep"),
  tricep("Tricep"),
  shoulder("Shoulder"),
  chest("Chest"),
  back("Back"),
  backpack("Backpack");

  _Location get complement {
    switch (this) {
      case _Location.bicep:
        return _Location.tricep;
      case _Location.tricep:
        return _Location.bicep;
      case _Location.shoulder:
        return _Location.back;
      case _Location.back:
        return _Location.shoulder;
      default:
        throw UnimplementedError();
    }
  }

  final String name;

  const _Location(this.name);
}

class FlexTech extends StatefulWidget implements AbstractApp {
  static const Signal _emgActual = Signal(
    SignalType.emg,
    serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000eef1-0000-1000-8000-00805f9b34fb",
  );

  static const Signal _imu = Signal(
    SignalType.imu,
    serviceUuid: "228ba3a0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000a3a5-0000-1000-8000-00805f9b34fb",
  );

  static const _pressureRead = Signal(
    SignalType.pressure,
    serviceUuid: "228ba730-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000a731-0000-1000-8000-00805f9b34fb",
  );

  static const _pamControl = Signal(
    SignalType.other,
    serviceUuid: "228baec3-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baece-35fd-875f-39fe-b2a394d28057",
  );

  static const _readyFlag = Signal(
    SignalType.other,
    serviceUuid: "228baec4-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baecd-35fd-875f-39fe-b2a394d28057",
  );

  static const _compressorControl = Signal(
    SignalType.other,
    serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baecf-35fd-875f-39fe-b2a394d28057",
  );

  static const _motionPause = Signal(
    SignalType.other,
    serviceUuid: "228baec5-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baecc-35fd-875f-39fe-b2a394d28057",
  );

  static const _signals = [
    _pressureRead,
    _pamControl,
    _readyFlag,
    _compressorControl,
    _motionPause,
  ];

  static double shiftY(double value) => ((value / 4096 * 3.3) - 0.3) * 100 / 3;

  static const List<Device> devices = [
    Device([
      Measurement(
        _emgActual,
        bitLength: 24,
        sampleRate: 500,
        endian: Endian.big,
        signed: true,
        conversion: 1 / 8388607.0 * 2.42,
        key: ValueKey(0),
      ),
    ], id: ValueKey(0)),
    Device(
      [
        Measurement(
          _emgActual,
          bitLength: 24,
          sampleRate: 500,
          endian: Endian.big,
          signed: true,
          conversion: 1 / 8388607.0 * 2.42,
          key: ValueKey(1),
        )
      ],
      id: ValueKey(1),
    ),
    Device(
      [
        Measurement(
          _emgActual,
          bitLength: 24,
          sampleRate: 500,
          endian: Endian.big,
          signed: true,
          conversion: 1 / 8388607.0 * 2.42,
          key: ValueKey(2),
        )
      ],
      id: ValueKey(2),
    ),
    Device(
      [
        Measurement(
          _emgActual,
          bitLength: 24,
          sampleRate: 500,
          endian: Endian.big,
          signed: true,
          conversion: 1 / 8388607.0 * 2.42,
          key: ValueKey(3),
        )
      ],
      id: ValueKey(3),
    ),
    Device(
      [
        Measurement(
          _emgActual,
          bitLength: 24,
          sampleRate: 500,
          endian: Endian.big,
          signed: true,
          conversion: 1 / 8388607.0 * 2.42,
          key: ValueKey(4),
        ),
        Measurement(
          _imu,
          bitLength: 16,
          sampleRate: 100,
          endian: Endian.big,
          channels: 6,
          signed: true,
        ),
      ],
      id: ValueKey(4),
    ),
    Device(
      [
        Measurement(
          _pressureRead,
          bitLength: 12,
          endian: Endian.little,
          sampleRate: 1,
          yMap: shiftY,
        )
      ],
    )
  ];

  @override
  final AppData appData;

  @override
  String get name => "FlexTech Exoskeleton";

  @override
  bool get navigateOnNewConnection => true;

  const FlexTech(this.appData, {Key? key}) : super(key: key);

  @override
  State<FlexTech> createState() => _FlexTechEMGState();
}

class _FlexTechEMGState extends State<FlexTech>
    with DeviceControl, Plotting, FileSaving {
  late final StreamSubscription<List<int>>? _motionDoneSubscription;
  // late final int _numSliders = 3;

  // locations to their index in the exoskeleton pam array
  final Map<_Location, int> _pamLocations = {
    _Location.tricep: 2,
    _Location.bicep: 1,
    _Location.shoulder: 0,
  };

  final Set<_Location> _recentLocationHistory = {};

  Map<_Location, _Activation> activatedLocation = {};
  Map<_Location, _Activation> activatedCounterLocation = {};
  int currentActivationCount = 0;

  late final DeviceControllable _pamControlEndpoint;
  late final DeviceControllable _motionDoneEndpoint;
  late final DeviceControllable _compressorControlEndpoint;
  late final DeviceControllable _motionPauseEndpoint;
  final Map<Device, Classification<int>> _classifications = {};
  // late final Map<_Location, int> _currentStates;
  // late final Timer _pamWriteControl;
  // final Duration _pamWriteDuration = const Duration(milliseconds: 500);

  final int _minSliderValue = 36;
  final int _maxSliderValue = 255;
  // late final int _numPams;

  bool _motionDone = true;
  bool _venting = false;
  bool _paused = false;
  final Duration _ventDuration = const Duration(seconds: 5);

  late final Map<_Location, int> _sliderValues;

  /// The current Flextech stage shown on the screen
  int currentStage = 0;
  // _MotionClass? currentMotion;

  @override
  AppData get appData => widget.appData;

  @override
  String get projectName => "FlexTech";

  @override
  initState() {
    super.initState();
    _pamControlEndpoint = DeviceControllable.fromSignal(
      FlexTech._signals[1],
      device: FlexTech.devices.last,
    );

    _motionDoneEndpoint = DeviceControllable.fromSignal(
      FlexTech._signals[2],
      device: FlexTech.devices.last,
    );
    _initializeMotionDoneStream();

    _compressorControlEndpoint = DeviceControllable.fromSignal(
      FlexTech._signals[3],
      device: FlexTech.devices.last,
    );

    _motionPauseEndpoint = DeviceControllable.fromSignal(
      FlexTech._signals[4],
      device: FlexTech.devices.last,
    );

    _sliderValues = {for (var loc in _pamLocations.keys) loc: _minSliderValue};
  }

  bool _isComplementaryToCurrent(_Location newLocation) {
    _Location currentActivationLocation;
    try {
      currentActivationLocation = activatedLocation.keys.first;
    } on StateError {
      return false;
    }

    return newLocation.complement == currentActivationLocation;
  }

  /// Flutter calls this for us on every `connectionGroup` change,
  /// allowing us access in this method to the currently connected devices.
  ///
  @override
  void didChangeDependencies() {
    final connectionGroup = Provider.of<ConnectionGroup>(context);

    // get current devices
    final devices = connectionGroup.connectionMap.keys.toList();
    final currentDevices =
        devices.where((d) => d.measurements[0].signal.type == SignalType.emg);

    // remove unused devices
    final unusedDevices = _classifications.keys
        .where((device) => !currentDevices.contains(device));
    // for (var emgDevice in unusedDevices) {
    // _classifications[emgDevice]?.stop(); // needed to prevent memory leaks?
    // _classifications.remove(emgDevice);
    // }
    _classifications.removeWhere((key, _) => unusedDevices.contains(key));

    // add new devices
    for (var emgDevice in currentDevices) {
      // halt previous classification and make new
      _classifications[emgDevice]?.stop();

      // get device location from its name
      final deviceName = connectionGroup.connectionMap[emgDevice]?.device.name;
      final loc = _locationMap[deviceName?.substring(deviceName.length - 2)];

      final pumpConnected = devices.contains(FlexTech.devices.last);

      // make new classification instance based on device and its location
      final newClassification = Classification<int>(
        emgDevice.measurements[0],
        channel: 0,
        appData,
        shape: Shape(channels: 1, samples: 502),
        bodyParams: {
          'project': 'FlexTech',
          'location': loc?.name.toLowerCase()
        },
      );
      _classifications[emgDevice] = newClassification;

      // turn on classification stream and track incoming states
      newClassification.start();
      newClassification.stream.listen((result) {
        if (pumpConnected) {
          final newActivation =
              _Activation.values.firstWhere((a) => a.value == result);

          print("${loc?.name} class ${newActivation.value}");

          _handleStateChange(newActivation, loc!);
        }
      });
    }

    super.didChangeDependencies();
  }

  @override
  dispose() {
    for (var classification in _classifications.values) {
      classification.stop();
    }
    _motionDoneSubscription?.cancel();
    super.dispose();
  }

  void _handleStateChange(_Activation activation, _Location location) {
    final isComplementary = _isComplementaryToCurrent(location);

    if (activatedLocation.isEmpty) {
      // universal ready: no current PAM pair
      _setOnset(location, activation);
    } else if (location == activatedLocation.keys.first) {
      // in onset: same location, new activation
      _handleCurrent(activation);
    } else if (isComplementary && activatedCounterLocation.isEmpty) {
      _setCounterOnset(location, activation);
    } else if (isComplementary) {
      _handleCounter(location, activation);
    }
    // else, fall through method since this is a classificatoin extraneous to
    // our current PAM group (e.g. shoulder activation during bicep/tricep motion)
  }

  void _setOnset(_Location newLocation, _Activation newActivation) {
    if (newActivation == _Activation.onset) {
      activatedLocation.clear();
      activatedCounterLocation.clear();
      print("${newLocation.name} set as primary");
      activatedLocation[newLocation] = newActivation;

      setState(() {
        activatedLocation[newLocation] = newActivation;
      });

      _handleCurrent(newActivation); // TODO: remove
    }
  }

  void _setCounterOnset(_Location counterLocation, _Activation newActivation) {
    if (_isComplementaryToCurrent(counterLocation) &&
        newActivation == _Activation.onset) {
      activatedCounterLocation[counterLocation] = newActivation;
      print("${counterLocation.name} set as complementary");

      _handleCounter(counterLocation, newActivation); // TODO: remove
    }
  }

  /// `activatedLocation` must have nonzero length
  void _handleCurrent(_Activation newActivation) {
    final currentActivation = activatedLocation.values.first;
    final currentLocation = activatedLocation.keys.first;

    if (currentActivation == _Activation.low) return;

    // if (currentActivation == _Activation.onset) {
    // with onset -> high transition, we drive the exoskeleton
    // if ((newActivation == _Activation.high ||
    _Location complement = currentLocation.complement;

    if (newActivation == _Activation.onset && _motionDone) {
      activatedLocation[currentLocation] = newActivation;
      if (_recentLocationHistory.contains(complement)) {
        // if complement has been inflated, we can't inflate
        _recentLocationHistory.remove(complement);
        _vent();
        _enterReadyState();
      } else if (currentLocation != _Location.back &&
          !_recentLocationHistory.contains(currentLocation)) {
        // drive in any cases not back
        print("${currentLocation.name} pump");
        _driveExoskeleton(useCurrentLocation: true);
        _recentLocationHistory.add(currentLocation);
      } else {
        // cannot have back as primary
        _enterReadyState();
      }
    }
  }

  void _enterReadyState() {
    print("Entered ready state");
    activatedLocation.clear();
    activatedCounterLocation.clear();
    // _setPaused(false);
  }

  /// Callback for counter-muscle activation
  void _handleCounter(
    _Location counterLocation,
    _Activation newCounterActivation,
  ) async {
    assert(_isComplementaryToCurrent(counterLocation));

    final currentCounterActivation = activatedCounterLocation.values.first;

    if (currentCounterActivation == _Activation.low) return;

    _Location complement = counterLocation.complement;
    if (newCounterActivation == _Activation.onset && _motionDone) {
      print("${counterLocation.name} vent");

      activatedCounterLocation[counterLocation] = newCounterActivation;

      _recentLocationHistory.remove(complement);
      await _vent();
      _enterReadyState();
    }
  }

  Future<bool> _readReadyFlag() async {
    List<int>? bytes = await read(endpoint: _motionDoneEndpoint);

    return _motionDone = bytes?[0] == 1;
  }

  Future<void> _initializeMotionDoneStream() async {
    final stream = await listen(endpoint: _motionDoneEndpoint);
    _motionDoneSubscription = stream?.listen(_onReadyFlag);
  }

  void _onReadyFlag(List<int> bytes) async {
    if (bytes.isNotEmpty) {
      bool isReady = bytes.first == 1;

      // Don't want to trigger rebilid for the same value.
      // This logic allows us to catch our own writes if we set _motionDone
      // appropriately beforehand.
      if (_motionDone != isReady) {
        print("Motion done from exo: $isReady");
        setState(() {
          _motionDone = isReady;
        });
      }
    }
  }

  /// Vent
  Future<void> _vent() async {
    // turn off compressor
    await write([0], endpoint: _compressorControlEndpoint);

    setState(() {
      _venting = true;
    });

    // to delete?
    await write([0, 0, 0, 0, 0], endpoint: _pamControlEndpoint);
    await write([1], endpoint: _compressorControlEndpoint);
    await write([0], endpoint: _compressorControlEndpoint);

    await Future.delayed(
      _ventDuration,
      () => setState(() {
        _venting = false;
      }),
    );

    // clear active group
    _enterReadyState();
    await Future.delayed(const Duration(milliseconds: 50));

    await write([1], endpoint: _motionDoneEndpoint);
    _motionDone = true; // for clearing of stuck motionDone via manual vent
  }

  /// Procedure for actuating the exoskeleton. If no arguments are passed,
  /// uses all slider values for actuation reference pressure. If
  /// `useCurrentLocation` is `true`, instead drives exoskeleton to actuate
  /// the `_Location` in `activeLocation`. `activeLocation` must have
  /// nonzero length to use the `useCurrentLocation` argument.
  Future<void> _driveExoskeleton({bool useCurrentLocation = false}) async {
    // initialize pam array to zeros of length 5 (number exo is expecting)
    List<int> valuesToWrite = List.generate(5, (_) => 0);

    if (useCurrentLocation) {
      // use the provided values if any are nonzero
      final currentLocation = activatedLocation.keys.first;
      final indexToWrite = _pamLocations[currentLocation]!;
      valuesToWrite[indexToWrite] = 230; // 50 psi
    } else {
      // use sliders directly, writing
      for (MapEntry<_Location, int> slider in _sliderValues.entries) {
        final location = slider.key;
        final value = slider.value > _minSliderValue ? 0 : _minSliderValue;
        valuesToWrite[_pamLocations[location]!] = value;
      }
    }

    // await _setPaused(false);

    // write values
    await write(valuesToWrite, endpoint: _pamControlEndpoint);
    // print("PAMs: " + (await read(endpoint: _pamControlEndpoint)).toString());

    // clear done flag
    await write([0], endpoint: _motionDoneEndpoint);
    print("Done flag: " +
        (await read(endpoint: _compressorControlEndpoint)).toString());

    // turn on compressor
    await write([1], endpoint: _compressorControlEndpoint);
    // print("Compressor: " +
    // (await read(endpoint: _compressorControlEndpoint)).toString());

    // set state for motion done
    bool motionDoneFlag = await _readReadyFlag();
    print("Motion done from write: $motionDoneFlag");
    setState(() {
      _motionDone = motionDoneFlag;
    });

    await Future.delayed(const Duration(milliseconds: 50));
  }

  Future<bool> _setPaused(bool pause) async {
    bool status = await write([pause ? 1 : 0], endpoint: _motionPauseEndpoint);
    setState(() {
      _paused = pause;
    });
    return status;
  }

  double _calculateFullScalePercent(num value) => FlexTech.shiftY(value * 10);

  Widget _makePauseButton() {
    Widget button;
    if (_motionDone || _venting) {
      button = ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(shape: const CircleBorder()),
        child: Text(
          "Pause",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
      );
    } else if (!_paused) {
      button = ElevatedButton(
        onPressed: () async {
          await _setPaused(true);
        },
        child: Text(
          "Pause",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: const CircleBorder(),
        ),
      );
    } else {
      // paused and motion not done
      button = ElevatedButton(
        onPressed: () async {
          await _setPaused(false);
        },
        child: Text(
          "Continue",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
      );
    }

    return button;
  }

  Widget _makeSliderBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BorderedContainer(
        label: "PAM Pressure Tuning",
        child: Align(
          alignment: Alignment.center,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...List.generate(
                _pamLocations.length,
                (i) => Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _calculateFullScalePercent(
                                        _sliderValues.values.toList()[i])
                                    .toInt()
                                    .toString() +
                                " psi",
                            textScaleFactor: 1.3,
                          ),
                        ),
                        Slider(
                          value: _sliderValues.values.toList()[i].toDouble(),
                          min: _minSliderValue.toDouble(),
                          max: _maxSliderValue.toDouble(),
                          onChanged: (value) => setState(() {
                            _sliderValues.values.toList()[i] = value.toInt();
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _makeCurrentStageIndication() {
    String textToShow;
    if (activatedLocation.isEmpty) {
      textToShow = "No primary";
    } else {
      textToShow = activatedLocation.keys.first.name + " primary";
    }
    // if (_venting) {
    //   textToShow = "Venting";
    // } else if (!_motionDone && !_paused) {
    //   textToShow = "Pumping";
    // } else if (_paused) {
    //   textToShow = "Paused";
    // } else {
    //   textToShow = "Ready";
    // }

    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        bottom: 8,
      ),
      child: BorderedContainer(
        label: "Current Stage",
        child: Center(
            child: Text(
          textToShow,
          style: const TextStyle(
            fontSize: 48,
          ),
        )),
      ),
    );
  }

  Widget _makePressurePlot() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8,
              bottom: 8,
            ),
            child: BorderedContainer(
              label: "Compressor Pressure Monitor",
              child: makePlot(
                FlexTech.devices.last.measurements.first,
                title: "Pressure (psi)",
                includeYLabels: true,
                yInterval: 5,
                yMax: 60,
                yMin: -0.5,
                timeSpan: const Duration(seconds: 20),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _makeSendVentButtons() {
    bool sendReady = _motionDone && !_venting;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 4),
              child: ElevatedButton(
                style: sendReady
                    ? ElevatedButton.styleFrom(backgroundColor: Colors.blue)
                    : ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: sendReady ? _driveExoskeleton : null,
                child: const Text("Send"),
              ),
            ),
          ),
        ),
        Flexible(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: ElevatedButton(
                onPressed: sendReady || _paused
                    ? () async {
                        await _setPaused(false);
                        await _vent();
                      }
                    : null,
                child: const Text("Vent"),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionGroup>(
      builder: ((context, group, child) {
        // return FutureBuilder(future: _promptSelectLocation, builder: builder)
        return Column(children: [
          Flexible(
            flex: 2,
            fit: FlexFit.tight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(flex: 7, child: _makeSliderBar()),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 12, top: 20, bottom: 20),
                    child: SizedBox(
                        width: 150, height: 150, child: _makePauseButton()),
                  ),
                ),
                Expanded(flex: 1, child: _makeSendVentButtons())
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: BorderedContainer(
                label: "Connected Devices",
                child: _ConnectedDeviceBar(group),
              ),
            ),
          ),
          Flexible(
            flex: 5,
            child: Row(children: [
              Expanded(flex: 4, child: _makePressurePlot()),
              Expanded(flex: 4, child: _makeCurrentStageIndication()),
            ]),
          ),
        ]);
      }),
    );
  }
}

class _ConnectedDeviceBar extends StatelessWidget {
  final ConnectionGroup connectionGroup;
  final Set<_Location> _connectedLocations = {};

  _ConnectedDeviceBar(this.connectionGroup, {super.key}) {
    final connectedDevices =
        connectionGroup.connections.map((connection) => connection.device);

    for (BluetoothDevice device in connectedDevices) {
      _Location? target = _locationMap[_locationMap.keys.firstWhereOrNull(
        (locationCode) => device.name.contains(locationCode),
      )];

      if (target != null) {
        _connectedLocations.add(target);
      }
    }
  }

  Widget _makeDeviceWidget(_Location location) {
    Icon iconToShow = _connectedLocations.contains(location)
        ? const Icon(
            Icons.check,
            color: Colors.green,
            size: 30,
          )
        : const Icon(
            Icons.question_mark_sharp,
            color: Colors.red,
            size: 30,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [iconToShow, Text(location.name)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        _Location.values.length,
        (i) => _makeDeviceWidget(_Location.values[i]),
      ),
    );
  }
}
