class BatteryInfoModel {
  final int level;
  final double temperature;
  final int voltage;
  final String technology;
  final String health;
  final String plugged;
  final int currentNow;
  final int currentAverage;
  final int capacity;
  final int cycleCount;
  final double designCapacityMah;
  final double actualFullCapacityMah;
  final double healthPercent;
  final double wearLevel;

  BatteryInfoModel({
    required this.level,
    required this.temperature,
    required this.voltage,
    required this.technology,
    required this.health,
    required this.plugged,
    required this.currentNow,
    this.currentAverage = 0,
    required this.capacity,
    this.cycleCount = 0,
    this.designCapacityMah = 5000.0,
    this.actualFullCapacityMah = 5000.0,
    this.healthPercent = 100.0,
    this.wearLevel = 0.0,
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
      currentAverage: (map['currentAverage'] as num?)?.toInt() ?? 0,
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      cycleCount: (map['cycleCount'] as num?)?.toInt() ?? 0,
      designCapacityMah: (map['designCapacityMah'] as num?)?.toDouble() ?? 5000.0,
      actualFullCapacityMah: (map['actualFullCapacityMah'] as num?)?.toDouble() ?? 5000.0,
      healthPercent: (map['healthPercent'] as num?)?.toDouble() ?? 100.0,
      wearLevel: (map['wearLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isCharging => plugged != 'Discharging';

  double get currentMa => (currentNow.abs() / 1000.0);

  double get wattage {
    if (currentNow == 0 || voltage == 0) return 0.0;
    final double v = voltage / 1000.0;
    final double a = currentNow.abs() / 1000000.0;
    return v * a;
  }
}
