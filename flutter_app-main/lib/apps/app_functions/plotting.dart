import 'dart:math';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/apps/buffers/buffers.dart';
import 'package:fl_new/connections/app_connection_model.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

@protected
enum FilterMode { lowpass, highpass, bandpass }

@protected
class DigitalFilter {
  final FilterMode mode;
  final double cutoff;

  DigitalFilter(this.mode, this.cutoff);

  double _calcAlpha(double samplingTime) =>
      exp(-2 * pi * cutoff * samplingTime);

  List<DataPoint> filter(List<DataPoint> data, int sampleRate) {
    List<DataPoint> output = List.filled(data.length, DataPoint(0, 0));
    double alpha = _calcAlpha(1 / sampleRate);

    if (mode == FilterMode.lowpass) {
      for (var i = 1; i < data.length; i++) {
        double y = data[i].y;
        double yPrev = data[i - 1].y;
        double newY = (1 - alpha) * y + alpha * yPrev;
        output[i] = DataPoint(data[i].x, newY);
      }
    } else if (mode == FilterMode.highpass) {
      for (var i = 1; i < data.length; i++) {
        double y = data[i].y;
        double yPrev = data[i - 1].y;
        double newY = (1 + alpha) / 2 * (y - yPrev) + alpha * yPrev;
        output[i] = DataPoint(data[i].x, newY);
      }
    } else if (mode == FilterMode.bandpass) {
      throw UnimplementedError("Need to implement bandpass.");
    } else {
      throw UnimplementedError("See supported filter modes.");
    }

    return output;
  }
}

mixin Plotting<T extends StatefulWidget> on State<T> implements AppFunction {
  final Map<NotifyingStreamBuffer, ChartSeriesController> _controllerMap = {};
  final Map<NotifyingStreamBuffer, List<DataPoint>> _dataMap = {};
  final Map<NotifyingStreamBuffer, int> _bufferCaps = {};
  final DigitalFilter _lowPass = DigitalFilter(FilterMode.lowpass, 20);
  final DigitalFilter _highPass = DigitalFilter(FilterMode.highpass, 0.5);

  @protected
  bool get filterData => false;

  @protected
  set filterData(bool filter) => filterData = filter;

  @override
  @protected
  AppData get appData;

  Widget makePlot(
    Measurement measurement, {
    int channel = 0,
    bool includeYLabels = false,
    Duration timeSpan = const Duration(seconds: 10),
    int decimals = 1,
    double? yMin,
    double? yMax,
    double? yInterval,
    String? title,
    TextStyle? titleStyle,
    bool? downsample,
  }) {
    AbstractNotifyingBuffer? buff = appData.notifierMap[measurement]?[channel];

    if (buff == null) {
      return Stack(
        children: [
          Plot(
            measurement,
            buffer: null,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(Icons.bluetooth_disabled_outlined, size: 50),
                Text(
                  "Device not connected.",
                  style: TextStyle(fontSize: 16),
                )
              ],
            ),
          ),
        ],
      );
    }

    Duration start = appData.getStartSinceEpoch(buff as NotifyingStreamBuffer)!;

    return Plot(
      measurement,
      buffer: buff,
      showYLabels: includeYLabels,
      epochOffset: start,
      timeSpan: timeSpan,
      decimals: decimals,
      yMin: yMin,
      yMax: yMax,
      yInterval: yInterval,
      title: title,
      titleStyle: titleStyle,
      downsample: downsample,
    );
  }
}

class Plot extends StatefulWidget {
  final Measurement measurement;
  final int channel;
  // final DigitalFilter? filter;
  final AbstractNotifyingBuffer? buffer;
  final bool showYLabels;
  final bool showXLabels;
  final Duration timeSpan;
  final Duration? epochOffset;
  final int decimals;
  final double? yMin;
  final double? yMax;
  final double? yInterval;
  final ChartTitle? _titleWidget;
  late final bool downsample;

  Plot(
    this.measurement, {
    required this.buffer,
    this.channel = 0,
    this.epochOffset,
    // DigitalFilter? filter,
    this.showYLabels = false,
    this.showXLabels = true,
    this.timeSpan = const Duration(seconds: 10),
    this.decimals = 1,
    this.yMin,
    this.yMax,
    this.yInterval,
    bool? downsample,
    String? title,
    TextStyle? titleStyle,
    Key? key,
  })  : _titleWidget = title == null
            ? null
            : ChartTitle(text: title, textStyle: titleStyle),
        super(key: key) {
    this.downsample = downsample ?? measurement.sampleRate > 50;
  }

