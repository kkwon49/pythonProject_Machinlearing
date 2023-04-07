import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:stream_transform/stream_transform.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Center(child: FlutterLogo(size: 100)),
            const Icon(
              Icons.bluetooth_disabled,
              size: 20.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              maxLines: 2,
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Connected Device Tiles:

Widget _buildTitle(BluetoothDevice device, BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(device.name.isEmpty ? "Unnamed Device" : device.name,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge),
      // Text(
      //   device.id.toString(),
      //   style: Theme.of(context).textTheme.caption,
      // )
    ],
  );
}

class _ConnectedDeviceTile extends StatelessWidget {
  final Function(BluetoothDevice, BuildContext) onOpen;
  final Function(BluetoothDevice, BuildContext) onDisconnect;
  final BluetoothDevice device;

  const _ConnectedDeviceTile(
      {required this.device,
      required this.onOpen,
      required this.onDisconnect,
      Key? key})
      : super(key: key);

  Widget _makeOpenCloseButtons(BuildContext context) {
    return StreamBuilder<BluetoothDeviceState>(
        stream: device.state,
        initialData: BluetoothDeviceState.disconnected,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("ERROR: " + snapshot.error.toString());
          }
          if (snapshot.data == BluetoothDeviceState.connecting) {
            return const CircularProgressIndicator();
          } else {
            return SizedBox(
              width: 200,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(primary: Colors.black),
                      onPressed: () => onDisconnect(device, context),
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
                      onPressed: () => onOpen(device, context),
                    ),
                  )
                ],
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: _buildTitle(device, context),
      subtitle:
          Text("${device.id}", style: Theme.of(context).textTheme.labelMedium),
      trailing: _makeOpenCloseButtons(context),
    );
  }
}

class ConnectedDeviceList extends StatelessWidget {
  /// The device widget to build when opening the device for viewing.
  final dynamic Function(BluetoothDevice, BuildContext) onOpenDevice;

  /// Callback for handling disconnecting from this device
  final Function(BluetoothDevice, BuildContext) onDisconnect;

  final List<BluetoothDevice> connectedDevices;

  const ConnectedDeviceList(this.connectedDevices,
      {required this.onOpenDevice, required this.onDisconnect, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: ListTile.divideTiles(
          context: context,
          tiles: connectedDevices.map(
            (device) => _ConnectedDeviceTile(
              device: device,
              onOpen: onOpenDevice,
              onDisconnect: onDisconnect,
            ),
          )).toList(),
    );
  }
}

class _DiscoveredDeviceTile extends StatefulWidget {
  final ScanResult result;
  final Function(BluetoothDevice, BuildContext) onConnect;

  const _DiscoveredDeviceTile(
      {required this.result, required this.onConnect, Key? key})
      : super(key: key);
  @override
  State<_DiscoveredDeviceTile> createState() => _DiscoveredDeviceTileState();
}

class _DiscoveredDeviceTileState extends State<_DiscoveredDeviceTile> {
  late Widget _trailing;
  Timer? _timeoutTimer;

  Widget _resetTrailing() {
    return ElevatedButton(
        child: const Text('CONNECT',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(primary: Colors.black),
        onPressed: () {
          widget.onConnect(widget.result.device, context);
          setState(() {
            _timeoutTimer = Timer(const Duration(seconds: 10), _runTimeout);
            _trailing = Container(
              child: const CircularProgressIndicator(),
              padding: const EdgeInsets.only(right: 26),
            );
          });
        });
  }

  void _runTimeout() {
    _timeoutTimer?.cancel();
    setState(() {
      _trailing = _resetTrailing();
    });
  }

  @override
  void initState() {
    super.initState();
    _trailing = _resetTrailing();
  }

  @override
  void dispose() {
    if (_timeoutTimer?.isActive ?? false) {
      _timeoutTimer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
        title: _buildTitle(widget.result.device, context),
        trailing: _trailing,
        subtitle: Text(
          "${widget.result.device.id}",
          style: Theme.of(context).textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text("RSSI: ${widget.result.rssi}db"),
          ),
        ]);
  }
}

class DiscoveredDeviceList extends StatefulWidget {
  final Function(BluetoothDevice, BuildContext) onConnect;
  final bool? filter;

  const DiscoveredDeviceList({required this.onConnect, bool? filter, Key? key})
      : filter = filter ?? true,
        super(key: key);

  @override
  State<DiscoveredDeviceList> createState() => DiscoveredDeviceListState();
}

