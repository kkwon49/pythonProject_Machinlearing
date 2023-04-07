import 'package:fl_new/apps/projects/ethiopia_project.dart';
import 'package:fl_new/apps/projects/fdc_pressure_sensor.dart';
import 'package:fl_new/apps/projects/led_driver.dart';
import 'package:fl_new/apps/projects/pressure_sensor.dart';
import 'package:fl_new/connections/app_connection_model.dart';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/apps/projects/choa_patch.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/app_data.dart';
import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

class View extends StatefulWidget {
  // final ConnectionGroup connectionGroup;
  late final Future<String> name;
  final Completer<String> _nameCompleter = Completer();

  View({super.key}) {
    name = _nameCompleter.future;
  }

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with AutomaticKeepAliveClientMixin {
  BluetoothDeviceState? _state = BluetoothDeviceState.connected;
  AbstractApp? targetAppWidget;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
  }

  // Future<AppData> _getAppData(ConnectionGroup connectionGroup) async {
  //   List<Connection> connections = connectionGroup.connections;

  //   // For each connection, make a list of DataStreams from its measurements
  //   // NOTE: cannot use Future.wait as it attempts concurrent descriptor
  //   // writes and results in a driver error.
  //   // See https://github.com/pauldemarco/flutter_blue/issues/295#issuecomment-774809433
  //   Map<Connection, List<DataStream>> appDataMap = {};
  //   for (Connection connection in connections) {
  //     List<Measurement> measurements =
  //         connectionGroup.getMeasurements(connection)!;

  //     // datastreams for all measurements for this connection
  //     List<DataStream> dataStreams =
  //         await _makeDataStreams(connection, measurements);
  //     appDataMap[connection] = dataStreams;
  //   }

  //   return AppData.multiple(appDataMap);
  // }

  AbstractApp? _getAppWidget(ConnectionGroup connectionGroup) {
    assert(connectionGroup.initialized);
    AppData appData = connectionGroup.appData!;

    switch (connectionGroup.app.type) {
      // TODO: add more devices here as they are needed.
      case ChoaPatch:
        targetAppWidget = ChoaPatch(appData);
        break;
      case FlexTech:
        targetAppWidget = FlexTech(appData);
        break;
      case LEDDriver:
        targetAppWidget = LEDDriver(appData);
        break;
      case PostpartumMonitor:
        targetAppWidget = PostpartumMonitor(appData);
        break;
      case EarPPG:
        targetAppWidget = EarPPG(appData);
        break;
      case PpgChoaPatch:
        targetAppWidget = PpgChoaPatch(appData);
        break;
      case FdcPressureSensor:
        targetAppWidget = FdcPressureSensor(appData);
        break;
      case SmartMask:
        targetAppWidget = SmartMask(appData);
        break;
      case EthiopiaProject:
        targetAppWidget = EthiopiaProject(appData);
        break;
      default:
        return null;
    }

    if (!widget._nameCompleter.isCompleted) {
      widget._nameCompleter.complete(targetAppWidget!.name);
    }

    return targetAppWidget!;
  }

  @override
  bool get wantKeepAlive =>
      _state == null || _state != BluetoothDeviceState.disconnected;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ConnectionGroup>(
      builder: (context, group, child) {
        AbstractApp? targetApp = _getAppWidget(group);
        if (targetApp != null) {
          group.navigateOnNewConnection = targetApp.navigateOnNewConnection;
          return targetApp;
        }

        return Column(children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomCenter,
              child: const Icon(Icons.warning),
            ),
          ),
          Expanded(
            child: Column(
              children: const [
                Expanded(child: Text("Error getting app.")),
                Expanded(child: Text("Restart target device and try again.")),
              ],
            ),
          ),
        ]);
      },
    );
  }
}
