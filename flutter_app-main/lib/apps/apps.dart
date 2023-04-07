// import 'package:fl_new/apps/devices/choa_patch.dart';
import 'package:fl_new/apps/app_data.dart';
import 'package:fl_new/apps/projects/ear_ppg.dart';
import 'package:fl_new/apps/projects/erg_snapshot.dart';
import 'package:fl_new/apps/projects/ethiopia_project.dart';
import 'package:fl_new/apps/projects/fdc_pressure_sensor.dart';
import 'package:fl_new/apps/projects/flex_tech.dart';
import 'package:fl_new/apps/projects/led_driver.dart';
import 'package:fl_new/apps/projects/old_choa_patch.dart';
import 'package:fl_new/apps/projects/ppg_scg.dart';
import 'package:fl_new/apps/projects/pressure_sensor.dart';
import 'package:fl_new/apps/projects/smart_mask.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/gen/flutterblue.pb.dart';

import 'projects/nrf_matty.dart';
import 'projects/choa_patch.dart';
import 'package:fl_new/connections/connections.dart';
import 'projects/postpartum_monitor.dart';
import 'projects/ppg_scg.dart';

import 'device.dart';
export 'device.dart' show Device;
export 'app_data.dart' show AppData;

export 'projects/postpartum_monitor.dart' show PostpartumMonitor;
export 'projects/flex_tech.dart' show FlexTech;
export 'projects/nrf_matty.dart' show NRFMatty;
export 'projects/smart_mask.dart' show SmartMask;
export 'projects/ph_temp.dart' show PhTemp;
export 'projects/erg_snapshot.dart' show ERGSnapshot;
export 'projects/ppg_scg.dart' show PpgScg;
export 'projects/ear_ppg.dart' show EarPPG;
export 'projects/old_choa_patch.dart' show PpgChoaPatch;

// It seems we need to explicitly list the apps types (i.e. the
// below enum classes) and their static members separately - there doesn't
// appear to be a mechanism in Dart for referencing static members through (or
// otherwise specify constraints on) Type instances,
// which for example would be possible if classes were first class citizens
// like functions and objects.
//
// See https://github.com/dart-lang/language/issues/356 and
// https://github.com/dart-lang/sdk/issues/10667#issuecomment-108368913 for
// related community discussions.
//
// For now, we encapsulate app types and their associated static members
// in App enum instances.

enum App {
  postpartumMonitor(PostpartumMonitor, PostpartumMonitor.devices),

  choaPatch(ChoaPatch, ChoaPatch.devices),

  smartMask(SmartMask, SmartMask.devices),

  ppgChoaPatch(PpgChoaPatch, PpgChoaPatch.devices),

  flexTech(FlexTech, FlexTech.devices),

  earPPG(EarPPG, EarPPG.devices),

  ledDriver(LEDDriver, LEDDriver.devices),

  ethiopiaProject(EthiopiaProject, EthiopiaProject.devices),

  irasPressureSensor(FdcPressureSensor, FdcPressureSensor.devices);

  final Type type;
  final List<Device> devices;

  const App(this.type, this.devices);
}

abstract class AbstractApp extends StatefulWidget {
  final AppData appData;
  String get name;
  bool get navigateOnNewConnection;

  const AbstractApp(this.appData, {super.key});
}
