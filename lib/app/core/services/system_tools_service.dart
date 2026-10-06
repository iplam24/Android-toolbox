import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/app_package_model.dart';
import '../../data/models/battery_info_model.dart';
import '../../data/models/hardware_info_model.dart';
import '../../data/models/privacy_audit_model.dart';

class SystemToolsService extends GetxService {
  static SystemToolsService get to => Get.find();

  static const MethodChannel _channel = MethodChannel('com.toolbox.android/system_tools');

  // APK Manager
  Future<List<AppPackageModel>> getInstalledPackages({bool includeSystem = false}) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getInstalledPackages', {
        'includeSystem': includeSystem,
      });
      if (result == null) return [];
      return result.map((e) => AppPackageModel.fromMap(Map<dynamic, dynamic>.from(e))).toList();
    } on PlatformException catch (e) {
      print('Error getting packages: ${e.message}');
      return [];
    }
  }

  Future<String?> getAppIcon(String packageName) async {
    try {
      final String? base64Icon = await _channel.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });
      return base64Icon;
    } catch (e) {
      return null;
    }
  }

  Future<AppPackageModel?> getAppDetails(String packageName) async {
    try {
      final Map<dynamic, dynamic>? map = await _channel.invokeMethod('getAppDetails', {
        'packageName': packageName,
      });
      if (map == null) return null;
      return AppPackageModel.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<String?> extractApk(String packageName) async {
    try {
      final String? path = await _channel.invokeMethod('extractApk', {
        'packageName': packageName,
      });
      return path;
    } catch (e) {
      print('Error extracting APK: $e');
      return null;
    }
  }

  Future<bool> openApp(String packageName) async {
    try {
      final bool? res = await _channel.invokeMethod('openApp', {'packageName': packageName});
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> openAppSettings(String packageName) async {
    try {
      final bool? res = await _channel.invokeMethod('openAppSettings', {'packageName': packageName});
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uninstallApp(String packageName) async {
    try {
      final bool? res = await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  // Battery Monitor
  Future<BatteryInfoModel?> getAdvancedBatteryInfo() async {
    try {
      final Map<dynamic, dynamic>? map = await _channel.invokeMethod('getAdvancedBatteryInfo');
      if (map == null) return null;
      return BatteryInfoModel.fromMap(map);
    } catch (e) {
      print('Error getting battery info: $e');
      return null;
    }
  }

  // Hardware / Device Info
  Future<HardwareInfoModel?> getHardwareDeviceInfo() async {
    try {
      final Map<dynamic, dynamic>? map = await _channel.invokeMethod('getHardwareDeviceInfo');
      if (map == null) return null;
      return HardwareInfoModel.fromMap(map);
    } catch (e) {
      print('Error getting hardware info: $e');
      return null;
    }
  }

  // Privacy & Permissions
  Future<List<PrivacyAuditModel>> getDangerousPermissionsAudit() async {
    try {
      final List<dynamic>? list = await _channel.invokeMethod('getDangerousPermissionsAudit');
      if (list == null) return [];
      return list.map((e) => PrivacyAuditModel.fromMap(Map<dynamic, dynamic>.from(e))).toList();
    } catch (e) {
      print('Error getting privacy audit: $e');
      return [];
    }
  }

  // Developer / ADB Tools
  Future<bool> openDevSettings() async {
    try {
      final bool? res = await _channel.invokeMethod('openDevSettings');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> openWirelessDebuggingSettings() async {
    try {
      final bool? res = await _channel.invokeMethod('openWirelessDebuggingSettings');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isShizukuInstalled() async {
    try {
      final bool? res = await _channel.invokeMethod('isShizukuInstalled');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getSystemLogcat({int maxLines = 100}) async {
    try {
      final List<dynamic>? list = await _channel.invokeMethod('getSystemLogcat', {
        'maxLines': maxLines,
      });
      if (list == null) return [];
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return ['Error reading logcat: $e'];
    }
  }

  Future<void> vibrate({int durationMs = 100}) async {
    try {
      await _channel.invokeMethod('vibrateDevice', {'durationMs': durationMs});
    } catch (_) {}
  }
}
