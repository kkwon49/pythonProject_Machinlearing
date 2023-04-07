import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/measurements/measurement.dart';

@protected
abstract class AbstractNotifyingBuffer<T> extends ValueNotifier {
  AbstractNotifyingBuffer() : super(null);

  T get mostRecent;
}

/// A `NotifyingStreamBuffer`  notifies its listeners whenever a packet is
/// added to the buffer. Each instance buffers a stream.
@protected
class NotifyingStreamBuffer extends AbstractNotifyingBuffer<List<DataPoint>> {
  final Stream<List<DataPoint>> _stream;
  final ListQueue<List<DataPoint>> _buffer;

  // Maximum number of packets allowed in the buffer. Defaults to 50.
  final int bufferSize;
  late StreamSubscription<List<DataPoint>> _subscription;
  int? _previousPacketSize;
  bool _started = false;
  bool _uniformPacketSize = true;

  NotifyingStreamBuffer(Stream<List<DataPoint>> stream, {this.bufferSize = 50})
      : assert(bufferSize > 0),
        _buffer = ListQueue(bufferSize),
        _stream = stream;

  List<DataPoint> _compileBuffer() {
    return _buffer.fold([], (prev, value) => prev..addAll(value));
  }

  Stream<List<DataPoint>> get stream => _stream;

  /// A `List`-like view of the contents stored in this buffer. This can be
  /// an expensive operation depending on the size of the buffer.
  @override
  List<DataPoint> get value => _compileBuffer();

  /// The current number of DataPoints in this buffer.
  int get numSamples {
    if (_uniformPacketSize) {
      return _buffer.isEmpty ? 0 : _buffer.first.length * _buffer.length;
    }
    return _buffer.fold(0, (prev, next) => prev + next.length);
  }

  int get numPackets => _buffer.length;

  @override
  List<DataPoint> get mostRecent => _buffer.isEmpty ? [] : _buffer.last;

  /// Return a lazy iterable of the first `n` elements currently stored in
  /// this buffer.
  Iterable<List<DataPoint>> first(int n) {
    return _buffer.take(n);
  }

  /// Removes all elements from the buffer.
  void clear() => _buffer.clear();

  /// Add `newData` to the buffer while maintaining its size constraints.
  void _addData(List<DataPoint> newData) {
    if (_buffer.length > bufferSize) {
      _buffer.removeFirst();
    }
    _buffer.add(newData);

    // update buffer size optimization parameters
    _uniformPacketSize = _previousPacketSize != newData.length;
    _previousPacketSize = newData.length;
  }

  /// Allow the buffer to start collecting data from its stream. Listeners to
  /// this buffer will then receive notifications. `start()` calls not
  /// separated by `stop()` calls have no effect.
  void start() {
    if (!_started) {
      _subscription = _stream.listen((List<DataPoint> newData) {
        _addData(newData);
        notifyListeners();
      });
      _started = true;
    }
  }

  void stop() {
    if (_started) {
      _subscription.cancel();
      _started = false;
    }
  }
}

/// `FunctionBuffer`s provide a useful interface for buffering typical app functions
/// such as file saving or cloud computation. A `FunctionBuffer` wraps all the
/// channels of a `measurement`, notifiying listeners every `rollover` seconds
/// of new data, which is accessed via the `mostRecent` getter. A `FunctionBuffer`
/// store thes last `memory` seconds of channel data, which implies for
/// `memory` longer than `rollover` that data via `mostRecent` will be repeated
/// on successive calls, or for `memory` shorter than `rollover` that some
/// `measurement` data is lost between calls. `memory` defauls to exactly
/// `rollover`, which implies no repeated or lost data between notifications.
@protected
class FunctionBuffer extends AbstractNotifyingBuffer<List<List<DataPoint>>> {
  final Duration rollover;
  final Duration memory;
  final Measurement measurement;
  final AppData appData;
  final ValueNotifier<int> rolloverNotifier;
  late final int _maxCompiledSize;
  late final List<NotifyingStreamBuffer> _notifiers; // one for each buffer
  late final List<ListQueue<List<DataPoint>>> _buffers; // one for each channel

  @override
  List<List<DataPoint>> mostRecent = [<DataPoint>[]];

  @override
  List<List<DataPoint>> get value => _compileBuffers();

  FunctionBuffer(this.appData, this.measurement,
      {required this.rollover, Duration? memory})
      : assert(rollover.inSeconds > 0),
        memory = memory ?? rollover,
        rolloverNotifier = ValueNotifier(0) {
    assert(this.memory >= rollover); // buffer would repeat itself otherwise
    _notifiers = appData.notifierMap[measurement]!;
    _buffers = List.generate(_notifiers.length, (_) => ListQueue());

    bool initialReady = false;

    // make sure enough time has passed for memory to be full
    // ignored when memory == rollover
    Timer(this.memory, () => initialReady = true);
    Timer.periodic(
      rollover,
      (timer) {
        if (this.memory == rollover || initialReady) {
          mostRecent = _compileBuffers();

          for (var buffer in _buffers) {
            if (this.memory == rollover) {
              // guarantee no overlap in typical case
              buffer.clear();
            } else {
              // eliminate up to the most recent memory-minus-rollover seconds
              // assumes that all buffesr packets have the same length
              var channel = _buffers.indexOf(buffer);
              int minSize = (this.memory.inSeconds - rollover.inSeconds) *
                  measurement.sampleRate;

              while (length(channel: channel) > minSize) {
                buffer.removeFirst();
              }
            }
          }
          rolloverNotifier.value = rolloverNotifier.value + 1;
          notifyListeners();
        }
      },
    );

    // listen to app buffers
    for (var i = 0; i < _notifiers.length; i++) {
      var notifier = _notifiers[i];
      notifier.addListener(() {
        List<DataPoint> data = notifier.mostRecent;
        _buffers[i].add(data);
      });
    }
  }

