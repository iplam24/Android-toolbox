import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/clipboard_storage_service.dart';
import '../../../core/services/settings_service.dart';

class SettingsController extends GetxController {
  final settingsService = Get.find<SettingsService>();
  final clipboardService = Get.find<ClipboardStorageService>();

  final portController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    portController.text = settingsService.serverPort.value.toString();
  }

  @override
  void onClose() {
    portController.dispose();
    super.onClose();
  }

  void setThemeMode(ThemeMode mode) {
    settingsService.setThemeMode(mode);
  }

  void toggleHaptic(bool value) {
    settingsService.setHaptic(value);
  }

  void toggleAutoRefresh(bool value) {
    settingsService.setAutoRefresh(value);
  }

  void savePort() {
    final port = int.tryParse(portController.text.trim());
    if (port != null && port >= 1024 && port <= 65535) {
      settingsService.setServerPort(port);
      Get.back();
      Get.snackbar(
        'Đã lưu cổng Web Share',
        'Cổng máy chủ được đổi thành $port',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Cổng không hợp lệ',
        'Vui lòng nhập cổng trong khoảng từ 1024 đến 65535',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void clearClipboardHistory() {
    Get.defaultDialog(
      title: 'Xóa lịch sử Clipboard',
      middleText: 'Bạn có chắc chắn muốn xóa toàn bộ bản sao đã lưu trữ không?',
      textConfirm: 'Xác nhận xóa',
      textCancel: 'Hủy',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        clipboardService.clearAll();
        Get.back();
        settingsService.vibrate(heavy: true);
        Get.snackbar(
          'Đã dọn dẹp',
          'Đã xóa sạch toàn bộ lịch sử clipboard.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  void copyGithubUrl() {
    const url = 'https://github.com/iplam24/Android-toolbox';
    Clipboard.setData(const ClipboardData(text: url));
    settingsService.vibrate();
    Get.snackbar(
      'Đã sao chép liên kết GitHub',
      url,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueAccent.withOpacity(0.85),
      colorText: Colors.white,
    );
  }

  void resetToDefaults() {
    Get.defaultDialog(
      title: 'Khôi phục cài đặt gốc',
      middleText: 'Đặt lại toàn bộ cấu hình giao diện và tùy chọn về mặc định ban đầu?',
      textConfirm: 'Đặt lại',
      textCancel: 'Hủy',
      confirmTextColor: Colors.white,
      buttonColor: Colors.orangeAccent,
      onConfirm: () {
        settingsService.setThemeMode(ThemeMode.dark);
        settingsService.setHaptic(true);
        settingsService.setAutoRefresh(true);
        settingsService.setServerPort(8080);
        portController.text = '8080';
        Get.back();
        settingsService.vibrate();
        Get.snackbar(
          'Thành công',
          'Cài đặt đã được khôi phục về mặc định.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }
}
