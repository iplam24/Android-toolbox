import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/system_tools_service.dart';

class AdbController extends GetxController {
  final systemTools = SystemToolsService.to;

  final RxBool isShizukuInstalled = false.obs;
  final RxList<String> logcatLogs = <String>[].obs;
  final RxBool isLoadingLogs = false.obs;
  final RxString logFilter = ''.obs;

  List<String> get filteredLogs {
    if (logFilter.value.trim().isEmpty) return logcatLogs;
    final q = logFilter.value.toLowerCase();
    return logcatLogs.where((l) => l.toLowerCase().contains(q)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    checkShizuku();
    fetchLogcat();
  }

  Future<void> checkShizuku() async {
    isShizukuInstalled.value = await systemTools.isShizukuInstalled();
  }

  Future<void> fetchLogcat() async {
    isLoadingLogs.value = true;
    try {
      final logs = await systemTools.getSystemLogcat(maxLines: 150);
      logcatLogs.value = logs;
    } finally {
      isLoadingLogs.value = false;
    }
  }

  void openDevSettings() {
    systemTools.openDevSettings();
  }

  void openWirelessDebugging() {
    systemTools.openWirelessDebuggingSettings();
  }

  void copyLogs() {
    if (logcatLogs.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: logcatLogs.join('\n')));
      Get.snackbar('Copied', 'Logcat output copied to clipboard');
    }
  }
}
