// import 'dart:typed_data';
// import 'package:fl_new/apps/abstract_app.dart';
// import 'package:fl_new/apps/app_data.dart';
// import 'package:fl_new/apps/app_functions/app_function.dart';
// import 'package:fl_new/connections/connection.dart';
// import 'package:fl_new/measurements/measurement.dart';
// import 'package:fl_new/widgets/widgets.dart';
// import 'package:flutter/material.dart';

// class PpgScg extends StatefulWidget implements AbstractApp {
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
//         channels: 2),
//     Measurement(
//       Signal(
//         SignalType.acceleration,
//         serviceUuid: "228ba3a0-35fd-875f-39fe-b2a394d28057",
//         charUuid: "0000a3a5-0000-1000-8000-00805f9b34fb",
//       ),
//       signed: true,
//       channels: 3,
//       sampleRate: 250,
//       bitLength: 24,
//       endian: Endian.big,
//       conversion: 1 / 16.0 / 524288.0 * 2.048,
//     ),
//   ];

//   static const List<Signal> _signals = [
//     Signal(
//       SignalType.ppg,
//       serviceUuid: "228baec0-35fd-875f-39fe-b2a394d28057",
//       charUuid: "228baec1-35fd-875f-39fe-b2a394d28057",
//     ),
//     Signal(
//       SignalType.acceleration,
//       serviceUuid: "228ba3a0-35fd-875f-39fe-b2a394d28057",
//       charUuid: "0000a3a5-0000-1000-8000-00805f9b34fb",
//     ),
//   ];

//   static const Signature signature = Signature(_signals);

//   @override
//   final AppData appData;

//   @override
//   String get name => "PPG-SCG";

//   @override
//   final ValueNotifier<bool> disconnect;

//   const PpgScg(this.appData, this.disconnect, {Key? key}) : super(key: key);

//   @override
//   State<PpgScg> createState() => _PpgScgState();
// }

// class _PpgScgState extends State<PpgScg>
//     with FileSavingMixin, PlottingMixin, CloudComputationMixin {
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
//     });
//     return Column(
//       children: [
//         Expanded(
//           flex: 1,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(8.0, 4, 8.0, 0),
//             child: BorderedContainer(
//               padding: const EdgeInsets.all(0),
//               label: "PPG",
//               child: makePlot(PpgScg.measurements[0], channel: 1),
//             ),
//           ),
//         ),
//         Expanded(
//           flex: 3,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
//             child: BorderedContainer(
//               label: "Acceleration",
//               child: Column(
//                 children: [
//                   Expanded(
//                     child: makePlot(
//                       PpgScg.measurements[1],
//                       channel: 0,
//                       includeYLabels: true,
//                       decimals: 0,
//                       yMin: -2,
//                       yMax: 2,
//                       downsample: true,
//                     ),
//                   ),
//                   Expanded(
//                     child: makePlot(
//                       PpgScg.measurements[1],
//                       channel: 1,
//                       includeYLabels: true,
//                       decimals: 0,
//                       yMin: -2,
//                       yMax: 2,
//                       downsample: true,
//                     ),
//                   ),
//                   Expanded(
//                     child: makePlot(
//                       PpgScg.measurements[1],
//                       channel: 2,
//                       includeYLabels: true,
//                       decimals: 0,
//                       yMin: -2,
//                       yMax: 2,
//                       downsample: true,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }
