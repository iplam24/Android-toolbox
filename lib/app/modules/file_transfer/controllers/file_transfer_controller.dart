import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/web_server_service.dart';

class FileTransferController extends GetxController {
  final webServer = WebServerService.to;

  final RxInt selectedPort = 8080.obs;


  Future<void> toggleServer() async {
    if (webServer.isRunning.value) {
      await webServer.stopServer();
      Get.snackbar('Server Stopped', 'Local Web Share is now offline');
    } else {
      final success = await webServer.startServer(port: selectedPort.value);
      if (success) {
        Get.snackbar(
          'Web Server Started',
          'Access via browser at ${webServer.serverUrl.value}',
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar('Error', 'Failed to start local web server');
      }
    }
  }

  void copyUrl() {
    if (webServer.serverUrl.value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: webServer.serverUrl.value));
      Get.snackbar('Copied', 'Server URL copied to clipboard');
    }
  }
}
