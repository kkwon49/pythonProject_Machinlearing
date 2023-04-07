import 'dart:async';

import 'package:fl_new/measurements/measurement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:collection/collection.dart';
import 'package:fl_new/connections/connections.dart';
import '../apps/apps.dart';

/// The `AppConnectionModel` handles low-level details of devices connecting
/// and disconnecting. It tracks currently connected devices and their
/// groups, and being a `ChangeNotifier` can be provided to project views
/// as an inherited widget through the Provider package, allowing for
/// views to monitor other apps and build accordingly as their state
/// changes.
///
/// There is only one `AppConnectionModel` instance per runtime.
class AppConnectionModel extends ChangeNotifier {
  // singleton pattern
  static final AppConnectionModel _instance = AppConnectionModel._internal();

  AppConnectionModel._internal();

  factory AppConnectionModel() => _instance;

  final List<ConnectionGroup> _groups = [];

  final Set<Connection> _connections = {};

  // Get current number of individual devices connected
  int get numConnected => _connections.length;

  /// Get currently connected devices. The order is identical to the
  /// `connections` getter.
  List<BluetoothDevice> get devices =>
      UnmodifiableListView(_connections.map((c) => c.device));

  /// Get currently connected `Connection` objects, which contain metadate on
  /// the low-level `BluetoothDevice` objects (available from the `devices`
  /// getter).
  List<Connection> get connections => UnmodifiableListView(_connections);

  List<ConnectionGroup> get groups => UnmodifiableListView(_groups);

  ConnectionGroup? groupOf(Connection connection) {
    return _groups.firstWhereOrNull(
      (group) => group.connections.contains(connection),
    );
  }

  Connection? connectionOf(BluetoothDevice device) {
    return connections.firstWhereOrNull((c) => c.device == device);
  }

  bool isConnected(BluetoothDevice device) => devices.contains(device);

  void _onConnectionStateChange(Connection connection) {
    if (connection.disconnected) {
      remove(connection);
    }
  }

  Future<ConnectionGroup> add(Connection connection) async {
    App? targetApp = await connection.app;

    if (targetApp == null) {
      throw StateError("No app found");
    }

    ConnectionGroup? targetGroup = _groups.firstWhereOrNull(
        (group) => group.isCompatible(connection) && !group.isFull);

    // add to group and register callback for disconnection
    _connections.add(connection);
    connection.stateNotifier.addListener(
      () => _onConnectionStateChange(connection),
    );

    if (targetGroup != null) {
      // existing group found and will be used
      await targetGroup.add(connection);
      notifyListeners();
      return targetGroup;
    }

    // new group made
    targetGroup = ConnectionGroup(entryPoint: connection, app: targetApp);
    _groups.add(targetGroup);

    return targetGroup;
  }

  void remove(Connection connection) {
    if (_connections.contains(connection)) {
      _connections.remove(connection);

      // find its group and remove it
      ConnectionGroup? containingGroup = groups.singleWhereOrNull(
        (group) => group.connections.contains(connection),
      );
      containingGroup?.remove(connection);

      // drop a group if it has no connections
      if (containingGroup?.connections.isEmpty ?? false) {
        _groups.remove(containingGroup);
        notifyListeners();
      }
    }
  }
}

/// `ConnectionGroup`s are `ChangeNotifier`s that notify listeners whenever
/// their group of connected `Device`s change. They can be wrapped with
/// inherited widgets via Provider or similar state management packages
/// exposed to child widgets such as project views to dynamically update
/// parts of the app widget tree as devices connect and disconnect from
/// tracked groups. `ConnectionGroup` behaior is undefined when no devices
/// are associated with it; a `Connection` entry point must therefore be
/// provided to every `ConnectionGroup` initialization.
class ConnectionGroup extends ChangeNotifier {
  final Map<Connection, Device> _connections = {};
  final AppData? _appData;
  final App app;
  late Connection _mostRecentChange;
  late final DateTime? _start;
  bool navigateOnNewConnection;
  bool _initialized;
  final Connection _entryPoint;

  bool get initialized => _initialized;

  AppData? get appData => _appData;

  /// Returns the `BluetoothCharacteristic` represented by `signal` in
  /// a list of services.
  BluetoothCharacteristic _fromServices(
      List<BluetoothService> services, Signal signal) {
    Uuid charUuid = signal.charUuid;
    Uuid servUuid = signal.serviceUuid;

    var targetService =
        services.firstWhere((s) => s.uuid.toString() == servUuid);
    var targetChar = targetService.characteristics
        .firstWhere((c) => c.uuid.toString() == charUuid);

    return targetChar;
  }

