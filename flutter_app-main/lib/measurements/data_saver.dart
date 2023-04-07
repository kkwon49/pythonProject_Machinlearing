import 'dart:io';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unique_identifier/unique_identifier.dart';
import 'measurement.dart';
import 'package:external_path/external_path.dart';

class DataSaver {
  final DateTime start;
  final Measurement measurement;
  final String project;
  late final String _id;
  File? _file;
  int channel;
  bool _initialized = false;

  DataSaver(
      {required this.project,
      required this.measurement,
      required this.channel,
      required this.start});

  static Future<String> _getID() async {
    return (await UniqueIdentifier.serial)!.toUpperCase();
  }

  Future<Directory> _getRoot() async {
    // return the Documents folder on android
    return Directory(await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS));
  }

  List<String> _splitDateTime() {
    String datetimeString = start.toIso8601String().split('.')[0];
    return datetimeString.split('T');
  }

  Future<Directory> _getTargetDirectory() async {
    List<String> splitDateTime = _splitDateTime();
    String date = splitDateTime[0];
    String time = splitDateTime[1].replaceAll(RegExp(r':'), "_");
    String measName = measurement.name;

    Directory root = await _getRoot();

    return await Directory("${root.path}/$project/$date/$_id/$measName/$time/")
        .create(recursive: true);
  }

  Future<File> _createTargetFile() async {
    Directory dataDir = await _getTargetDirectory();

    List<String> splitDateTime = _splitDateTime();
    String date = splitDateTime[0].replaceAll(RegExp(r'-'), "_");
    String time = splitDateTime[1].replaceAll(RegExp(r':'), "_");

    String filePath =
        dataDir.path + "$_id-$date-${measurement.name}-$time-ch$channel";

    List<FileSystemEntity> entities = dataDir.listSync(followLinks: false);
    int duplicates = entities.where((e) => e.path.contains(filePath)).length;

    if (duplicates > 0) {
      filePath += "_${duplicates++}";
    }

    filePath += '.csv';

    File file = await File(filePath).create();

    return file;
  }

  Future<void> _initialize() async {
    // Obtain permissions
    if (!await Permission.storage.status.isGranted) {
      await Permission.storage.request();
    }

    _id = await _getID();

    // create target file
    _file = await _createTargetFile();

    _initialized = true;
  }

  /// Saves the file `csvData`
  Future<bool> _localSave(String csvData) async {
    bool failed = false;
    try {
      await _file!.writeAsString(csvData, mode: FileMode.append);
    } on IOException {
      failed = true;
    }
    return failed;
  }

  saveData(List<DataPoint> data) async {
    if (!_initialized) {
      await _initialize();
    }

    ListToCsvConverter converter = const ListToCsvConverter();
    List<List<dynamic>> csvData =
        data.map((DataPoint d) => [d.x, d.y]).toList();
    String csvString = converter.convert(csvData) + '\r\n';

    // Write data and notify user
    _localSave(csvString);
  }
}
