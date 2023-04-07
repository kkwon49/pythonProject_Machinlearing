import 'dart:ui';

/// Enum class representing the different type of signals currently supported.
enum SignalType {
  temperature,
  ecg,
  ppg,
  eeg,
  erg,
  ph,
  pressure,
  emg,
  acceleration,
  imu,
  other,
}

typedef Uuid = String;

/// Returns a negative value if `sig1` is ordered before `sig2`,
/// a positive value if `sig1` is ordered after `sig2`,
/// or zero if `sig1` and `sig2` are equivalent.
extension _SignalTypeExtension on SignalType {
  static final Map<SignalType, String> _nameMap = {
    SignalType.temperature: "Temperature",
    SignalType.eeg: "EEG",
    SignalType.ecg: "ECG",
    SignalType.erg: "ERG",
    SignalType.ppg: "PPG",
    SignalType.pressure: "Pressure",
    SignalType.ph: "pH",
    SignalType.emg: "EMG",
    SignalType.acceleration: "Acceleration",
    SignalType.imu: "IMU",
    SignalType.other: "Other",
  };

  static String _nameOf(SignalType sig) => _nameMap[sig] ?? "Unnamed";
}

/// `Signal` instances are abstractions of BLE characteristics.
class Signal {
  final SignalType type;
  final Uuid serviceUuid;
  final Uuid charUuid;

  const Signal(this.type, {required this.serviceUuid, required this.charUuid});

  get name => _SignalTypeExtension._nameOf(type);

  static int compare(Signal sig1, Signal sig2) {
    return sig1.name.compareTo(sig2.name);
  }

  @override
  bool operator ==(Object other) =>
      other is Signal &&
      other.runtimeType == runtimeType &&
      other.type == type &&
      other.name == name &&
      other.serviceUuid == serviceUuid &&
      other.charUuid == charUuid;

  @override
  int get hashCode => hashValues(type, name, serviceUuid, charUuid);
}
