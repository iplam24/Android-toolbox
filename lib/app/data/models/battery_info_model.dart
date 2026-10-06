class BatteryInfoModel {
  final int level;
  final double temperature;
  final int voltage;
  final String technology;
  final String health;
  final String plugged;
  final int currentNow;
  final int capacity;

  BatteryInfoModel({
    required this.level,
    required this.temperature,
    required this.voltage,
    required this.technology,
    required this.health,
    required this.plugged,
    required this.currentNow,
    required this.capacity,
  });

  factory BatteryInfoModel.fromMap(Map<dynamic, dynamic> map) {
    return BatteryInfoModel(
      level: (map['level'] as num?)?.toInt() ?? 0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      voltage: (map['voltage'] as num?)?.toInt() ?? 0,
      technology: map['technology']?.toString() ?? 'Li-ion',
      health: map['health']?.toString() ?? 'Good',
      plugged: map['plugged']?.toString() ?? 'Discharging',
      currentNow: (map['currentNow'] as num?)?.toInt() ?? 0,
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isCharging => plugged != 'Discharging';

  double get wattage {
    // Current is usually in microamperes (uA), voltage in millivolts (mV)
    // Power (W) = V * I = (mV / 1000) * (abs(uA) / 1000000)
    if (currentNow == 0 || voltage == 0) return 0.0;
    final double v = voltage / 1000.0;
    final double a = currentNow.abs() / 1000000.0;
    return v * a;
  }
}