  Future<DataStream> _makeDataStream(
    Connection connection,
    Measurement measurement,
  ) async {
    BluetoothCharacteristic target =
        _fromServices(connection.services, measurement.signal);

    // set up BLE stream
    await target.setNotifyValue(true);
    var stream = target.value.asBroadcastStream();

    return DataStream(
      stream,
      connection: connection,
      measurement: measurement,
    );
  }

  Future<List<DataStream>> _makeDataStreams(Connection connection) async {
    List<DataStream> dataStreams = [];
    for (Measurement measurement in getMeasurements(connection)!) {
      dataStreams.add(await _makeDataStream(connection, measurement));
    }

    return dataStreams;
  }

  /// Returns `true` if this group has all of its connection requirements
  /// satisfied as determined by its `app`.
  bool get isFull => _connections.length == app.devices.length;

  /// Returns `true` if this group does not have all of its connection
  /// requirements satisfied as determined by its `app`.
  bool get isNotFull => !isFull;

  bool get isEmpty => _connections.isEmpty;

  DateTime get start => _start!;

  List<Device> get _unconnectedDevices {
    List<Device> unconnected = app.devices
        .where((device) => !_connections.values.contains(device))
        .toList();

    return unconnected;
  }

  Map<Device, Connection> get connectionMap {
    final reversedConnections =
        _connections.map((connection, device) => MapEntry(device, connection));

    return reversedConnections;
  }

  Connection get mostRecentChange => _mostRecentChange;

  /// Returns an umodifiable list containing all connections of this group
  /// in the order they were added.
  List<Connection> get connections => UnmodifiableListView(_connections.keys);

  List<Measurement> get connectedMeasurements {
    return connections.fold(
      <Measurement>[],
      (accumulatedMeasurements, connection) =>
          accumulatedMeasurements..addAll(getMeasurements(connection)!),
    );
  }

  /// Returns `true` if `connection` is in this group.
  bool contains(Connection connection) => connections.contains(connection);

  /// The number of devices currently in this group, including the `entryPoint`.
  int get size => _connections.length;

  /// Returns `true` if `connection` can be added to this group. A connection
  /// can be added when an unassigned device attributes match those of
  /// `connection`
  bool isCompatible(Connection connection) =>
      _unconnectedDevices.any((device) => connection.equals(device));

  List<Measurement>? getMeasurements(Connection connection) {
    return _connections[connection]?.measurements;
  }

  Connection? getConnection(Measurement measurement) {
    final connectionEntries = _connections.entries;
    return connectionEntries
        .firstWhereOrNull(
          (MapEntry<Connection, Device> entry) =>
              entry.value.measurements.contains(measurement),
        )
        ?.key;
  }

  bool _resolve(Connection connection) {
    // try to assign target as first potential device
    Device? target = _unconnectedDevices
        .firstWhereOrNull((device) => connection.equals(device));

    if (target != null) {
      _connections[connection] = target;
      return true;
    }
    return false;
  }

  /// Adds `connection` to this group, doing nothing if the group already
  /// contains `connection`.
  @protected
  Future<bool> add(Connection connection) async {
    if (_resolve(connection)) {
      _mostRecentChange = connection;

      List<DataStream> dataStreams = await _makeDataStreams(connection);
      _appData!.add(connection, dataStreams);

      connection.stateNotifier.addListener(() {
        if (connection.stateNotifier.value ==
            BluetoothDeviceState.disconnected) {
          remove(connection);
        }
      });
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Removes `connection` from this group if the group contains it does nothing
  /// otherwise. If `connection` is the `entryPoint`, the entryPoint becomes
  /// the earliest added connection still remaining in the group. If there are
  /// no connections remaining, `entryPoint` is `null`.
  @protected
  bool remove(Connection connection) {
    if (_connections.remove(connection) != null) {
      _appData!.remove(connection);
      _mostRecentChange = connection;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _setStart() async {
    _start = Timestamp().now() ?? DateTime.now();
  }

  Future<void> initialize() async {
    if (!_initialized) {
      await add(_entryPoint);
      _initialized = true;
    }
  }

  ConnectionGroup({
    required Connection entryPoint,
    required this.app,
    this.navigateOnNewConnection = true,
  })  : _appData = AppData(),
        _initialized = false,
        _entryPoint = entryPoint {
    _setStart();
  }
}
