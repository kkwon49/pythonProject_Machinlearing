// import 'package:fl_new/apps/abstract_app.dart';
// import 'package:fl_new/apps/app_data.dart';
// import 'package:fl_new/apps/app_functions/file_saving.dart';
// import 'package:fl_new/connections/connection.dart';
// import 'package:fl_new/measurements/measurement.dart';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';

// class PhTemp extends StatefulWidget implements AbstractApp {
//   // Class variables
//   final Map<Uuid, List<Uuid>> _uuids = const {
//     "228beef0-35fd-875f-39fe-b2a394d28057": [
//       "0000eef1-0000-1000-8000-00805f9b34fb",
//       "0000eef2-0000-1000-8000-00805f9b34fb"
//     ]
//   };

//   static const List<Signal> _signals = [
//     Signal(SignalType.ph,
//         serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
//         charUuid: "0000eef1-0000-1000-8000-00805f9b34fb"),
//     Signal(SignalType.temperature,
//         serviceUuid: "228beef0-35fd-875f-39fe-b2a394d28057",
//         charUuid: "0000eef2-0000-1000-8000-00805f9b34fb")
//   ];

//   static const Signature signature = Signature(PhTemp._signals);

//   // intance variables
//   final List<Measurement> measurements = _signals
//       .map((sig) => Measurement(sig,
//           bitLength: 24, sampleRate: 1, endian: Endian.big, channels: 16))
//       .toList();

//   @override
//   String get name => '16 Channel pH & Temperature';

//   @override
//   final AppData appData;

//   @override
//   final ValueNotifier<bool> disconnect;

//   PhTemp({required this.appData, required this.disconnect, Key? key})
//       : super(key: key);

//   @override
//   State<PhTemp> createState() => _PhTempState();
// }

// class _PhTempState extends State<PhTemp> with FileSavingMixin {
//   @override
//   void dispose() {
//     // uploadAll();
//     super.dispose();
//   }

//   @override
//   AppData get appData => widget.appData;

//   @override
//   String get projectName => widget.name;

//   @override
//   bool get wantLocalSaving => true;

//   @override
//   bool get wantCloudSaving => true;

//   @override
//   Widget build(BuildContext context) {
//     startSaving();
//     widget.disconnect.addListener(() async {
//       stopSaving();
//       // await uploadAll();
//     });
//     return Container();
//   }
// }
