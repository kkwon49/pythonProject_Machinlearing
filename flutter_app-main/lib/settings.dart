import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController controller = TextEditingController();
  late SharedPreferences? prefs;
  final ValueNotifier<int?> notifier = ValueNotifier<int?>(null);
  late final Timer resetTimer;

  void _initializePreferences() async {
    prefs = null;
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();

    _initializePreferences();
    resetTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (prefs != null) {
          notifier.value = prefs!.getInt('patientNumber');
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    resetTimer.cancel();
    super.dispose();
  }

  /// Return `true` if this string respresents an integer and `false` otherwise.
  bool _checkInteger(String str) {
    return !(int.tryParse(str) == null);
  }

  Future<void> _updatePreferences(String key, dynamic value) async {
    var prefs = await SharedPreferences.getInstance();
    switch (value.runtimeType) {
      case (int):
        await prefs.setInt(key, value);
        break;
      case (String):
        await prefs.setString(key, value);
        break;
      case (double):
        await prefs.setString(key, value);
        break;
      case (bool):
        await prefs.setBool(key, value);
        break;
      case (List<String>):
        await prefs.setStringList(key, value);
        break;
      default:
        throw Exception();
    }
  }

  FloatingActionButton _makeSaveButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.check),
      onPressed: () {
        Text text = const Text("");
        showDialog(
          context: context,
          builder: (context) {
            if (!_checkInteger(controller.text)) {
              text = const Text("Please enter a numeric value.");
            } else {
              String numericString = controller.text;
              _updatePreferences('patientNumber', int.parse(numericString));
              text = Text("Patient number set as $numericString.");
            }

            return AlertDialog(
              title: const Text("Patient Reassignment"),
              content: SingleChildScrollView(child: text),
            );
          },
        );
      },
    );
  }

  Widget _makeSubtext() {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, _) {
        String text = "";
        if (value == null) {
          text = "None set";
        } else {
          text = "Current: ${value.toString()}";
        }
        return Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),
      floatingActionButton: _makeSaveButton(context),
      body: Container(
        padding: const EdgeInsets.all(30),
        child: Align(
          alignment: Alignment.topCenter,
          child: Row(
            children: [
              Flexible(
                flex: 1,
                child: Column(
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: TextField(
                              controller: controller,
                              obscureText: false,
                              decoration: const InputDecoration(
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(),
                                labelText: 'Patient number',
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _makeSubtext(),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: TextButton(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              content: const Text(
                                                  "Are you sure you want to clear this setting?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    prefs?.remove(
                                                        'patientNumber');
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text(
                                                    "Confirm",
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                )
                                              ],
                                            );
                                          });
                                    },
                                    child: const Text(
                                      'Reset',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    )),
                              )
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3)
            ],
          ),
        ),
      ),
    );
  }
}
