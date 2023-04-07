import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/signals.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/apps/app_functions/device_control.dart';
import 'package:fl_new/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Top-level stage constants: change these to
final Map<List<_LEDInstruction>, String> _insts = {
  [
    _LEDInstruction(
      0,
      totalTime: const Duration(minutes: 5),
    )
  ]: "Step 1 DA 20min",
  [
    _LEDInstruction(1,
        totalTime: const Duration(seconds: 10),
        onTime: const Duration(milliseconds: 1),
        period: const Duration(seconds: 2))
  ]: "Step 2 DA 0.01",
  [
    _LEDInstruction(
      2,
      totalTime: const Duration(minutes: 50),
      onTime: const Duration(milliseconds: 4),
      period: const Duration(seconds: 10),
    )
  ]: "Step 3 DA 0.04",
  [
    _LEDInstruction(3,
        totalTime: const Duration(seconds: 100),
        onTime: const Duration(milliseconds: 5),
        period: const Duration(seconds: 20))
  ]: "Step 4 DA 0.05",
  [
    _LEDInstruction(
      4,
      totalTime: const Duration(minutes: 10),
    )
  ]: "Step 5 Light Adaptation",
  [
    _LEDInstruction(
      5,
      totalTime: const Duration(seconds: 50),
      onTime: const Duration(milliseconds: 4),
      period: const Duration(milliseconds: 500),
    ),
  ]: "Step 6 LA 10min",
  [
    _LEDInstruction(
      6,
      totalTime: const Duration(seconds: 50),
      onTime: const Duration(milliseconds: 4),
      period: const Duration(milliseconds: 33),
    ),
  ]: "Step 7 LA 30hz"
};

class LEDDriver extends StatefulWidget implements AbstractApp {
  static const _led = Signal(
    SignalType.other,
    serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
    charUuid: "228baecf-35fd-875f-39fe-b2a394d28057",
  );

  static const _erg = Signal(
    SignalType.erg,
    serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
    charUuid: "0000eef1-0000-1000-8000-00805f9b34fb",
  );

  static const List<Device> devices = [
    // ERG sensing device
    Device([
      Measurement(
        _erg,
        sampleRate: 1000,
        bitLength: 24,
        endian: Endian.big,
        conversion: 1 / 8388607.0,
        signed: true,
      ),
    ]),
    // LED device: has no measurements
    Device([
      Measurement(_led, bitLength: 8, endian: Endian.big, sampleRate: 1),
    ]),
  ];

  @override
  final AppData appData;

  @override
  String get name => "LED Driver";

  const LEDDriver(this.appData, {Key? key}) : super(key: key);

  @override
  State<LEDDriver> createState() => _LEDDriverState();

  @override
  bool get navigateOnNewConnection => false;
}

