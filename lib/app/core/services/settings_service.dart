import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsService extends GetxService {
  final _storage = GetStorage();

  static const _keyThemeMode = 'app_theme_mode';
  static const _keyHaptic = 'pref_haptic';
  static const _keyAutoRefresh = 'pref_auto_refresh';
  static const _keyServerPort = 'pref_server_port';

  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;
  final RxBool hapticEnabled = true.obs;
  final RxBool autoRefreshStats = true.obs;
  final RxInt serverPort = 8080.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    // Theme mode: 0 = system, 1 = light, 2 = dark. Default to dark for cool initial look
    final savedTheme = _storage.read<int>(_keyThemeMode) ?? 2;
    switch (savedTheme) {
      case 0:
        themeMode.value = ThemeMode.system;
        break;
      case 1:
        themeMode.value = ThemeMode.light;
        break;
      default:
        themeMode.value = ThemeMode.dark;
        break;
    }

    hapticEnabled.value = _storage.read<bool>(_keyHaptic) ?? true;
    autoRefreshStats.value = _storage.read<bool>(_keyAutoRefresh) ?? true;
    serverPort.value = _storage.read<int>(_keyServerPort) ?? 8080;
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    int modeIndex = 0;
    if (mode == ThemeMode.light) {
      modeIndex = 1;
    } else if (mode == ThemeMode.dark) {
      modeIndex = 2;
    }
    _storage.write(_keyThemeMode, modeIndex);
    Get.changeThemeMode(mode);
    vibrate();
  }

  void toggleTheme() {
    final currentIsDark = isDarkMode;
    setThemeMode(currentIsDark ? ThemeMode.light : ThemeMode.dark);
  }

  bool get isDarkMode {
    if (themeMode.value == ThemeMode.dark) return true;
    if (themeMode.value == ThemeMode.light) return false;
    return Get.isPlatformDarkMode;
  }

  void setHaptic(bool enabled) {
    hapticEnabled.value = enabled;
    _storage.write(_keyHaptic, enabled);
    if (enabled) vibrate();
  }

  void setAutoRefresh(bool enabled) {
    autoRefreshStats.value = enabled;
    _storage.write(_keyAutoRefresh, enabled);
    vibrate();
  }

  void setServerPort(int port) {
    serverPort.value = port;
    _storage.write(_keyServerPort, port);
    vibrate();
  }

  void vibrate({bool heavy = false}) {
    if (!hapticEnabled.value) return;
    try {
      if (heavy) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }
}
