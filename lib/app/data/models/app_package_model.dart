class AppPackageModel {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final bool isSystemApp;
  final String apkPath;
  final int apkSize;
  final int firstInstallTime;
  final int lastUpdateTime;
  final int targetSdkVersion;
  final int minSdkVersion;
  final String installerPackageName;
  final String installerSource;
  final bool isFromPlayStore;
  final bool isSideloaded;
  final List<String> permissionsGranted;
  final List<String> permissionsDenied;

  AppPackageModel({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.isSystemApp,
    required this.apkPath,
    required this.apkSize,
    required this.firstInstallTime,
    required this.lastUpdateTime,
    required this.targetSdkVersion,
    required this.minSdkVersion,
    this.installerPackageName = '',
    this.installerSource = '',
    this.isFromPlayStore = false,
    this.isSideloaded = false,
    this.permissionsGranted = const [],
    this.permissionsDenied = const [],
  });

  factory AppPackageModel.fromMap(Map<dynamic, dynamic> map) {
    return AppPackageModel(
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? '',
      versionName: map['versionName']?.toString() ?? '',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
      isSystemApp: map['isSystemApp'] == true,
      apkPath: map['apkPath']?.toString() ?? '',
      apkSize: (map['apkSize'] as num?)?.toInt() ?? 0,
      firstInstallTime: (map['firstInstallTime'] as num?)?.toInt() ?? 0,
      lastUpdateTime: (map['lastUpdateTime'] as num?)?.toInt() ?? 0,
      targetSdkVersion: (map['targetSdkVersion'] as num?)?.toInt() ?? 0,
      minSdkVersion: (map['minSdkVersion'] as num?)?.toInt() ?? 0,
      installerPackageName: map['installerPackageName']?.toString() ?? '',
      installerSource: map['installerSource']?.toString() ?? (map['isFromPlayStore'] == true ? 'Google Play Store' : 'Cài ngoài (APK)'),
      isFromPlayStore: map['isFromPlayStore'] == true,
      isSideloaded: map['isSideloaded'] == true,
      permissionsGranted: (map['permissionsGranted'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      permissionsDenied: (map['permissionsDenied'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  String get formattedSize {
    if (apkSize <= 0) return '0 B';
    final double kb = apkSize / 1024;
    final double mb = kb / 1024;
    final double gb = mb / 1024;

    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${kb.toStringAsFixed(0)} KB';
  }
}
