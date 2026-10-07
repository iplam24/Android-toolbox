import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/file_transfer_controller.dart';

const _fileTransferUsageGuide = UsageGuideData(
  title: 'Truyền tệp Web nội bộ (Web Share)',
  description: 'Chia sẻ và nhận tệp tin tốc độ cao giữa điện thoại Android và bất kỳ máy tính PC, laptop hoặc iPhone nào trong cùng mạng Wi-Fi mà không cần cài thêm phần mềm hay dây cáp.',
  steps: [
    'Đảm bảo điện thoại và máy tính/iPhone kết nối CHUNG mạng Wi-Fi nội bộ.',
    'Bật công tắc "MÁY CHỦ HTTP NỘI BỘ" phía trên.',
    'Trên máy tính, mở trình duyệt (Chrome, Edge, Safari...) truy cập địa chỉ IP hiển thị hoặc quét mã QR.',
    'Gửi tệp từ máy tính sang điện thoại: Kéo thả tệp vào giao diện Web và chọn thư mục lưu (Tải về, Ảnh, Video, Tài liệu...).',
    'Xác nhận lưu tệp trên điện thoại: Nếu bật "Hỏi xác nhận", điện thoại sẽ hiện hộp thoại thông báo tên, dung lượng và cho bạn chọn Đồng ý lưu hay Từ chối tệp đó.',
    'Tải tệp từ điện thoại về máy tính: Bấm nút "Tải về" cạnh từng tệp trên trang web máy tính.',
  ],
  tips: [
    'Bạn có thể bấm vào menu 3 chấm cạnh mỗi tệp để chia sẻ nhanh qua Zalo, Drive, di chuyển thư mục hoặc xóa tệp.',
    'Tốc độ truyền tải qua mạng Wi-Fi nội bộ rất nhanh (20-80 MB/s) và không tốn dung lượng 4G.',
    'Khi không sử dụng, hãy tắt máy chủ để tối ưu thời lượng pin.',
  ],
);

class FileTransferView extends GetView<FileTransferController> {
  const FileTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Truyền tệp Web nội bộ',
        subtitle: 'Chia sẻ tệp không dây & xác nhận nhận tệp',
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
            const SizedBox(height: 20),

            // Receive & Storage Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: AppColors.fileTransferColor),
                        SizedBox(width: 8),
                        Text(
                          'CẤU HÌNH NHẬN & LƯU TỆP',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hỏi xác nhận trước khi lưu tệp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Hiện thông báo hỏi bạn có nhận tệp không và cho phép chọn thư mục lưu', style: TextStyle(fontSize: 12)),
                      value: controller.webServer.askBeforeSave.value,
                      activeColor: AppColors.fileTransferColor,
                      onChanged: (val) => controller.webServer.askBeforeSave.value = val,
                    )),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Thư mục lưu mặc định:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Obx(() => DropdownButtonFormField<String>(
                      value: controller.webServer.defaultTargetFolder.value,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'download_webshare',
                          child: Text('📁 Thư mục WebShare (Download/WebShare)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'download',
                          child: Text('📥 Thư mục Tải về (/sdcard/Download)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'pictures',
                          child: Text('🖼️ Thư mục Ảnh (/sdcard/Pictures)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'documents',
                          child: Text('📄 Thư mục Tài liệu (/sdcard/Documents)', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          controller.webServer.defaultTargetFolder.value = val;
                          controller.webServer.resolveFolder(val).then((_) => controller.webServer.refreshFilesList());
                        }
                      },
                    )),
                  ],
                ),
              ),
            ),
            // Upload from Phone to PC Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.fileTransferColor.withOpacity(0.35)),
              ),
              color: AppColors.fileTransferColor.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.fileTransferColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_upload_rounded, color: AppColors.fileTransferColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHIA SẺ SANG MÁY TÍNH',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.fileTransferColor),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Chọn ảnh, video, tài liệu từ máy để máy tính tải về',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.isPickingFiles.value
                            ? null
                            : () => controller.pickAndShareFilesFromPhone(),
                        icon: controller.isPickingFiles.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add_photo_alternate_rounded, size: 20),
                        label: Text(
                          controller.isPickingFiles.value ? 'ĐANG CHUẨN BỊ TỆP...' : 'CHỌN ẢNH & TỆP TỪ ĐIỆN THOẠI',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.fileTransferColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                        Row(
                          children: [
                            Obx(() => Text(
                              '${controller.webServer.sharedFilesDetails.length} tệp',
                              style: const TextStyle(fontSize: 12, color: AppColors.fileTransferColor, fontWeight: FontWeight.bold),
                            )),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.fileTransferColor),
                              tooltip: 'Thêm tệp từ máy',
                              onPressed: () => controller.pickAndShareFilesFromPhone(),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              tooltip: 'Làm mới danh sách',
                              onPressed: () => controller.webServer.refreshFilesList(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.webServer.sharedFilesDetails.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Chưa có tệp nào trong thư mục WebShare', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
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
                          IconData iconData = Icons.insert_drive_file_rounded;
                          Color iconColor = AppColors.fileTransferColor;

                          switch (fileInfo.category) {
                            case 'image':
                              iconData = Icons.image_rounded;
                              iconColor = Colors.purpleAccent;
                              break;
                            case 'video':
                              iconData = Icons.video_file_rounded;
                              iconColor = Colors.redAccent;
                              break;
                            case 'audio':
                              iconData = Icons.audio_file_rounded;
                              iconColor = Colors.amberAccent;
                              break;
                            case 'doc':
                              iconData = Icons.description_rounded;
                              iconColor = Colors.blueAccent;
                              break;
                            case 'archive':
                              iconData = Icons.archive_rounded;
                              iconColor = Colors.orangeAccent;
                              break;
                          }

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(iconData, color: iconColor, size: 22),
                            ),
                            title: Text(fileInfo.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(fileInfo.formattedSize, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onSelected: (val) {
                                switch (val) {
                                  case 'share':
                                    controller.shareFile(fileInfo);
                                    break;
                                  case 'move':
                                    controller.showMoveFileDialog(fileInfo);
                                    break;
                                  case 'delete':
                                    controller.deleteFile(fileInfo);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share_rounded, size: 18, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Chia sẻ tệp'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'move',
                                  child: Row(
                                    children: [
                                      Icon(Icons.drive_file_move_rounded, size: 18, color: Colors.amber),
                                      SizedBox(width: 8),
                                      Text('Lưu sang thư mục khác'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Xóa tệp'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
