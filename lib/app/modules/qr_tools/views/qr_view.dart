import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/qr_controller.dart';

const _qrUsageGuide = UsageGuideData(
  title: 'Quét & Tạo mã QR, Mã vạch',
  description: 'Quét nhanh mọi loại mã QR và mã vạch (Barcode) qua camera, đồng thời hỗ trợ tạo mã QR văn bản, đường dẫn website hoặc mã QR chia sẻ Wi-Fi tiện lợi.',
  steps: [
    'Tab "Quét mã": Hướng camera về phía mã QR hoặc mã vạch. Nhấn nút ⚡ để bật đèn flash trợ sáng khi ở nơi tối, hoặc nút 🔄 để đổi sang camera trước.',
    'Khi quét thành công, máy sẽ rung phản hồi và hiển thị nội dung để bạn Sao chép hoặc Quét tiếp.',
    'Tab "Tạo mã": Chọn kiểu mã "Văn bản / Link" hoặc "Mã QR Wi-Fi".',
    'Tạo mã QR Wi-Fi: Nhập tên Wi-Fi (SSID) và Mật khẩu rồi bấm "Tạo mã QR Wi-Fi". Người khác chỉ cần quét mã là máy sẽ tự động kết nối Wi-Fi mà không cần nhập mật khẩu.',
  ],
  tips: [
    'Mã QR Wi-Fi chuẩn quốc tế, hoạt động mượt mà trên cả Android và iPhone (iOS).',
    'Bạn có thể chụp ảnh màn hình mã QR Wi-Fi vừa tạo để in ra dán trong phòng khách hoặc cửa hàng.',
  ],
);

class QrView extends GetView<QrController> {
  const QrView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Quét & Tạo mã QR',
          subtitle: 'Quét mã vạch & tạo mã QR tùy chỉnh',
          usageGuide: _qrUsageGuide,
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const TabBar(
                indicatorColor: AppColors.qrColor,
                labelColor: AppColors.qrColor,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Quét mã'),
                  Tab(icon: Icon(Icons.qr_code_rounded), text: 'Tạo mã QR'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildScannerTab(context),
                  _buildGeneratorTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller.scannerController,
          onDetect: (capture) => controller.onBarcodeDetected(capture),
        ),
        // Scanner Overlay Reticle
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.qrColor, width: 3),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.qrColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // Tip banner top
        const Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: UsageGuideBanner(guide: _qrUsageGuide),
        ),
        // Controls at bottom
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.flash_on_rounded),
                tooltip: 'Bật/Tắt đèn Flash',
                onPressed: () => controller.scannerController.toggleTorch(),
              ),
              const SizedBox(width: 24),
              IconButton.filledTonal(
                icon: const Icon(Icons.flip_camera_android_rounded),
                tooltip: 'Đổi camera',
                onPressed: () => controller.scannerController.switchCamera(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratorTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Banner Hướng dẫn cách dùng nhanh
          const UsageGuideBanner(guide: _qrUsageGuide),
          const SizedBox(height: 8),

          // QR Code Preview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() => QrImageView(
                      data: controller.qrContent.value.isEmpty ? 'Empty' : controller.qrContent.value,
                      version: QrVersions.auto,
                      size: 200.0,
                    )),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => Text(
                    controller.qrContent.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // QR Type Selector
          Row(
            children: [
              Expanded(
                child: Obx(() => ChoiceChip(
                  label: const Center(child: Text('Văn bản / Link')),
                  selected: controller.qrType.value == 'text',
                  onSelected: (val) {
                    if (val) controller.qrType.value = 'text';
                  },
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ChoiceChip(
                  label: const Center(child: Text('Mã QR Wi-Fi')),
                  selected: controller.qrType.value == 'wifi',
                  onSelected: (val) {
                    if (val) controller.qrType.value = 'wifi';
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inputs according to type
          Obx(() {
            if (controller.qrType.value == 'wifi') {
              return Column(
                children: [
                  TextField(
                    controller: controller.wifiSsidController,
                    decoration: const InputDecoration(
                      labelText: 'Tên mạng Wi-Fi (SSID)',
                      prefixIcon: Icon(Icons.wifi_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.wifiPassController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu Wi-Fi',
                      prefixIcon: Icon(Icons.password_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Tạo mã QR Wi-Fi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.qrColor,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => controller.generateWifiQr(),
                  ),
                ],
              );
            }

            return Column(
              children: [
                TextField(
                  controller: controller.textInputController,
                  maxLines: 3,
                  onChanged: (val) => controller.updateTextQr(val),
                  decoration: const InputDecoration(
                    labelText: 'Nội dung văn bản, đường dẫn website hoặc tin nhắn',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