class DiscoveredDeviceListState extends State<DiscoveredDeviceList> {
  List<ScanResult> _mostRecentScanResults = [];
  final StreamController<List<ScanResult>> _controller =
      StreamController.broadcast();
  late final Timer _filterTimer;
  @override
  initState() {
    super.initState();

    // _controller sends the most recent scan results periodically to rebuild
    // this widget when a scan is not running. This is useful to update the
    // displayed connectable device list as devices are connected and
    // disconnected without having to rescan via FLutterBlue.
    _filterTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_controller.isClosed) {
        try {
          _controller.add(await _filterRecent());
          // ignore: empty_catches
        } on StateError {}
      }
    });
  }

  @override
  dispose() {
    _filterTimer.cancel();
    _controller.close();
    super.dispose();
  }

  Future<List<ScanResult>> _filterRecent() async {
    // get already connected devices
    var connectedDevices = await FlutterBlue.instance.connectedDevices;

    // parse json for permitted devices
    final String response =
        await rootBundle.loadString('assets/permitted_apps.json');
    var permitted = List<String>.from(json.decode(response).toList());

    if (widget.filter!) {
      // return those that are permitted and not already connected
      return _mostRecentScanResults
          .where((scanResult) =>
              permitted.contains(scanResult.device.name) &&
              !connectedDevices
                  .any((device) => device.id == scanResult.device.id))
          .toList();
    }
    // return those not already connected and with names
    return _mostRecentScanResults
        .where((scanResult) =>
            scanResult.device.name.isNotEmpty &&
            !connectedDevices
                .any((device) => device.id == scanResult.device.id))
        .toList();
  }

  Iterable<Widget> _makeDiscoveredTiles(List<ScanResult> scanResults) {
    scanResults.sort((a, b) => b.device.name.compareTo(a.device.name));
    return scanResults.map(
      (scanResult) => _DiscoveredDeviceTile(
          result: scanResult, onConnect: widget.onConnect),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScanResult>>(
      // rebuild whenever _controller or FlutterBlue send data
      stream: FlutterBlue.instance.scanResults.merge(_controller.stream),
      initialData: const <ScanResult>[],
      builder: (c, AsyncSnapshot<List<ScanResult>> snapshot) {
        _mostRecentScanResults = snapshot.data!;
        return FutureBuilder(
          future: _filterRecent(),
          builder: (context, AsyncSnapshot<List<ScanResult>> snapshot) {
            if (!snapshot.hasData || snapshot.hasError) {
              return Column(
                children: const [],
              );
            } else {
              List<ScanResult> data = snapshot.data!;
              return ListView(
                shrinkWrap: true,
                children: ListTile.divideTiles(
                  color: Theme.of(context).primaryColorLight,
                  context: context,
                  tiles: _makeDiscoveredTiles(data),
                ).toList(),
              );
            }
          },
        );
      },
    );
  }
}

class BluetoothDisabledScreen extends StatelessWidget {
  const BluetoothDisabledScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Center(
          child: Icon(
            Icons.error,
            size: 200,
            color: Colors.red,
          ),
        ),
        Text(
          "Unable to get Bluetooth adapter.",
          style: TextStyle(fontSize: 30),
        ),
        Text(
          "Please check the app's permissions and try again.",
          style: TextStyle(fontSize: 30),
        )
      ],
    );
  }
}

class NullAppScreen extends StatelessWidget {
  const NullAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.bottomCenter,
            child: const Icon(
              Icons.warning,
              size: 20,
            ),
          ),
        ),
        const Expanded(
          child: Text(
            "No corresponding app.",
            style: TextStyle(fontSize: 28),
          ),
        )
      ],
    );
  }
}

class BorderedContainer extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final String? label;
  final TextStyle? labelStyle;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  BorderedContainer.merge(
    BorderedContainer existing, {
    Widget? child,
    Color? borderColor,
    String? label,
    TextStyle? labelStyle,
    double? borderWidth,
    EdgeInsetsGeometry? padding,
    Key? key,
  })  : child = child ?? existing.child,
        borderColor = borderColor ?? existing.borderColor,
        label = label ?? existing.label,
        labelStyle = labelStyle ?? existing.labelStyle,
        borderWidth = borderWidth ?? existing.borderWidth,
        padding = padding ?? existing.padding,
        super(key: key);

  const BorderedContainer(
      {required this.child,
      this.label,
      this.borderWidth = 2.0,
      this.labelStyle,
      this.borderColor,
      this.padding = const EdgeInsets.all(12),
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Container(
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).primaryColorLight,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(15)),
        child: Center(child: child),
      );
    }
    return Container(
      padding: padding,
      alignment: Alignment.center,
      child: InputDecorator(
        decoration: InputDecoration(
          enabled: false,
          labelText: label,
          labelStyle: labelStyle ??
              Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 18),
          disabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColorLight,
              width: borderWidth,
            ),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class CloudError extends StatelessWidget {
  final double size;
  const CloudError({this.size = 100, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.wb_cloudy_outlined,
          size: size,
        ),
        Icon(
          Icons.error,
          size: 0.35 * size,
          color: Colors.red,
        ),
      ],
    );
  }
}