  int length({required int channel}) {
    return _buffers[channel].fold(0, (prev, next) => prev + next.length);
  }

  /// Helper function that trims all buffers to be equal in length to the
  ///  shortest buffer.
  void _trimBuffers(List<List<DataPoint>> compiledBuffers) {
    var bufferLengths = compiledBuffers.map((b) => b.length);
    int minLen = bufferLengths.reduce(math.min);
    for (var buffer in compiledBuffers) {
      assert(buffer.length >= minLen);
      if (buffer.length != minLen) {
        buffer = buffer.getRange(0, minLen).toList();
      }
    }
  }

  /// Returns list views of the buffers.
  /// Assumes buffers have a common sample rate (which they should as long as
  /// a measurement has a single rate).
  List<List<DataPoint>> _compileBuffers() {
    // TODO: implement using built-in map() function
    List<List<DataPoint>> values =
        List.filled(_buffers.length, [], growable: false);

    for (var b = 0; b < _buffers.length; b++) {
      values[b] = (_buffers[b].fold(
        [],
        (prev, values) => prev..addAll(values),
      ));
    }

    _trimBuffers(values);
    return values;
  }
}

/// A `ChannelBuffer` notifies when a certain number of samples have been
/// buffered from a single measurement channel.
@protected
class ChannelBuffer extends AbstractNotifyingBuffer<List<DataPoint>> {
  final Stream<List<DataPoint>> _stream;
  final ListQueue<List<DataPoint>> _buffer;
  List<DataPoint> _mostRecent = [];
  bool _uniformPacketSize = true;
  final int numSampleOverlap;

  /// Number of samples at which point this buffer notifies its listeners.
  final int maxSamples;

  late StreamSubscription<List<DataPoint>> _subscription;
  int? _previousPacketSize;
  bool _started = false;

  ChannelBuffer(Stream<List<DataPoint>> stream,
      {required this.maxSamples, this.numSampleOverlap = 0})
      : assert(numSampleOverlap < maxSamples),
        _buffer = ListQueue(),
        _stream = stream;

  List<DataPoint> _compileBuffer() {
    return _buffer.fold([], (prev, value) => prev..addAll(value));
  }

  Stream<List<DataPoint>> get stream => _stream;

  /// A `List`-like view of the contents stored in this buffer. This can be
  /// an expensive operation depending on the size of the buffer.
  @override
  List<DataPoint> get value => _compileBuffer();

  /// The current number of DataPoints in this buffer.
  int get numSamples {
    if (_uniformPacketSize) {
      return _buffer.isEmpty ? 0 : _buffer.first.length * _buffer.length;
    }
    return _buffer.fold(0, (prev, next) => prev + next.length);
  }

  int get numPackets => _buffer.length;

  @override
  List<DataPoint> get mostRecent => _mostRecent;

  /// Return a lazy iterable of the first `n` elements currently stored in
  /// this buffer.
  Iterable<List<DataPoint>> first(int n) {
    return _buffer.take(n);
  }

  void _clearWithOverlap() {
    // TODO: implement with numSampleOverlap
    for (var i = 0; i < _buffer.length / 2; i++) {
      _buffer.removeFirst();
    }
  }

  /// Add `newData` to the buffer while maintaining its size constraints.
  void _addData(List<DataPoint> newData) {
    // update buffer size optimization parameters
    _uniformPacketSize = _previousPacketSize != newData.length;
    _previousPacketSize = newData.length;

    if (numSamples + newData.length < maxSamples) {
      // general case: add new data if it does not violate max size constraint
      _buffer.add(newData);
    } else {
      // fill only to max capacity and notify when newData puts us over max size
      final neededToFill = maxSamples - numSamples;
      final subset = newData.take(neededToFill).toList();
      _buffer.add(subset);
      _mostRecent = _compileBuffer();
      // _clearWithOverlap();
      _buffer.clear();
      notifyListeners();
    }
  }

  /// Allow the buffer to start collecting data from its stream. Listeners to
  /// this buffer will then receive notifications. `start()` calls not
  /// separated by `stop()` calls have no effect.
  void start() {
    if (!_started) {
      _subscription = _stream.listen((List<DataPoint> newData) {
        _addData(newData);
      });
      _started = true;
    }
  }

  void stop() {
    if (_started) {
      _subscription.cancel();
      _started = false;
    }
  }
}
