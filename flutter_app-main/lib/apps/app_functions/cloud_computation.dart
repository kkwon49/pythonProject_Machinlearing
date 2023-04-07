import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:fl_new/apps/app_functions/machine_learning.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:fl_new/widgets/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_new/apps/apps.dart';
import 'dart:convert';
import '../buffers/buffers.dart';
import 'app_function.dart';

const String _apiKey = 'AIzaSyBFdSRTBrAZ7RVb-gog5bjQGY4037aF1z4';
const String _serverAddress = 'https://data-storage-339220.ue.r.appspot.com';

@protected
enum ApiFunction {
  heartRate(
    apiName: 'hr',
    title: "Heart Rate",
    subtext: 'Beats per Minute',
    channelNames: ['data'],
    bounds: [40, 200],
  ),
  bloodOxygen(
      apiName: 'spo2',
      title: "Blood Oxygen",
      channelNames: ['red', 'ir'],
      bounds: [70, 100],
      mainTextEnding: '%',
      subtext: "Oxygen Saturation"),
  temperature(
    apiName: 'temp',
    title: "Skin Temperature",
    channelNames: ['data'],
    bounds: [15, 40],
    mainTextEnding: '\u{00B0}C',
  ),
  respirationRate(
    apiName: 'rr',
    subtext: "Breaths per Minute",
    channelNames: ['data'],
    title: "Respiration Rate",
    bounds: [8, 50],
  ),
  bloodPressure(
    apiName: 'bp',
    subtext: 'mmHg',
    channelNames: ['red', 'ir'],
    title: 'Blood Pressure',
    bounds: [],
  ),
  posture(
    apiName: 'posture',
    title: "Posture",
    channelNames: ['x_acc', 'y_acc', 'z_acc'],
  ),

  classification(
    apiName: 'classification',
    title: 'Classification',
    channelNames: ['data'],
  );

  final String subtext;
  final String url;
  final String title;
  final String mainTextEnding;
  final List<String> channelNames;
  final List<int> bounds;

  /// Returns `true` if this value is within the acceptable bounds of the API
  /// function.
  bool checkBounds(dynamic value) {
    double numValue;
    if (value.runtimeType == String) {
      numValue = double.parse(value as String);
    } else if (value.runtimeType == double) {
      numValue = value;
    } else {
      throw TypeError();
    }
    return bounds.isEmpty ||
        numValue <= bounds.last && numValue >= bounds.first;
  }

  const ApiFunction({
    required String apiName,
    required this.title,
    required this.channelNames,
    this.bounds = const <int>[],
    this.subtext = '',
    this.mainTextEnding = '',
  }) : url = _serverAddress + "/$apiName?key=" + _apiKey;
}

/// Provides a uniform interface with other app function mixins via the
/// conveniece function `makeCloudWidget()`.
mixin CloudComputation<T extends StatefulWidget> on State<T>
    implements AppFunction {
  @protected
  AppData get appData;

  CloudComputationDisplay makeCloudWidget(
    ApiFunction function,
    Measurement measurement, {
    double? fontSizeOverride,
    String? subtextOverride,
    Duration? outboundInterval,
    Duration? outboundMemory,
  }) {
    return CloudComputationDisplay(
      function,
      measurement,
      appData,
      fontSize: fontSizeOverride,
    );
  }
}

/// `CloudComputationDisplay` widgets present the results of a single `ApiFunction`,
/// complete with clear formatting and both signal quality and
/// out-of-bounds warnings.
class CloudComputationDisplay extends StatefulWidget {
  final Measurement measurement;
  final ApiFunction func;
  final String? subtextOverride;
  final double? fontSize;
  late final CloudStream? _cloudStream;

  CloudComputationDisplay.fromCloudStream(CloudStream cloudStream,
      {this.subtextOverride, this.fontSize, Key? key})
      : _cloudStream = cloudStream,
        measurement = cloudStream.measurement,
        func = cloudStream.function,
        super(key: key);

  CloudComputationDisplay(this.func, this.measurement, AppData appData,
      {this.subtextOverride,
      Duration outboundInterval = const Duration(seconds: 10),
      Duration outboundMemory = const Duration(seconds: 10),
      this.fontSize,
      Key? key})
      : super(key: key) {
    if (appData.notifierMap[measurement] == null) {
      _cloudStream = null;
    } else {
      _cloudStream = CloudStream(
        func,
        measurement,
        appData: appData,
        outboundInterval: outboundInterval,
        outboundMemory: outboundMemory,
      );
    }
  }

  @override
  State<CloudComputationDisplay> createState() => _CloudComputationState();
}

