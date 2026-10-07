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

  // Private DNS Settings
  Future<bool> openPrivateDnsSettings() async {
    try {
      final bool? res = await _channel.invokeMethod('openPrivateDnsSettings');
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
      return ['Lỗi đọc logcat: $e'];
    }
  }

  Future<void> vibrate({int durationMs = 100}) async {
    try {
      await _channel.invokeMethod('vibrateDevice', {'durationMs': durationMs});
    } catch (_) {}
  }

  Future<bool> scanMediaFile(String filePath) async {
    try {
      final bool? res = await _channel.invokeMethod('scanMediaFile', {'path': filePath});
      return res ?? false;
    } catch (e) {
      print('Error scanning media file: $e');
      return false;
    }
  }

  Future<bool> openAllFilesAccessSettings() async {
    try {
      final bool? res = await _channel.invokeMethod('openAllFilesAccessSettings');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  // --- Hardware Tests (Barometer, Tone, Mic) ---
  Future<bool> hasBarometerSensor() async {
    try {
      final bool? res = await _channel.invokeMethod('hasBarometerSensor');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<double> getBarometerPressure() async {
    try {
      final double? p = await _channel.invokeMethod('getBarometerPressure');
      return p ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> playTone({double frequency = 165.0, int durationMs = 10000, String channel = 'both'}) async {
    try {
      await _channel.invokeMethod('playTone', {
        'frequency': frequency,
        'durationMs': durationMs,
        'channel': channel,
      });
    } catch (_) {}
  }

  Future<void> stopTone() async {
    try {
      await _channel.invokeMethod('stopTone');
    } catch (_) {}
  }

  Future<String?> startRecordingMic() async {
    try {
      final String? path = await _channel.invokeMethod('startRecordingMic');
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> stopRecordingMic() async {
    try {
      final String? path = await _channel.invokeMethod('stopRecordingMic');
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<int> getMaxMicAmplitude() async {
    try {
      final int? amp = await _channel.invokeMethod('getMaxMicAmplitude');
      return amp ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> playRecordedMic() async {
    try {
      final bool? res = await _channel.invokeMethod('playRecordedMic');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
