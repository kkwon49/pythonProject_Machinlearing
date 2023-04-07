import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/app_connection_model.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:flutter/material.dart';
import 'package:fl_new/apps/app_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'app_function.dart';
import 'package:collection/collection.dart';

class DeviceControllable {
  final Uuid service;
  final Uuid characteristic;
  final Device? device;

  DeviceControllable({
    required this.service,
    required this.characteristic,
    this.device,
  });

  DeviceControllable.fromSignal(Signal signal, {required this.device})
      : service = signal.serviceUuid,
        characteristic = signal.charUuid;
}

/// Allows for low-level control of BLE characteristics, including
/// reading/writing, listening to changes, and registering callbacks.
mixin DeviceControl<T extends StatefulWidget> on State<T>
    implements AppFunction {
  @override
  @protected
  AppData get appData;

  Future<BluetoothCharacteristic?> _getCharacteristic(
      BluetoothDevice device, DeviceControllable endpoint) async {
    BluetoothCharacteristic? targetCharacteristic;
    List<BluetoothService> services = await device.discoverServices();

    int i = 0;
    while (i < services.length && targetCharacteristic == null) {
      bool correctService = services[i].uuid.toString() == endpoint.service;
      if (correctService) {
        targetCharacteristic = services[i].characteristics.firstWhereOrNull(
            (c) => c.uuid.toString() == endpoint.characteristic);
      }
      i++;
    }

    return targetCharacteristic;
  }

  BluetoothDevice? _getBluetoothDevice(Device? device) {
    ConnectionGroup group =
        Provider.of<ConnectionGroup>(context, listen: false);

    if (device != null) {
      return group.connectionMap[device]?.device;
    }
    throw StateError("getBLEDevice");
    // return group.connectionMap.entries.firstOrNull?.value.device;
  }

  Future<bool> write(List<int> bytes,
      {required DeviceControllable endpoint}) async {
    BluetoothDevice? bleDevice = _getBluetoothDevice(endpoint.device);

    if (bleDevice != null) {
      BluetoothCharacteristic? c =
          await _getCharacteristic(bleDevice, endpoint);
      try {
        await c?.write(bytes);
      } on PlatformException catch (e) {
        print(e.message);
        return false;
      }
      return true;
    }
    return false;
  }

  Future<List<int>?> read({required DeviceControllable endpoint}) async {
    BluetoothDevice? bleDevice = _getBluetoothDevice(endpoint.device);

    List<int>? values;
    if (bleDevice != null) {
      BluetoothCharacteristic? c =
          await _getCharacteristic(bleDevice, endpoint);
      try {
        values = await c?.read();
      } on PlatformException catch (e) {
        print(e.message);
      }
    }
    return values;
  }

  // Future<bool> unregisterCallback(
  //   VoidCallback callback, {
  //   required Uuid serv,
  //   required Uuid char,
  // }) async {
  //   BluetoothCharacteristic? c = _getCharacteristic(serv, char);
  //   await c?.setNotifyValue(false);
  //   return c == null;
  // }

  // Future<bool> registerCallback(
  //   Function(List<int>) callback, {
  //   required Uuid serv,
  //   required Uuid char,
  // }) async {
  //   BluetoothCharacteristic? c = _getCharacteristic(serv, char);
  //   await c?.setNotifyValue(true);
  //   c?.value.listen((event) => callback(event));
  //   return c == null;
  // }

  Future<Stream<List<int>>?> listen(
      {required DeviceControllable endpoint}) async {
    BluetoothDevice? bleDevice = _getBluetoothDevice(endpoint.device);

    Stream<List<int>>? valueStream;
    if (bleDevice != null) {
      BluetoothCharacteristic? c =
          await _getCharacteristic(bleDevice, endpoint);
      await c?.setNotifyValue(true);
      valueStream = c?.value;
    }
    return valueStream;
  }
}
