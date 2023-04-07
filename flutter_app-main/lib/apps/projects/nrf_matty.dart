// import 'dart:typed_data';
// import 'package:fl_new/apps/abstract_app.dart';
// import 'package:fl_new/apps/app_data.dart';
// import 'package:fl_new/apps/app_functions/app_function.dart';
// import 'package:fl_new/connections/connection.dart';
// import 'package:fl_new/measurements/measurement.dart';
// import 'package:flutter/material.dart';

// class NRFMatty extends StatefulWidget implements AbstractApp {
//   static const List<Measurement> measurements = [
//     Measurement(
//         Signal(
//           SignalType.ppg,
//           serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
//           charUuid: "228baec1-35fd-875f-39fe-b2a394d28057",
//         ),
//         sampleRate: 50,
//         bitLength: 18,
//         endian: Endian.big,
//         conversion: 1 / 262144.0 * 16384.0,
//         channels: 2)
//   ];

//   static const List<Signal> _signals = [
//     Signal(
//       SignalType.ecg,
//       serviceUuid: "228baec0-35fd-875Sf-39fe-b2a394d28057",
//       charUuid: "228baec1-35fd-875f-39fe-b2a394d28057",
//     ),
//   ];

//   static const Signature signature = Signature(_signals);

//   @override
//   final AppData appData;

//   @override
//   String get name => "NRF Matty";

//   @override
//   final ValueNotifier<bool> disconnect;

//   const NRFMatty(this.appData, this.disconnect, {Key? key}) : super(key: key);

//   @override
//   State<NRFMatty> createState() => _NRFMattyState();
// }

// class _NRFMattyState extends State<NRFMatty>
//     with FileSavingMixin, PlottingMixin {
//   @override
//   String get projectName => widget.name;

//   @override
//   AppData get appData => widget.appData;

//   @override
//   bool get wantCloudSaving => false;

//   @override
//   bool get wantLocalSaving => true;

//   @override
//   Widget build(BuildContext context) {
//     startSaving();
//     widget.disconnect.addListener(() async {
//       stopSaving();
//       // await uploadAll();
//     });
//     return Column(
//       children: [
//         Expanded(
//           child: Row(
//             children: [
//               Expanded(
//                   child: makePlot(NRFMatty.measurements[0], channel: 1),
//                   flex: 4),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
