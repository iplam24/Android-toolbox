class HardwareInfoModel {
  final String brand;
  final String model;
  final String manufacturer;
  final String device;
  final String board;
  final String hardware;
  final String androidVersion;
  final int sdkInt;
  final String securityPatch;
  final List<String> supportedAbis;
  final String socManufacturer;
  final String socModel;
  final int totalRam;
  final int availableRam;
  final bool isLowRam;
  final int totalStorage;
  final int freeStorage;

  HardwareInfoModel({
    required this.brand,
    required this.model,
    required this.manufacturer,
    required this.device,
    required this.board,
    required this.hardware,
    required this.androidVersion,
    required this.sdkInt,
    required this.securityPatch,
    required this.supportedAbis,
    required this.socManufacturer,
    required this.socModel,
    required this.totalRam,
    required this.availableRam,
    required this.isLowRam,
    required this.totalStorage,
    required this.freeStorage,
  });

  factory HardwareInfoModel.fromMap(Map<dynamic, dynamic> map) {
    return HardwareInfoModel(
      brand: map['brand']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      manufacturer: map['manufacturer']?.toString() ?? '',
      device: map['device']?.toString() ?? '',
      board: map['board']?.toString() ?? '',
      hardware: map['hardware']?.toString() ?? '',
      androidVersion: map['androidVersion']?.toString() ?? '',
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
      securityPatch: map['securityPatch']?.toString() ?? '',
      supportedAbis: (map['supportedAbis'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      socManufacturer: map['socManufacturer']?.toString() ?? '',
      socModel: map['socModel']?.toString() ?? '',
      totalRam: (map['totalRam'] as num?)?.toInt() ?? 0,
      availableRam: (map['availableRam'] as num?)?.toInt() ?? 0,
      isLowRam: map['isLowRam'] == true,
      totalStorage: (map['totalStorage'] as num?)?.toInt() ?? 0,
      freeStorage: (map['freeStorage'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedTotalRam => _formatBytes(totalRam);
  String get formattedAvailRam => _formatBytes(availableRam);
  String get formattedTotalStorage => _formatBytes(totalStorage);
  String get formattedFreeStorage => _formatBytes(freeStorage);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 GB';
    final double gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}
