import 'dart:collection';
import 'package:fl_new/connections/connections.dart';
import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/cupertino.dart';

/// A `Device` object (not to be confused with `BluetoothDevice`)
/// is a compile-time constant declared by project files for easy run-time
/// mapping of connected BLE devices to their relevant group. Each
///
/// Because they are compile-time constants, the compiler will optimize away
/// `Device` objects with identical fields to save space. Instances can
/// therefore use a project-unique ID `id` (of arbitrary type) to prevent
/// declared devices with otherwise identical fields from being optimized
/// into a single object, which would prevent accurate `Device` grouping.
class Device<T> {
  final T? id;
  final List<Measurement> _measurements;
  final String? name;

  List<Uuid> get services {
    return _measurements
        .map((measurement) => measurement.signal.serviceUuid)
        .toList();
  }

  List<Measurement> get measurements => UnmodifiableListView(_measurements);

  List<Signal> get signals => measurements.map((m) => m.signal).toList();

  Map<Uuid, Set<Uuid>> get serverMap {
    Map<Uuid, Set<Uuid>> server = {};
    for (Signal signal in signals) {
      Uuid service = signal.serviceUuid;
      Uuid characteristic = signal.charUuid;

      if (server.containsKey(service)) {
        server[service]!.add(characteristic);
      } else {
        server[service] = {characteristic};
      }
    }

    return server;
  }

  void add(Measurement measurement) => _measurements.add(measurement);

  void remove(Measurement measurement) => _measurements.remove(measurement);

  bool contains(Measurement measurement) => _measurements.contains(measurement);

  const Device(this._measurements, {this.id, this.name});
}