  @override
  State<Plot> createState() => _PlotState();
}

class _PlotState extends State<Plot> {
  late final int bufferCap;
  late final int sampleRate;
  ChartSeriesController? plotController;
  late double xMin;
  late double xMax;
  late double timeIncrement;
  int? startTimeMillis; // to handle offsets from isotime
  List<DataPoint> plottingData = [];

  void bufferCallback() {
    if (plotController != null && startTimeMillis != null) {
      _updatePlot(
        widget.downsample,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final fs = widget.measurement.sampleRate;
    sampleRate = widget.downsample ? fs ~/ 2 : fs;
    bufferCap = widget.timeSpan.inMilliseconds ~/ 1000 * sampleRate;

    timeIncrement = widget.timeSpan.inMilliseconds / 1000;
    startTimeMillis = widget.epochOffset?.inMilliseconds;

    // register plot to show new data when the buffer notifies
    widget.buffer?.addListener(bufferCallback);
  }

  @override
  void dispose() {
    widget.buffer?.removeListener(bufferCallback);
    super.dispose();
  }

  void _updatePlot(bool downsample) {
    List<DataPoint>? newData = widget.buffer?.mostRecent.toList();
    if (newData == null || newData.isEmpty) {
      return;
    }

    if (downsample) {
      newData = downsampleChannel(newData).toList();
    }

    // map from seconds since epoch to an offset time (also seconds)
    Iterable<DataPoint> dataToPlot = newData.map(
      (dp) => DataPoint(dp.x - startTimeMillis! / 1000, dp.y),
    );

    // Iterable<DataPoint> dataToPlot = newData;

    final existingLength = plottingData.length;
    final additionalLength = newData.length;

    List<int> removedIdxs;
    List<int> addedIdxs;
    plottingData.addAll(dataToPlot);

    if (plottingData.length <= bufferCap) {
      // early case when trace is filling the remaining plot space
      removedIdxs = [];
      addedIdxs = List.generate(
        additionalLength,
        (i) => existingLength + i,
        growable: false,
      );
    } else {
      // general case: add at end, remove at beginning
      removedIdxs = List.generate(
        plottingData.length - bufferCap,
        (i) => i,
        growable: false,
      );
      addedIdxs = List.generate(
        additionalLength,
        (i) => existingLength - removedIdxs.length + i,
        growable: false,
      );

      plottingData.removeRange(0, removedIdxs.length);
    }

    // plot
    try {
      plotController?.updateDataSource(
        addedDataIndexes: addedIdxs,
        removedDataIndexes: removedIdxs,
      );
    } on Exception catch (e) {
      print("Could not plot: $e");
    }
  }

  NumericAxis _makeAxis({
    String label = "",
    int decPlaces = 1,
    bool visible = true,
    double? min,
    double? max,
    double? interval,
  }) {
    return NumericAxis(
      title: AxisTitle(text: label),
      isVisible: visible,
      visibleMinimum: min,
      visibleMaximum: max,
      desiredIntervals: 2,
      interval: interval,
      edgeLabelPlacement: EdgeLabelPlacement.shift,
      maximumLabels: 3,
      majorGridLines: const MajorGridLines(width: 0),
      minorGridLines: const MinorGridLines(width: 0),
      decimalPlaces: decPlaces,
    );
  }

  @override
  Widget build(BuildContext context) {
    startTimeMillis ??=
        Provider.of<ConnectionGroup>(context).start.millisecondsSinceEpoch;
    return SfCartesianChart(
      title: widget._titleWidget,
      plotAreaBorderWidth: 0,
      primaryXAxis: _makeAxis(
        visible: widget.showXLabels,
        interval: 1,
      ),
      primaryYAxis: _makeAxis(
        visible: widget.showYLabels,
        decPlaces: widget.decimals,
        interval: widget.yInterval,
        min: widget.yMin,
        max: widget.yMax,
      ),
      // enableAxisAnimation: false,
      series: <ChartSeries>[
        LineSeries<DataPoint, double>(
            width: 3,
            onRendererCreated: (ChartSeriesController controller) {
              plotController = controller;
            },
            dataSource: plottingData,
            xValueMapper: (DataPoint point, _) => point.x,
            yValueMapper: (DataPoint point, _) => point.y),
      ],
    );
  }
}
