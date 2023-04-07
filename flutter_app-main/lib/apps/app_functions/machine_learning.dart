import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/buffers/buffers.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:http/http.dart' as http;

class Shape {
  final int samples;
  final int channels;

  Shape({required this.channels, required this.samples});
}

const String _apiKey = 'AIzaSyBFdSRTBrAZ7RVb-gog5bjQGY4037aF1z4';
const String _serverAddress = 'https://data-storage-339220.ue.r.appspot.com';

class Classification<T> {
  final AppData appData;
  final Shape shape;
  final Measurement measurement;
  final int channel;
  ChannelBuffer? _buffer;
  final StreamController<T> _controller;
  bool _started = false;
  Stream<T> get stream => _controller.stream;
  final Map<String, dynamic> bodyParams;

  Classification(
    this.measurement,
    this.appData, {
    required this.shape,
    required this.channel,
    this.bodyParams = const {},
  })  : assert(channel < measurement.channels, "No such channel"),
        _controller = StreamController<T>() {
    List<NotifyingStreamBuffer>? notifiers = appData.notifierMap[measurement];
    if ((notifiers ?? []).isNotEmpty) {
      _buffer = _buffer ??
          ChannelBuffer(
            notifiers![channel].stream,
            maxSamples: shape.samples,
          );
    }
  }

  void _sendToCloud(List<DataPoint>? data) {
    // print("$hashCode sent");
    if ((data ?? []).isNotEmpty) {
      assert(data!.length == shape.samples);
      _sendChannel(data!);
    }
  }

  _sendChannel(List<DataPoint> data) async {
    // Create JSON-compatible data
    Map<String, dynamic> dataMap = _makeJsonMap(data);

    // form POST request
    var url = Uri.parse(_serverAddress + "/classification?key=" + _apiKey);
    var body = jsonEncode({
      'data': dataMap,
      'rate': 500,
      // 'project': 'FlexTech',
      // 'location': 'forearm',

      ...bodyParams
    });

    // send POST request
    dynamic classification;
    try {
      http.Response response = await http.post(
        url,
        body: body,
        headers: {'content-type': 'application/json'},
      );
      classification = _processResponse(response);
    } on Exception catch (e) {
      _controller.addError(e);
      return;
    }

    if (!_controller.isClosed && !_controller.isPaused) {
      _controller.add((classification.toList().first as T));
    }
  }

  Map<String, dynamic> _makeJsonMap(List<DataPoint> data) {
    return {for (var element in data) element.x.toString(): element.y};
  }

  dynamic _processResponse(http.Response response, {int precision = 0}) {
    if (response.statusCode == 200) {
      Map<String, dynamic> decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes));
      if (decodedResponse.isNotEmpty) {
        return decodedResponse.values;
      }
      throw const FormatException("Empty response");
    } else {
      throw HttpException("ERR" + response.statusCode.toString());
    }
  }

  void start() {
    if (!_started) {
      _buffer?.start();
      _buffer!.addListener(() => _sendToCloud(_buffer?.mostRecent));
      _started = true;
    }
  }

  void stop() {
    if (_started) {
      _buffer?.stop();
      _buffer?.removeListener(() => _sendToCloud(_buffer?.mostRecent));
      _controller.close();
      _started = false;
    }
  }
}