class _LEDDriverState extends State<LEDDriver>
    with DeviceControl, FileSaving, Plotting {
  final _StopwatchWidget _stopwatch = _StopwatchWidget();
  late final DeviceControllable _ledControl;
  late final DeviceControllable _endpoint;
  final Timestamp _timestampGenerator = Timestamp();
  late final StreamController<String> _timestampStream;
  late final int _numButtons;
  late final Stream<List<int>>? _stepStream;
  late final StreamSubscription<List<int>>? _stepSubscription;
  bool _showPlot = true;

  /// The current LED stage shown on the screen
  int currentStage = 0;

  @override
  AppData get appData => widget.appData;

  @override
  String get projectName => widget.name;

  @override
  bool get wantCloudSaving => false;

  @override
  bool get wantLocalSaving => true;

  @override
  initState() {
    super.initState();
    startSaving();
    _numButtons = _insts.entries.length;
    _timestampStream = StreamController<String>();
    _endpoint = DeviceControllable(
      characteristic: LEDDriver._led.charUuid,
      service: LEDDriver._led.serviceUuid,
      device: LEDDriver.devices[1],
    );

    registerCustomSaving(_timestampStream.stream, fileName: "timestamps");
    _initializeStepStream();
  }

  @override
  dispose() {
    _stepSubscription?.cancel();
    super.dispose();
  }

  /// Subscribes to the characteristic that passes the current stage as the
  /// second of a pair of bytes (the first byte being where the stage can be
  /// assigned). Rebuilds of the screen will occur when the current stage
  /// as reported by the device differs from the state of this object.
  Future<void> _initializeStepStream() async {
    _stepStream = await listen(endpoint: _endpoint);
    _stepSubscription = _stepStream?.listen(_onDeviceNotify);
  }

  /// Callback for handling device notifications, which may result from
  /// stage changes (but can also happen through our own writing to
  /// the characteristic).
  void _onDeviceNotify(List<int> bytes) {
    if (bytes.isNotEmpty) {
      int newStage = bytes.last; // from characteristic

      if (currentStage != newStage) {
        _stopwatch.reset();

        // stage 0 edge case: stopwatch should be paused
        newStage == 0 ? _stopwatch.stop() : _stopwatch.start();

        // save timestamp
        DateTime now = _timestampGenerator.now() ?? DateTime.now();
        String toSave = (now.millisecondsSinceEpoch / 1000).toString() +
            ',' +
            newStage.toString() +
            '\r\n';
        _timestampStream.add(toSave);

        // redraw the screen // used in flextech
        setState(() {
          currentStage = newStage;
        });
      }
    }
  }

  /// Callback to be passed to the ButtonArray so that it can be registered
  /// by that widgets buttons.
  Future<void> _onPress(int pressed) async {
    List<int>? bytes = await read(endpoint: _endpoint);
    if (bytes != null) {
      await write([pressed, bytes.last], endpoint: _endpoint);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Step $pressed queued',
          textScaleFactor: 1.2,
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _makeProtocolTextDisplay(List<_LEDInstruction> insts) {
    List<Widget> list = <Widget>[];
    for (_LEDInstruction inst in insts) {
      final totalTime = inst.totalTime.inSeconds;
      String prefix;
      if (inst.onTime.inSeconds == totalTime) {
        // on the whole time
        prefix = "";
      } else {
        bool onTimeMillis = inst.onTime.inSeconds <= 2;
        final int onTime =
            onTimeMillis ? inst.onTime.inMilliseconds : inst.onTime.inSeconds;
        final String onTimeUnit = onTimeMillis ? "ms" : "s";

        bool periodMillis = inst.period.inSeconds <= 2;
        final int period =
            periodMillis ? inst.period.inMilliseconds : inst.period.inSeconds;
        final String periodUnit = periodMillis ? "ms" : "s";

        prefix = "$onTime$onTimeUnit every $period$periodUnit for ";
      }
      list.add(
        Text(
          "LED ${inst.led}: $prefix${totalTime}s",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: list,
    );
  }

  Widget _makeProtocol() {
    if (currentStage <= 0 || currentStage > _numButtons) {
      // stage "0": nothing to show
      return Container();
    }

    // otherwise, we get the instruction corresponding to the current stage
    final entry = _insts.entries.elementAt(currentStage - 1);
    Widget title = Text(
      entry.value,
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
    );
    if (entry.key.isEmpty) {
      return Center(child: title);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(padding: const EdgeInsets.all(8.0), child: title),
        ),
        Expanded(child: _makeProtocolTextDisplay(entry.key)),
      ],
    );
  }

  Widget _drawPlot() {
    if (_showPlot) {
      return Expanded(
        child: makePlot(
          LEDDriver.devices[0].measurements[0],
          timeSpan: const Duration(
            seconds: 2,
          ),
        ),
      );
    }

    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: 1,
          fit: FlexFit.tight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BorderedContainer(
              label: "Step Selection",
              child: Align(
                alignment: Alignment.center,
                child: _ButtonArray(
                  _numButtons,
                  currentStage: currentStage,
                  onButtonPress: _onPress,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: BorderedContainer(
                          label: "Protocol",
                          child: _makeProtocol(),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 8),
                        child: BorderedContainer(
                          label: "Elapsed Step Duration",
                          child: _stopwatch,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    ElevatedButton(
                        onPressed: () => setState(() {
                              _showPlot = !_showPlot;
                            }),
                        child: const Text('Toggle Plot')),
                    _drawPlot(),
                  ],
                ),
              ) //show plot function
            ],
          ),
        )
      ],
    );
  }
}

