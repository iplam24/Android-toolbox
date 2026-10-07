import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/web_server_service.dart';

class FileTransferController extends GetxController {
  final webServer = WebServerService.to;

  final RxInt selectedPort = 8080.obs;

  Future<void> toggleServer() async {
    if (webServer.isRunning.value) {
      await webServer.stopServer();
      Get.snackbar('Đã tắt máy chủ', 'Dịch vụ chia sẻ tệp Web đã ngừng hoạt động');
    } else {
      final success = await webServer.startServer(port: selectedPort.value);
      if (success) {
        Get.snackbar(
          'Máy chủ đã sẵn sàng',
          'Truy cập qua trình duyệt máy tính/iPhone tại: ${webServer.serverUrl.value}',
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar('Lỗi', 'Không thể khởi động máy chủ Web nội bộ');
      }
    }
  }

  void copyUrl() {
    if (webServer.serverUrl.value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: webServer.serverUrl.value));
      Get.snackbar('Đã sao chép', 'Đã sao chép đường dẫn máy chủ vào bộ nhớ tạm');
    }
  }
}
