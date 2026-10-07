import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/system_tools_service.dart';

class QrController extends GetxController {
  final systemTools = SystemToolsService.to;

  final MobileScannerController scannerController = MobileScannerController();

  final RxInt selectedTabIndex = 0.obs; // 0 = Scanner, 1 = Generator
  final RxString scannedResult = ''.obs;
  final RxBool isScanning = true.obs;

  // Generator inputs
  final RxString qrType = 'text'.obs; // text, wifi
  final RxString qrContent = 'https://github.com/iplam24/Android-toolbox'.obs;

  final textInputController = TextEditingController(text: 'https://github.com/iplam24/Android-toolbox');
  final wifiSsidController = TextEditingController();
  final wifiPassController = TextEditingController();
  final RxString wifiSecurity = 'WPA'.obs; // WPA, WEP, nopass

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['initialText'] != null) {
      selectedTabIndex.value = 1;
      final text = args['initialText'] as String;
      textInputController.text = text;
      qrContent.value = text;
    }
  }

  @override
  void onClose() {
    scannerController.dispose();
    textInputController.dispose();
    wifiSsidController.dispose();
    wifiPassController.dispose();
    super.onClose();
  }

  void onBarcodeDetected(BarcodeCapture capture) {
    if (!isScanning.value) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        systemTools.vibrate(durationMs: 60);
        isScanning.value = false;
        scannedResult.value = code;
        _showScannedDialog(code);
      }
    }
  }

  void restartScanning() {
    isScanning.value = true;
    scannedResult.value = '';
  }

  void generateWifiQr() {
    final ssid = wifiSsidController.text.trim();
    final pass = wifiPassController.text.trim();
    final sec = wifiSecurity.value;

    if (ssid.isEmpty) {
      Get.snackbar('Lỗi nhập liệu', 'Vui lòng nhập tên mạng Wi-Fi (SSID)');
      return;
    }

    // Wi-Fi QR format: WIFI:S:MySSID;T:WPA;P:MyPassword;;
    final wifiFormat = 'WIFI:S:$ssid;T:$sec;P:$pass;;';
    qrContent.value = wifiFormat;
  }

  void updateTextQr(String text) {
    qrContent.value = text.trim();
  }

  void _showScannedDialog(String result) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('Kết quả quét mã QR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              result,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              restartScanning();
            },
            child: const Text('Quét lại'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result));
              Get.back();
              restartScanning();
              Get.snackbar('Đã sao chép', 'Đã lưu nội dung mã QR vào bộ nhớ tạm');
            },
          ),
        ],
      ),
    ).then((_) => restartScanning());
  }
}
