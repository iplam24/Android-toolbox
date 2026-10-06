import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/qr_controller.dart';

class QrView extends GetView<QrController> {
  const QrView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'QR & Barcode Studio',
          subtitle: 'Scan codes & generate custom QR',
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
                  Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scanner'),
                  Tab(icon: Icon(Icons.qr_code_rounded), text: 'Generator'),
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
                onPressed: () => controller.scannerController.toggleTorch(),
              ),
              const SizedBox(width: 24),
              IconButton.filledTonal(
                icon: const Icon(Icons.flip_camera_android_rounded),
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
                  label: const Center(child: Text('Text / URL')),
                  selected: controller.qrType.value == 'text',
                  onSelected: (val) {
                    if (val) controller.qrType.value = 'text';
                  },
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ChoiceChip(
                  label: const Center(child: Text('Wi-Fi QR')),
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
                      labelText: 'Wi-Fi Network Name (SSID)',
                      prefixIcon: Icon(Icons.wifi_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.wifiPassController,
                    decoration: const InputDecoration(
                      labelText: 'Wi-Fi Password',
                      prefixIcon: Icon(Icons.password_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Generate Wi-Fi QR'),
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
                    labelText: 'Text, Website URL, or Message',
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
