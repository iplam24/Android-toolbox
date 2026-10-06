import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/file_transfer_controller.dart';

class FileTransferView extends GetView<FileTransferController> {
  const FileTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Local Web Share',
        subtitle: 'Browser-to-Phone wireless file transfer',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Server Switch Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.fileTransferColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.wifi_channel_rounded, color: AppColors.fileTransferColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LOCAL HTTP SERVER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Obx(() => Text(
                                controller.webServer.isRunning.value ? 'Server Running' : 'Server Offline',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: controller.webServer.isRunning.value ? AppColors.success : Colors.grey,
                                ),
                              )),
                            ],
                          ),
                        ),
                        Obx(() => Switch(
                          value: controller.webServer.isRunning.value,
                          activeColor: AppColors.fileTransferColor,
                          onChanged: (_) => controller.toggleServer(),
                        )),
                      ],
                    ),
                    Obx(() {
                      if (!controller.webServer.isRunning.value) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Turn on the server to share and receive files from any PC or phone on the same Wi-Fi without installing apps.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.4),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          // QR Code for easy browser scanning
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: controller.webServer.serverUrl.value,
                              version: QrVersions.auto,
                              size: 160.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => controller.copyUrl(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.fileTransferColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.fileTransferColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    controller.webServer.serverUrl.value,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.fileTransferColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.copy_rounded, size: 16, color: AppColors.fileTransferColor),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Open this URL in any browser on PC/iPhone to transfer files',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Files in Transfer Folder
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RECEIVED FILES',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Obx(() => Text(
                          '${controller.webServer.sharedFilesList.length} files',
                          style: const TextStyle(fontSize: 12, color: AppColors.fileTransferColor, fontWeight: FontWeight.bold),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.webServer.sharedFilesList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text('No files received yet via web share', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.webServer.sharedFilesList.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final fileName = controller.webServer.sharedFilesList[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.insert_drive_file_rounded, color: AppColors.fileTransferColor),
                            title: Text(fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