class _CloudComputationState extends State<CloudComputationDisplay> {
  static const Color _warningBorderColor = Color.fromARGB(255, 255, 119, 0);
  static const Color _warningTextColor = Color.fromARGB(255, 201, 100, 0);
  late final ValueNotifier<bool> animationNotifier;
  late final _AnimatedBorderedContainer animatedBorder;
  late final String borderTitle;

  @override
  void initState() {
    super.initState();
    animationNotifier = ValueNotifier(false);
    borderTitle = widget.func.title;
    final borderWidget =
        BorderedContainer(label: borderTitle, child: Container());

    animatedBorder = _AnimatedBorderedContainer(
      borderWidget,
      animationNotifier,
      onColor: _warningBorderColor,
      labelOnColor: _warningTextColor,
    );
  }

  Widget _checkHttpError(Exception e) =>
      e is HttpException ? const CloudError() : const _CheckWifiNotif();

  Widget makeBody(String data, {required bool goodQuality}) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Flexible(
            child: Visibility(
              visible: !goodQuality,
              replacement: const Text("", style: TextStyle(fontSize: 14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.warning, color: _warningBorderColor, size: 15),
                  Padding(
                    padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Text(
                      "Check fit",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            flex: 2,
          ),
          Expanded(
            child: Container(
              alignment: Alignment.topCenter,
              child: _NumericDisplay(
                data + widget.func.mainTextEnding,
                subtext: widget.subtextOverride ?? widget.func.subtext,
                fontSize: widget.fontSize,
              ),
            ),
            flex: 6,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget._cloudStream == null) {
      return BorderedContainer(
        label: borderTitle,
        child: const Icon(
          Icons.bluetooth_disabled,
        ),
      );
    }

    return StreamBuilder<String>(
      stream: widget._cloudStream!.inboundStream,
      builder: (_, snapshot) {
        Widget body = const CircularProgressIndicator();

        if (snapshot.hasError) {
          if (snapshot.error is HttpException) {
            body = _checkHttpError(snapshot.error as Exception);
          } else if (snapshot.error is HandshakeException) {
            body = Stack(alignment: Alignment.center, children: const [
              Icon(Icons.cloud),
              CircularProgressIndicator()
            ]);
          }
        } else if (snapshot.hasData) {
          String data = snapshot.data!;

          bool inBounds = widget.func.checkBounds(data);
          bool goodQuality = inBounds; // TODO: use cloud quality flag

          animationNotifier.value = !inBounds;
          body = makeBody(data, goodQuality: goodQuality);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            animatedBorder,
            body,
          ],
        );
      },
    );
  }
}

class _AnimatedBorderedContainer extends StatefulWidget {
  final BorderedContainer child;
  final Color onColor;
  final Color offColor;
  final Color labelOnColor;
  final Duration animationPeriod;
  final ValueNotifier<bool> _notifier;

  _AnimatedBorderedContainer(
    this.child,
    ValueNotifier<bool> onNotifier, {
    required this.onColor,
    this.animationPeriod = const Duration(milliseconds: 1500),
    Color? offColor,
    Color? labelOnColor,
    Key? key,
  })  : offColor = offColor ?? child.borderColor ?? Colors.grey,
        labelOnColor = labelOnColor ?? onColor,
        _notifier = onNotifier,
        super(key: key);

  @override
  State<_AnimatedBorderedContainer> createState() =>
      _AnimatedBorderedContainerState();
}

class _AnimatedBorderedContainerState
    extends State<_AnimatedBorderedContainer> {
  late Widget onWidget;
  late Widget offWidget;

  @override
  void initState() {
    super.initState();
    offWidget = widget.child;
    onWidget = BorderedContainer.merge(
      widget.child,
      borderColor: widget.onColor,
      borderWidth: min(widget.child.borderWidth * 1.75, 3),
      labelStyle: widget.child.labelStyle?.copyWith(color: widget.labelOnColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: widget._notifier,
        builder: (context, value, _) {
          if (!value) {
            return offWidget;
          }
          return StreamBuilder<bool>(
            stream: Stream<bool>.periodic(
              widget.animationPeriod,
              (count) => count % 2 == 0,
            ),
            initialData: false,
            builder: (_, snapshot) {
              if (snapshot.hasData && snapshot.data!) {
                return onWidget;
              }
              return offWidget;
            },
          );
        });
  }
}

class _NumericDisplay extends StatelessWidget {
  final String displayValue;
  final String? subtext;
  final double _fontSize;
  static const double _defaultSize = 46.0;

  const _NumericDisplay(
    this.displayValue, {
    this.subtext,
    double? fontSize,
    Key? key,
  })  : _fontSize = fontSize ?? _defaultSize,
        super(key: key);

  List<Widget> _makeDisplayBody() {
    List<Widget> body = [];
    Widget primaryText = Flexible(
      flex: 4,
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          displayValue,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: (_fontSize).toDouble(),
          ),
        ),
      ),
    );
    body.add(primaryText);

    if (subtext != null) {
      Widget secondardyText = Flexible(
        flex: 1,
        child: Center(
          child: Text(
            subtext!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ),
      );
      body.add(secondardyText);
    }

    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: _makeDisplayBody(),
    );
  }
}

