// import 'dart:typed_data';
// import 'package:fl_new/apps/abstract_app.dart';
// import 'package:fl_new/apps/app_data.dart';
// import 'package:fl_new/apps/app_functions/file_saving.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_new/measurements/measurement.dart';
// import 'package:fl_new/connections/connection.dart';

// const String _serviceUuid = "228beef0-35fd-875f-39fe-b2a394d28057";

// const List<String> _charUuids = [
//   "0000eef1-0000-1000-8000-00805f9b34fb",
//   "0000eef2-0000-1000-8000-00805f9b34fb",
//   "0000eef3-0000-1000-8000-00805f9b34fb",
//   "0000eef4-0000-1000-8000-00805f9b34fb"
// ];

// // map each service and its characteristics to a list of Signals
// final List<Signal> _signals = _charUuids
//     .map(
//       (e) => Signal(SignalType.emg, serviceUuid: _serviceUuid, charUuid: e),
//     )
//     .toList();

// class EMGMonitor extends StatefulWidget implements AbstractApp {
//   static final Signature signature = Signature(_signals);

//   static final List<Measurement> measurements = _signals
//       .map((s) =>
//           Measurement(s, bitLength: 24, endian: Endian.big, sampleRate: 2000))
//       .toList();

//   @override
//   final AppData appData;

//   @override
//   final ValueNotifier<bool> disconnect;

//   @override
//   String get name => 'EMG Monitor';

//   const EMGMonitor(this.appData, this.disconnect, {Key? key}) : super(key: key);

//   @override
//   State<EMGMonitor> createState() => _EMGMonitorState();
// }

// class _EMGMonitorState extends State<EMGMonitor> with FileSavingMixin {
//   @override
//   String get projectName => widget.name;

//   @override
//   AppData get appData => widget.appData;

//   @override
//   bool get wantCloudSaving => true;

//   @override
//   bool get wantLocalSaving => true;

//   @override
//   Widget build(BuildContext context) {
//     startSaving();
//     return Container();
//   }
// }
