import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/file_transfer_controller.dart';

const _fileTransferUsageGuide = UsageGuideData(
  title: 'Truyền tệp Web nội bộ (Web Share)',
  description: 'Chia sẻ và nhận tệp tin tốc độ cao giữa điện thoại Android và bất kỳ máy tính PC, laptop hoặc iPhone nào trong cùng mạng Wi-Fi mà hoàn toàn không cần cài đặt phần mềm bên thứ 3 hay cắm dây cáp USB.',
  steps: [
    'Đảm bảo điện thoại và máy tính (hoặc thiết bị nhận) đang kết nối CHUNG một mạng Wi-Fi.',
    'Bật công tắc "MÁY CHỦ HTTP NỘI BỘ" ở phía trên.',
    'Trên máy tính hoặc iPhone, mở trình duyệt (Chrome, Safari, Edge, Cốc Cốc...) và gõ địa chỉ URL hiển thị (hoặc quét mã QR trên màn hình).',
    'Gửi tệp từ máy tính sang điện thoại: Kéo thả tệp tin vào khung tải lên trên trình duyệt web.',
    'Tải tệp từ điện thoại về máy tính: Nhấn nút "Tải về" cạnh tệp bạn muốn lưu trong danh sách tệp.',
  ],
  tips: [
    'Tệp nhận được lưu tự động trong thư mục /sdcard/.../WebShare của máy.',
    'Tốc độ truyền tải qua mạng nội bộ LAN rất nhanh (thường 20-80 MB/s) và hoàn toàn không tốn lưu lượng 4G/Internet.',
    'Khi không sử dụng, hãy gạt tắt công tắc để tiết kiệm pin.',
  ],
);

class FileTransferView extends GetView<FileTransferController> {
  const FileTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Truyền tệp Web nội bộ',
        subtitle: 'Chia sẻ tệp không dây qua trình duyệt Web',
        usageGuide: _fileTransferUsageGuide,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Banner Hướng dẫn cách dùng nhanh
            const UsageGuideBanner(guide: _fileTransferUsageGuide),
            const SizedBox(height: 8),

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
                              const Text('MÁY CHỦ HTTP NỘI BỘ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Obx(() => Text(
                                controller.webServer.isRunning.value ? 'Máy chủ đang hoạt động' : 'Máy chủ đã tắt',
                                style: TextStyle(
                                  fontSize: 16,
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
                            'Bật công tắc máy chủ để bắt đầu chia sẻ và nhận tệp từ mọi máy tính PC, laptop hoặc iPhone trong cùng mạng Wi-Fi.',
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
                            'Mở địa chỉ này trên trình duyệt web máy tính/iPhone để truyền tệp',
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
                          'TỆP TRÊN ĐIỆN THOẠI',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Obx(() => Text(
                          '${controller.webServer.sharedFilesList.length} tệp',
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
                            child: Text('Chưa có tệp nào được tải lên qua Web Share', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.webServer.sharedFilesDetails.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final fileInfo = controller.webServer.sharedFilesDetails[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.insert_drive_file_rounded, color: AppColors.fileTransferColor),
                            title: Text(fileInfo.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(fileInfo.formattedSize, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
