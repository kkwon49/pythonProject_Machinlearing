import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/app_functions/app_function.dart';
import 'package:fl_new/connections/app_connection_model.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:unique_identifier/unique_identifier.dart';
import '../buffers/buffers.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin FileSaving<T extends StatefulWidget> on State<T> implements AppFunction {
  final List<_FileWriter> _writers = [];
  bool _initialized = false;
  late final VoidCallback _dispose;

  @protected
  String get projectName;

  @override
  @protected
  AppData get appData;

  @protected
  bool get wantLocalSaving => true;

  @protected
  bool get wantCloudSaving => false;

  @protected
  List<Measurement> get ignoredMeasurements => [];

  @protected
  void registerCustomSaving(Stream<String> out, {required String fileName}) {
    out.listen((event) async {}, cancelOnError: true);
  }

  _FileWriter _makeWriter(
    ConnectionGroup connectionGroup,
    Measurement measurement,
  ) {
    // Make FunctionBuffer for this measurement
    int startMillis = connectionGroup.start.millisecondsSinceEpoch;
    DateTime start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final saveInterval = measurement.sampleRate > 5
        ? const Duration(seconds: 3)
        : const Duration(seconds: 10);
    var buffer = FunctionBuffer(appData, measurement, rollover: saveInterval);

    // Create FunctionBuffera
    BluetoothDevice targetDevice = connectionGroup.connections
        .singleWhere(
          (connection) => connectionGroup
              .getMeasurements(connection)!
              .contains(measurement),
        )
        .device;

    final writer = _FileWriter(
      buffer,
      appName: projectName,
      device: targetDevice,
      startTime: start,
      measurement: measurement,
    );

    return writer;
  }

  /// Adds untracked measurements and removes those from devices no
  /// longer connected.
  void _setCurrentWriters(ConnectionGroup connectionGroup) {
    final connectedMeasurements = connectionGroup.connectedMeasurements
        .toSet()
        .difference(ignoredMeasurements.toSet());
    final writerMeasurements =
        _writers.map((writer) => writer.buffer.measurement).toSet();

    final toRemove = writerMeasurements.difference(connectedMeasurements);
    final toAdd = connectedMeasurements.difference(writerMeasurements);

    // turn off and remove the recently disconnected writers
    final writersToRemove = _writers
        .where((writer) => toRemove.contains(writer.buffer.measurement));
    for (_FileWriter writer in writersToRemove) {
      writer.stop();
    }

    _writers
        .removeWhere((writer) => toRemove.contains(writer.buffer.measurement));

    final newWriters = toAdd.map(
      (measurement) => _makeWriter(
        connectionGroup,
        measurement,
      ),
    );
    _writers.addAll(newWriters);
  }

  void _setAndRunWriters(ConnectionGroup connectionGroup) {
    _setCurrentWriters(connectionGroup);
    for (_FileWriter writer in _writers) {
      writer.start();
    }
  }

  /// Called with each `startSaving` call to set `_writers` according to the
  /// currently connected devices, which is necessary if they have never been
  /// set before or if saving was stopped via `stopSaving`.
  void _initialize() {
    ConnectionGroup connectionGroup =
        Provider.of<ConnectionGroup>(context, listen: false);

    final onGroupUpdate = () {
      if (!connectionGroup.isEmpty) {
        _setAndRunWriters(connectionGroup);
      }
    };

    connectionGroup.addListener(onGroupUpdate);
    _dispose = () => connectionGroup.removeListener(onGroupUpdate);

    _setAndRunWriters(connectionGroup);
  }

  /// Start saving files locally if they are not already saving. Has no effect
  /// if saving has already started and not yet been stopped with a call to
  /// `stopSaving`.
  @protected
  void startSaving() async {
    if (!_initialized && (wantCloudSaving || wantLocalSaving)) {
      _writers.clear();
      _initialize();
      _initialized = true;
    }
  }

  /// Stop saving files locally if they are already saving. Has no effect
  /// if saving has not already started or already stopped with this function.
  /// A `BuildContext` of the nearest ancestor stateful widget should be
  /// provided if cloud uploading after data collection is desired so that
  /// and upload status window can be shown to the user.
  @protected
  void stopSaving([BuildContext? parentContext]) async {
    if (_initialized) {
      // make streams for connected group devices and enable streaming
      for (_FileWriter writer in _writers) {
        writer.stop();
      }

      _dispose();
      _initialized = false;
      if (wantCloudSaving && parentContext != null) {
        _uploadAll(parentContext);
      }
    }
  }

  _showUploadDialog(Future<List<bool>> statuses, BuildContext parentContext) {
    // schedule display for immediately after we return to the scan screen
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        showDialog(
          context: parentContext,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return FutureBuilder<List<bool>>(
              future: statuses,
              builder: (context, snapshot) {
                ConnectionState state = snapshot.connectionState;
                if (state != ConnectionState.done) {
                  return AlertDialog(
                    title: const Text("File Upload"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Please wait for file upload to complete."),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: CircularProgressIndicator(),
                          )
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return AlertDialog(
                    title: const Text("File Upload"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "No files to upload.\nDisregard if this is expected.",
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Icon(
                              Icons.question_mark,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Continue"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                } else if (snapshot.hasData && _all(snapshot.data!)) {
                  return AlertDialog(
                    title: const Text("File Upload"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("File upload success!"),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Icon(Icons.check, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Continue"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                }
                return AlertDialog(
                  title: const Text("File Upload"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Upload failed. Please contact us for assistance"),
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Icon(Icons.error, size: 40, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Continue"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Upload all buffers' current and past data to the cloud. Has no effect
  /// if `wantCloudSaving()` returns `false`.
  @protected
  Future<void> _uploadAll(BuildContext parentContext) async {
    // send all csv files found non-recursively within the root shared
    // by all the writers
    Directory root = _writers.first.root!;
    Iterable<File> candidateFiles = root.listSync().whereType<File>();
    Future<List<bool>> statuses = Future.wait(
      candidateFiles
          .where(
            (file) => file.path.substring(file.path.length - 4) == ".csv",
          )
          .map(
            (csvFile) async => await _handleFileUpload(csvFile),
          ),
    );
    _showUploadDialog(statuses, parentContext);
  }

  Future<bool> _handleFileUpload(File file) async {
    UploadTask? upload = await _uploadFile(file)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (upload == null) {
      return false;
    }
    return await _checkStatus(upload);
  }

  Future<UploadTask?> _uploadFile(File? target) async {
    if (target == null) {
      // _displayToast('Data is not ready for upload yet.', Colors.redAccent);
      return null;
    } else {
      // get existing top-level (i.e. app-specific) directories
      ListResult topLevelDirectories =
          await FirebaseStorage.instance.ref().listAll();

      List<Reference> possibleReferences = topLevelDirectories.prefixes
          .where((p) => p.fullPath == projectName)
          .toList();

      // upload to existing app directory or create a new one if one doesn't exist
      Reference targetReference;
      if (possibleReferences.isNotEmpty) {
        targetReference = possibleReferences.first;
      } else {
        var base = FirebaseStorage.instance.ref();
        targetReference = base.child(projectName);
      }

      // build out path to be used in cloud filestore
      int rootIdx = target.path.indexOf(projectName);
      String fileCloudPath =
          target.path.substring(rootIdx + projectName.length);

      String dbPath = targetReference.fullPath;
      Reference fileRef = FirebaseStorage.instance.ref(dbPath + fileCloudPath);

      // monitor upload with async UploadTask instance
      UploadTask upload = fileRef.putFile(target);
      return Future.value(upload);
    }
  }

  /// Returns a future that evaluates to `true` when this firebase `UploadTask`
  /// is complete.
  Future<bool> _checkStatus(UploadTask task) async {
    bool result = false;
    await for (TaskSnapshot snapshot in task.snapshotEvents) {
      TaskState state = snapshot.state;
      if (state == TaskState.success) {
        result = true;
        break;
      }
      // TODO: maybe handle other states here
    }
    return result;
  }

  /// Return `false` if this list of boolean values contains `false` and `true`
  /// otherwise.
  bool _all(List<bool> list) => !list.contains(false);
}

/// Provides a simple interface for writing the possibly multichannel data of a
/// `DataStream` to a file and uploading it the cloud.
class _FileWriter extends BufferedFunction {
  File? _file;
  final Measurement? measurement;
  final BluetoothDevice? device;
  final String appName;
  final DateTime? startTime;
  bool _started;
  Directory? _root;

  // DataPoint _mostRecentHeader = DataPoint(0, 0);

  Directory? get root => _root;

  _FileWriter(
    super.buffer, {
    required this.appName,
    this.device,
    this.measurement,
    this.startTime,
    super.startImmediately,
  }) : _started = startImmediately {
    _initialize();
    // buffer.addListener(() {});
  }

  @override
  bool get started => _started;

  @override
  void start() {
    if (!_started) {
      buffer.addListener(() => _bufferCallback());
      _started = true;
    }
  }

  @override
  void stop() {
    if (_started) {
      buffer.removeListener(() => _bufferCallback());
      _started = false;
      // print("Stopped $hashCode");
    }
  }

  @override
  void toggle() {
    _started ? stop() : start();
  }

  void _bufferCallback() {
    List<List<DataPoint>> data = buffer.mostRecent;
    if (data[0].isNotEmpty) {
      csvWrite(data);
      // _mostRecentHeader = data[0].first;
    }
  }

  void _initialize() async {
    _root = await _getRoot();
    _file = await _createTargetFile();
  }

  static Future<void> _isolateWrite(List<dynamic> args) async {
    ListToCsvConverter converter = const ListToCsvConverter();
    var file = File(args[0]);
    List<List<dynamic>> stringData = args[1];

    // TODO: provide option to save ISO-formatted timestamps
    // List<List<String>> stringData = args[1]
    //     .map<List<String>>(
    //       (List<dynamic> dpList) => [
    //         DateTime.fromMillisecondsSinceEpoch((dpList[0] * 1000).toInt(),
    //                 isUtc: true)
    //             .toIso8601String(),
    //         ...dpList.sublist(1).map((e) => e.toString())
    //       ],
    //     )
    //     .toList();

    String csvString = converter.convert(stringData) + '\r\n';

    await file.writeAsString(csvString, mode: FileMode.append);
  }

  Future<void> write(String data, {FileMode mode = FileMode.append}) async {
    await _file?.writeAsString(data, mode: mode);
  }

  Future<void> csvWrite(List<List<DataPoint>> data,
      {FileMode fileMode = FileMode.append}) async {
    // turn DataPoint list into string for writing
    List<List<dynamic>> csvData = List.generate(
      data[0].length,
      (_) => List.generate(data.length + 1, (_) => 0.0),
    );

    for (var timeIdx = 0; timeIdx < data[0].length; timeIdx++) {
      for (var ch = 0; ch < data.length + 1; ch++) {
        if (ch == 0) {
          csvData[timeIdx][ch] = data[ch][timeIdx].x;
        } else {
          csvData[timeIdx][ch] = data[ch - 1][timeIdx].y;
        }
      }
    }

    // spawn thread for slow file system I/O
    if (_file != null) {
      compute(_FileWriter._isolateWrite, [_file!.path, csvData]);
      // print("$hashCode saved ${_file?.path}");
    }
  }

  List<String>? _splitDateTime() {
    String? datetimeString = startTime?.toIso8601String().split('.')[0];
    return datetimeString?.split('T');
  }

  Future<Directory> _getRoot() async {
    List<String>? splitDateTime = _splitDateTime();
    String? date = splitDateTime?[0];
    String? time = splitDateTime?[1].replaceAll(RegExp(r':'), "_");

    var settings = await SharedPreferences.getInstance();
    String? patientNumber = settings.getInt('patientNumber')?.toString();

    String id;
    if (patientNumber == null) {
      String identifier = "";
      try {
        identifier = (await UniqueIdentifier.serial)!;
      } on PlatformException {
        identifier = 'Failed to get Unique Identifier';
      }
      id = "Unidentified/$identifier";
    } else {
      id = patientNumber;
    }

    Directory base = Directory(
      await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOCUMENTS),
    );

    if (date != null) {
      return await Directory(
        "${base.path}/$appName/$date/$id/$time/",
      ).create(recursive: true);
    }

    return await Directory(
      "${base.path}/$appName/$id/",
    ).create(recursive: true);
  }

  /// Asynchronously returns the file to be periodically saved by this instance.
  Future<File> _createTargetFile() async {
    String macAddress =
        device?.id.toString().replaceAll(RegExp(':'), '') ?? "custom";
    String filePath = root!.path + macAddress + "_" + (measurement?.name ?? "");

    List<FileSystemEntity> entities = root!.listSync(followLinks: false);
    int duplicates = entities.where((e) => e.path.contains(filePath)).length;

    if (duplicates == 0) {
      filePath += '.csv';
      return File(filePath);
    } else if (duplicates == 1) {
      return entities[0] as File;
    }

    filePath += "_${duplicates++}";
    return File(filePath);
  }
}

// https://github.com/dart-lang/samples/blob/master/isolates/bin/long_running_isolate.dart
// class IsolateService<T> {
//   final void Function(T) _toCompute;
//   final ReceivePort _receivePort;

//   SendPort get port => _receivePort.sendPort;

//   IsolateService(void Function(T) toCompute)
//       : _toCompute = toCompute,
//         _receivePort = ReceivePort();

//   static void _compute(SendPort port, dynamic message) async {
//     throw UnimplementedError();
//   }

//   void compute(SendPort port, T message) async {
//     await port.send(message);
//   }

//   Stream streamCompute(T input) async* {
//     throw UnimplementedError();
//   }
// }

// Future<void> _isolateEntry(List<dynamic> args) async {
//   // Send a SendPort to the main isolate so that it can send JSON strings to
//   // this isolate.
//   SendPort p = args[0];
//   void Function(dynamic) func = args[0];

//   final commandPort = ReceivePort();
//   p.send(commandPort.sendPort);
//   // Wait for messages from the main isolate.
//   await for (var message in commandPort) {
//     if (message is String) {
//       // Read and decode the file.
//       final contents = await File(message).readAsString();

//       // Send the result to the main isolate.
//       p.send(jsonDecode(contents));
//     } else if (message == null) {
//       // Exit if the main isolate sends a null message, indicating there are no
//       // more files to read and parse.
//       break;
//     }
//   }

//   print('Spawned isolate finished.');
//   Isolate.exit();
// }
