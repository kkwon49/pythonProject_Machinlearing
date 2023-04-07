import 'dart:async';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/connections/connections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fl_new/measurements/measurement.dart';

export 'signals.dart' show Signal, SignalType, Uuid;
export 'view.dart' show View;

class Connection {
  static const List<String> ignoredServices = [
    '00001800-0000-1000-8000-00805f9b34fb',
    '00001801-0000-1000-8000-00805f9b34fb',
    '0000180a-0000-1000-8000-00805f9b34fb',
    '0000180f-0000-1000-8000-00805f9b34fb'
  ];

  final BluetoothDevice device;
  late final Stream<dynamic>? stateStream;
  late final Future<App?> app;
  List<BluetoothService>? _services;
  final List<BluetoothService> services;
  final ValueNotifier<BluetoothDeviceState> stateNotifier;
  final Timestamp _timestamp;
  final Future<App?> Function(List<App>) resolveApps;

  bool get disconnected =>
      stateNotifier.value == BluetoothDeviceState.disconnected;

  List<BluetoothService>? get servicesSync => _services;

  bool isIgnorable(BluetoothService service) =>
      Connection.ignoredServices.contains(service.uuid.toString());

  DateTime get start => _timestamp.now() ?? DateTime.now();

  Connection(this.device, this.services, {required this.resolveApps})
      : _timestamp = Timestamp(),
        stateNotifier = ValueNotifier(BluetoothDeviceState.connected)
  // services = Future.value(device.discoverServices()) {
  {
    // services.then((value) => _services = value);
    app = Future.value(_resolveApps());
    device.state.listen((event) => stateNotifier.value = event);
  }

  bool equals(Device device) {
    var relevantServices = services.where((service) => !isIgnorable(service));
    if (relevantServices.length < device.serverMap.length) {
      return false;
    }

    final connectionAttributes = {
      for (var service in relevantServices)
        service.uuid.toString(): Set<Uuid>.from(
          service.characteristics.map(
            (characteristic) => characteristic.uuid.toString(),
          ),
        )
    };

    // Check if the given device already has an associated connection
    Map<Uuid, Set<Uuid>> requiredAttributes = device.serverMap;

    // Attributes match if their services are identical and the service
    // characteristics for the given device contain all of the connection's
    // characteristics for the same service.
    Iterable<bool> attributesMatch = requiredAttributes.entries.map((entry) =>
        connectionAttributes.containsKey(entry.key) &&
        connectionAttributes[entry.key]!.containsAll(entry.value));

    // return false if any attributes do not match, otherwise these are equal
    return attributesMatch.where((match) => !match).isEmpty;
  }

  Future<App?> _resolveApps() async {
    // find apps matching this device's services
    List<App> apps = App.values
        .where((app) => app.devices.map(
              (device) {
                return equals(device);
              },
            ).any((match) => match))
        .toList();

    if (apps.length > 1) {
      return resolveApps(apps);
    } else if (apps.length == 1) {
      return apps.first;
    }

    return null;
  }
}
