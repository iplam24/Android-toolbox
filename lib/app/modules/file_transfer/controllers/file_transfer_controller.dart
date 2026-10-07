import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/web_server_service.dart';

class FileTransferController extends GetxController {
  final webServer = WebServerService.to;

  final RxInt selectedPort = 8080.obs;

  @override
  void onInit() {
    super.onInit();
    // Auto listen to incoming files to prompt user on phone
    ever(webServer.activePrompt, (IncomingFilePrompt? prompt) {
      if (prompt != null) {
        _showIncomingPromptDialog(prompt);
      }
    });
  }

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

  void _showIncomingPromptDialog(IncomingFilePrompt prompt) {
    final isImage = RegExp(r'\.(jpe?g|png|gif|webp|heic|bmp)$', caseSensitive: false).hasMatch(prompt.fileName);
    String selectedDest = isImage ? 'pictures' : prompt.requestedFolder;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isImage ? Colors.purple.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isImage ? Icons.image_rounded : Icons.cloud_download_rounded,
                color: isImage ? Colors.purple : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isImage ? 'Nhận hình ảnh mới' : 'Yêu cầu nhận tệp mới',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.height * 0.65),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isImage && File(prompt.tempFilePath).existsSync()) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.file(
                            File(prompt.tempFilePath),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const SizedBox(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      isImage
                          ? 'Máy tính vừa gửi một ảnh sang điện thoại:'
                          : 'Thiết bị từ trình duyệt Web vừa gửi một tệp sang máy bạn:',
                      style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isImage ? Icons.photo_rounded : Icons.insert_drive_file_rounded,
                                size: 20,
                                color: isImage ? Colors.purple : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  prompt.fileName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dung lượng: ${prompt.formattedSize} • Từ: ${prompt.clientIp}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Vị trí lưu trên điện thoại:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedDest,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pictures',
                          child: Text('🖼️ Thư viện Ảnh & Album (/sdcard/Pictures)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'download_webshare',
                          child: Text('📁 Thư mục WebShare (Download/WebShare)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'downloads',
                          child: Text('📥 Thư mục Tải về (/sdcard/Download)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'movies',
                          child: Text('🎬 Video & Phim (/sdcard/Movies)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'music',
                          child: Text('🎵 Âm nhạc (/sdcard/Music)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'documents',
                          child: Text('📄 Tài liệu (/sdcard/Documents)', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedDest = val;
                          });
                        }
                      },
                    ),
                    if (isImage) ...[
                      const SizedBox(height: 8),
                      Text(
                        '✨ Ảnh lưu sẽ được tự động quét vào Thư viện & Bộ sưu tập của máy ngay lập tức.',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              webServer.answerIncomingFilePrompt(prompt, false);
            },
            child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              webServer.answerIncomingFilePrompt(prompt, true, targetFolderKey: selectedDest);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('LƯU VÀO MÁY'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> shareFile(WebShareFileInfo file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: file.name);
    } catch (e) {
      Get.snackbar('Lỗi chia sẻ', 'Không thể chia sẻ tệp: $e');
    }
  }

  Future<void> deleteFile(WebShareFileInfo file) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa tệp'),
        content: Text('Bạn có chắc chắn muốn xóa "${file.name}" khỏi điện thoại?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await webServer.deleteFile(file.name);
      if (ok) {
        Get.snackbar('Đã xóa', 'Đã xóa "${file.name}"');
      } else {
        Get.snackbar('Lỗi', 'Không thể xóa tệp');
      }
    }
  }

  void showMoveFileDialog(WebShareFileInfo file) {
    String dest = 'downloads';
    Get.dialog(
      AlertDialog(
        title: const Text('Di chuyển / Lưu sang thư mục khác'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tệp: ${file.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 14),
            const Text('Chọn thư mục chuyển tới:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: dest,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'downloads', child: Text('📥 Thư mục Tải về (Download)', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'pictures', child: Text('🖼️ Thư mục Ảnh (Pictures)', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'movies', child: Text('🎬 Video & Phim (Movies)', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'music', child: Text('🎵 Âm nhạc (Music)', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'documents', child: Text('📄 Tài liệu (Documents)', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) dest = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final ok = await webServer.moveFile(file.name, dest);
              if (ok) {
                Get.snackbar('Thành công', 'Đã chuyển tệp sang thư mục mới');
              } else {
                Get.snackbar('Lỗi', 'Không thể di chuyển tệp');
              }
            },
            child: const Text('DI CHUYỂN'),
          ),
        ],
      ),
    );
  }
}