class _CheckWifiNotif extends StatelessWidget {
  const _CheckWifiNotif({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.error,
          size: 75,
          color: Colors.red,
        ),
        Text(
          "Check WiFi",
          style: TextStyle(fontSize: 28),
        )
      ],
    );
  }
}

/// Given an `ApiFunction`, a `Measurement`, and an app's `AppData` instance,
/// `CloudStream`s automatically connect to the correct cloud endpoint and
/// send the `Measurement` instance's data. The results of the cloud computation
/// be read as a stream through the `inboundStream` field.
class CloudStream {
  final Measurement measurement;
  final ApiFunction function;
  final StreamController<String> _controller;
  final FunctionBuffer _buffer;
  late final bool downsampleOutbound;
  static const Duration defaultMemory = Duration(seconds: 8);
  static const Duration defaultInterval = Duration(seconds: 4);

  Stream<String> get inboundStream => _controller.stream;

  CloudStream.fromFunctionBuffer(FunctionBuffer functionBuffer, this.function,
      {bool? downsampleOutbound = false, Key? key})
      : _controller = StreamController(),
        _buffer = functionBuffer,
        measurement = functionBuffer.measurement {
    // this.downsampleOutbound = false;
    this.downsampleOutbound =
        downsampleOutbound ?? measurement.sampleRate >= 100;
    _registerBuffer();
  }

  /// Construct a `CloudStream` from an `ApiFunction` receiving data
  /// corresponding a `Measurement` via an `AppData` instance.
  CloudStream(
    this.function,
    this.measurement, {
    required AppData appData,
    Duration? outboundInterval,
    Duration? outboundMemory,
    FunctionBuffer? bufferOverride,
    this.downsampleOutbound = false,
  })  : assert(!downsampleOutbound || measurement.sampleRate / 2 > 1),
        _controller = StreamController(),
        _buffer = bufferOverride ??
            FunctionBuffer(
              appData,
              measurement,
              rollover: outboundInterval ?? CloudStream.defaultInterval,
              memory: outboundMemory ?? CloudStream.defaultMemory,
            ) {
    _registerBuffer();
  }

  /// Constructor helper function; registers the callback for the buffer updates.
  void _registerBuffer() {
    _buffer.addListener(() => _send(_buffer.mostRecent, downsampleOutbound));
  }

  bool _checkNumericResponse(Map<String, dynamic> decodedResponse) {
    double? parseResult = double.tryParse(decodedResponse.keys.first);
    return parseResult != null;
  }

  String _processResponse(http.Response response, {int precision = 0}) {
    if (response.statusCode == 200) {
      Map<String, dynamic> decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes));
      if (decodedResponse.isEmpty) {
        // return "No Response";
        throw const FormatException("Empty response");
      } else if (_checkNumericResponse(decodedResponse)) {
        // calculate mean value for now
        double sum =
            decodedResponse.values.fold(0, (prev, next) => prev + next);
        return (sum / decodedResponse.values.length).toStringAsFixed(precision);
      }
      return decodedResponse.values.last;
    } else {
      throw HttpException("ERR" + response.statusCode.toString());
    }
  }

  Map<String, dynamic> _makeJsonMap(List<DataPoint> data) {
    return {for (var element in data) element.x.toString(): element.y};
  }

  /// Sends `data` to the cloud server
  void _send(List<List<DataPoint>> data, bool downsample) async {
    // setup
    int numChannels = data.length;
    assert(numChannels == measurement.channels);
    if (downsample) {
      data = downsampleChannels(data);
    }

    // Create JSON-compatible data
    List<Map<String, dynamic>> dataMapList =
        data.map((chData) => _makeJsonMap(chData)).toList();

    // form POST request
    var url = Uri.parse(function.url);
    var body = jsonEncode({
      ...Map.fromIterables(function.channelNames, dataMapList),
      'rate': downsampleOutbound
          ? measurement.sampleRate ~/ 2
          : measurement.sampleRate,
    });

    // send POST request
    String shownText;
    try {
      http.Response response = await http.post(
        url,
        body: body,
        headers: {'content-type': 'application/json'},
      );
      shownText = _processResponse(response);
    } on Exception catch (e) {
      _controller.addError(e);
      return;
    }

    _controller.add(shownText);
  }
}
