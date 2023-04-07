import 'dart:async';
import 'package:fl_new/apps/apps.dart';
import 'package:fl_new/settings.dart';
import 'package:fl_new/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:http/retry.dart';
import 'package:provider/provider.dart';
import 'connections/connections.dart';
import 'package:collection/collection.dart';
import 'package:fl_new/connections/app_connection_model.dart';

export 'package:fl_new/scan_screen.dart' show ScanScreen;
export 'package:fl_new/connections/app_connection_model.dart'
    show AppConnectionModel;

const TextStyle buttonStyle = TextStyle(fontSize: 16, color: Colors.white);

/// `ScanScreen` is the main entrypoint the the app. It allows for
/// controlling the Bluetooth scan to discovered devices, viewing
/// discovered and connected devices, viewing device details, and connecting
/// to devices to view their waveform or other data.
class ScanScreen extends StatelessWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBlue.instance.state,
      initialData: BluetoothState.unknown,
      builder: (c, snapshot) {
        var state = snapshot.data;
        if (state == BluetoothState.on) {
          return const FindDevicesScreen();
        }
        return const BluetoothOffScreen();
      },
    );
  }
}

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  _FindDevicesScreenState createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  bool _filteringOn = true;
  final AppConnectionModel _connectionModel = AppConnectionModel();
  final Map<View, ConnectionGroup> _views = {};

  /// Relates a `BluetoothDevice` to a `ValueNotifier` that notifies its
  /// listeners `true` when the device has disconnected.
  // final List<Connection> _connections = [];
  late TabController _tabController;
  bool _isScanning = false;

  Future<void> _assignExistingDevices() async {
    final existingDevices = await FlutterBlue.instance.connectedDevices;
    for (BluetoothDevice device in existingDevices) {
      final deviceServices = await device.discoverServices();
      _connectionModel.add(
          Connection(device, deviceServices, resolveApps: _promptSelectApp));
    }
  }

  @override
  void initState() {
    super.initState();
    _assignExistingDevices();
    _controller = TextEditingController();
    _tabController = _makeTabController();
    _connectionModel.addListener(_removeEmptyGroups);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _connectionModel.removeListener(_removeEmptyGroups);
    super.dispose();
  }

  void _toggleSwitch() {
    setState(() {
      _filteringOn = !_filteringOn;
    });
  }

  void _removeEmptyGroups() {
    setState(() {
      _views.removeWhere(
        (_, group) => !_connectionModel.groups.contains(group),
      );
    });
  }

  /// Returns the button for the user to control Bluetooth scanning. `timeout`
  /// controls how long a scan is active before being turned off autmatically,
  ///  if not provided, the scan never stops without user input.
  Widget _makeScanButton({Duration? timeout}) {
    return StreamBuilder<bool>(
      stream: FlutterBlue.instance.isScanning,
      initialData: _isScanning,
      builder: (_, snapshot) {
        bool scanning = snapshot.data!;
        _isScanning = scanning;
        if (scanning) {
          return ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.red),
              onPressed: () => FlutterBlue.instance.stopScan(),
              child: const Text('Stop Scan', style: buttonStyle));
        }
        return ElevatedButton(
            style: ElevatedButton.styleFrom(primary: Colors.blue),
            onPressed: () => FlutterBlue.instance.startScan(timeout: timeout),
            child: const Text('Start Scan', style: buttonStyle));
      },
    );
  }

  /// Returns the top bar of the scan screen, including the scan button and
  /// device filtering switch.
  Widget _makeTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Filter Results",
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Container(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    alignment: Alignment.centerLeft,
                    child: Switch(
                      onChanged: (_) => _toggleSwitch(),
                      value: _filteringOn,
                      activeColor: Colors.blue,
                      activeTrackColor: Colors.lightBlue,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey,
                    ))
              ],
            ),
            padding: const EdgeInsets.only(left: 8, right: 20),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(flex: 5),
              Expanded(flex: 7, child: _makeScanButton()),
              Container(
                padding: const EdgeInsets.only(left: 8),
                alignment: Alignment.center,
                child: IconButton(
                  iconSize: 30,
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  void _connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
    } on TimeoutException {
      return;
    }

    Connection c = Connection(device, await device.discoverServices(),
        resolveApps: _promptSelectApp);

    // handle connection state changes
    device.state.listen((event) {
      if (event == BluetoothDeviceState.disconnected) {
        _disconnect(device);
      }
    });

    // get either an existing group or a new group entirely
    final ConnectionGroup resultingGroup;
    try {
      // add this connection and let connection model handle group resolution
      resultingGroup = await _connectionModel.add(c);
      await resultingGroup.initialize();

      // check to see if a new view needs to be shown (if new group made)
      if (!_views.values.contains(resultingGroup)) {
        final newView = View();
        _views[newView] = resultingGroup;
        final newTabController = _makeTabController();
        setState(() {
          _tabController = newTabController;
        });

        if (resultingGroup.navigateOnNewConnection) {
          _tabNavigate(newView);
        }
      } else {
        _tabNavigate(_views.keys.singleWhere(
          (view) => _views[view] == resultingGroup,
        ));
      }
    } on Error {
      _disconnect(device);
      return;
    }
  }

  void _tabNavigate(View view) {
    int targetIndex = 1 + _views.keys.toList().indexOf(view);
    targetIndex == -1 ? null : _tabController.animateTo(targetIndex);
  }

  void _disconnect(BluetoothDevice device) async {
    await device.disconnect();
    Connection? target = _connectionModel.connectionOf(device);

    if (target != null) {
      ConnectionGroup? containingGroup = _connectionModel.groupOf(target);
      _connectionModel.remove(target);

      if (containingGroup != null &&
          containingGroup.connections.isEmpty &&
          _views.isNotEmpty) {
        // only set state when a view closes (and that view exists)

        // remove unused view and redraw screen
        // _views.removeWhere(((_, group) => group == containingGroup));
        final newTabController = _makeTabController();
        setState(() {
          _tabController = newTabController;
        });
      }
    }
  }

  /// This should be called when an updated tab controller is needed,
  /// which occurs whenever an app is added or removed from the tabs.
  TabController _makeTabController() {
    // Note: length + 1 below is because the scan screen iself counts as a
    // tab to the tab controller.
    return TabController(length: _views.length + 1, vsync: this);
  }

  Widget _getTab(View connectionView) {
    return FutureBuilder(
      future: connectionView.name,
      builder: (_, AsyncSnapshot<String> snapshot) {
        String toDisplay = "New Connection";
        if (snapshot.hasData) {
          toDisplay = snapshot.data ?? 'No name';
        } else if (snapshot.hasError) {
          toDisplay = 'Error!';
        }
        return Tab(text: toDisplay);
      },
    );
  }

  Widget _makeTabBar() {
    Tab homeTab = const Tab(text: 'Home');

    // home screen tab
    final tabBar = TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(5.0),
        indicatorColor: Colors.white,
        tabs: [homeTab, ...(_views.keys.map(_getTab))]);

    if (_views.isEmpty) {
      return Visibility(
        child: tabBar,
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainSemantics: true,
        maintainState: true,
      );
    }

    return tabBar;
  }

  /// Handles conflicts in app selection by prompting the user to select
  /// from candidate `apps`. Returns `null` if the user does not select an
  /// app.
  Future<App?> _promptSelectApp(List<App> apps) {
    return showDialog<App?>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            "App Selection",
            style: TextStyle(fontSize: 20),
          ),
          // titleTextStyle: const TextStyle(fontSize: 22),
          clipBehavior: Clip.none,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text(
                "Multiple possible applications.\nPlease choose from one of the following.",
                style: TextStyle(fontSize: 18),
              ),
            ),
            ...apps.map(
              (a) => SimpleDialogOption(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
                child: Text(
                  // TODO: make project name instead of class name
                  a.toString().split('.').last,
                  style: const TextStyle(fontSize: 18),
                ),
                onPressed: () => Navigator.pop(context, a),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _makeScanScreenBody() {
    return Column(
      children: [
        Flexible(
          flex: 1,
          child: Container(
            child: Container(
              child: _makeTopBar(context),
              margin: const EdgeInsets.all(8),
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 2.0, color: Color(0xCCCCCCCC)),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DiscoveredDeviceList(
                  filter: _filteringOn,
                  onConnect: (device, _) async {
                    _connect(device);
                  },
                ),
              ),
              const VerticalDivider(
                width: 20,
                thickness: 2,
                indent: 20,
                endIndent: 0,
                color: Color(0xCCCCCCCC),
              ),
              Expanded(
                child: _views.isEmpty
                    ? Center(
                        child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            "Device groups will\nappear here",
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 24),
                          ),
                        ),
                      ))
                    : ListView(
                        children: [
                          ..._views.entries.map((entry) {
                            final connectionGroup = entry.value;
                            final view = entry.key;

                            return ChangeNotifierProvider.value(
                              value: connectionGroup,
                              child: FutureBuilder<String>(
                                  future: view.name,
                                  initialData: "Loading...",
                                  builder: (context, snapshot) {
                                    return Stack(
                                      fit: StackFit.loose,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      children: [
                                        BorderedContainer(
                                          label: snapshot.data,
                                          child: ConnectionGroupList(
                                            onDisconnect: _disconnect,
                                            onOpen: (_) => _tabNavigate(view),
                                          ),
                                        ),
                                        // Align(
                                        //   alignment: Alignment.bottomCenter,
                                        //   child: SizedBox(
                                        //     width: 100,
                                        //     height: 20,
                                        //     child: ElevatedButton(
                                        //       child: Text("Close All"),
                                        //       onPressed: () {
                                        //         for (var c in connectionGroup
                                        //             .connections) {
                                        //           _connectionModel.remove(c);
                                        //         }
                                        //       },
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    );
                                  }),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionModel.connections.isNotEmpty) {
      return Scaffold(
        bottomNavigationBar: Container(
          color: _views.isEmpty
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.blue,
          child: _makeTabBar(),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _makeScanScreenBody(),
            ..._views.entries.map(
              (entry) => ChangeNotifierProvider.value(
                value: entry.value,
                child: entry.key,
              ),
            ),
          ],
        ), // home screen body
      );
    }

    return _makeScanScreenBody();
  }
}

class ConnectionGroupList extends StatelessWidget {
  final Function(BluetoothDevice) onOpen;
  final Function(BluetoothDevice) onDisconnect;

  const ConnectionGroupList(
      {required this.onOpen, required this.onDisconnect, super.key});

  Widget _makeOpenCloseButtons(BluetoothDevice device, BuildContext context) {
    final children = [
      Expanded(
        child: ElevatedButton(
          child: const Text(
            'CLOSE',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(primary: Colors.black),
          onPressed: () => onDisconnect(device),
        ),
      ),
      const SizedBox(
        width: 20,
      ),
      Expanded(
        child: ElevatedButton(
          child: const Text(
            'OPEN',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(primary: Colors.blue),
          onPressed: () => onOpen(device),
        ),
      )
    ];

    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      return ConstrainedBox(
        child: Row(children: children),
        constraints: const BoxConstraints(maxWidth: 200),
      );
    }
    return ConstrainedBox(
      child: Column(
        children: children,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
      constraints: const BoxConstraints(maxWidth: 200),
    );

    // return SizedBox(
    //   width: 200,
    //   child: orientation == Orientation.landscape
    //       ? Row(children: children)
    //       : Column(
    //           children: children,
    //           mainAxisAlignment: MainAxisAlignment.spaceAround,
    //         ),
    // );
  }

  Widget _buildTitle(BluetoothDevice device, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          device.name.isEmpty ? "Unnamed Device" : device.name,
          style: Theme.of(context).textTheme.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionGroup>(
      builder: (context, connectionGroup, child) {
        return ListView(
          shrinkWrap: true,
          children: connectionGroup.connections
              .map(
                (connection) => ListTile(
                  title: _buildTitle(connection.device, context),
                  subtitle: Text(
                    "${connection.device.id}",
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  trailing: _makeOpenCloseButtons(
                    connection.device,
                    context,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