/// Make a `_numButtons`-button array and calls `onButtonPress` with
/// the current stage 1-indexed; that is, if first button is pressed,
/// `onButtonPress(1)` is called.
class _ButtonArray extends StatelessWidget {
  final Function(int)? onButtonPress;
  final int currentStage;
  final int _numButtons;

  const _ButtonArray(this._numButtons,
      {required this.currentStage, this.onButtonPress, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        _numButtons,
        (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: ElevatedButton(
              onPressed: () {
                if (onButtonPress != null) {
                  final target = i + 1;
                  onButtonPress!(target);
                }
              },
              style: ButtonStyle(
                backgroundColor: currentStage == i + 1
                    ? MaterialStateProperty.all<Color>(Colors.blue)
                    : MaterialStateProperty.all<Color>(Colors.grey),
              ),
              child: Text(
                'Step ${i + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A controllable stopwatch.
class _StopwatchWidget extends StatefulWidget {
  final ValueNotifier<bool> startNotif = ValueNotifier<bool>(false);
  final ValueNotifier<int> resetNotif = ValueNotifier(0);

  _StopwatchWidget({Key? key}) : super(key: key);

  /// Starts or resumes the stopwatch. Has no effect if the stopwatch is
  /// already running.
  void start() => startNotif.value = true;

  /// Pauses the stopwatch/
  void stop() => startNotif.value = false;

  /// Toggles the stopwatch on or off.
  void toggle() => startNotif.value = !startNotif.value;

  /// Zeros out the stopwatch but does not stop its count if started.
  void reset() => resetNotif.value += 1; // dummy value to trigger rebuild

  @override
  State<_StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<_StopwatchWidget> {
  late final Stopwatch _watch;
  final _stepSubscription = StreamController<Duration>();
  late final Timer _drawTimer;

  void setWatch(bool watchOn) {
    if (watchOn) {
      _watch.start();
    } else {
      _watch.stop();
    }
  }

  void resetWatch() {
    _watch.reset();
  }

  @override
  void initState() {
    super.initState();
    _watch = Stopwatch();
    widget.startNotif.addListener(() => setWatch(widget.startNotif.value));
    widget.resetNotif.addListener(resetWatch);
    _drawTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _stepSubscription.add(_watch.elapsed);
    });
  }

  @override
  void dispose() {
    _watch.stop();
    widget.startNotif.removeListener(() => setWatch(widget.startNotif.value));
    _stepSubscription.close();
    _drawTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _stepSubscription.stream,
      initialData: const Duration(seconds: 0),
      builder: ((context, snapshot) {
        if (snapshot.hasError) {
          return const Icon(Icons.error);
        } else if (snapshot.hasData) {
          Duration currentDuration = snapshot.data!;
          return Text(
            currentDuration.toString().substring(0, 9),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 52),
          );
        }
        return const CircularProgressIndicator();
      }),
    );
  }
}

class _LEDInstruction {
  final Duration period;
  final Duration onTime;
  final Duration totalTime;
  final int led;

  int get repetitions => totalTime.inMilliseconds ~/ period.inMilliseconds;

  _LEDInstruction(this.led,
      {required this.totalTime, Duration? onTime, Duration? period})
      : onTime = onTime ?? totalTime,
        period = period ?? totalTime {
    assert(totalTime >= this.period && totalTime >= this.onTime);
    assert(this.period >= this.onTime);
  }
}
