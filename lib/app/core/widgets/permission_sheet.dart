import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';

class PermissionSheet {
  static Future<void> show({bool force = false}) async {
    final box = GetStorage();
    if (!force) {
      final hasAsked = box.read<bool>('has_asked_initial_permissions') ?? false;
      if (hasAsked) return;
    }

    final micGranted = await Permission.microphone.isGranted;
    final cameraGranted = await Permission.camera.isGranted;

    if (micGranted && cameraGranted && !force) {
      return;
    }

    await box.write('has_asked_initial_permissions', true);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cấp quyền truy cập hệ thống',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Để sử dụng trọn vẹn mọi tính năng của Toolbox',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              _buildPermissionItem(
                icon: Icons.mic_rounded,
                color: Colors.deepPurple,
                title: 'Microphone (Ghi âm)',
                description: 'Cần để kiểm tra phần cứng Micro và đo biên độ âm thanh Decibel (dB).',
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                icon: Icons.camera_alt_rounded,
                color: Colors.blue,
                title: 'Máy ảnh (Camera)',
                description: 'Cần để quét mã QR kết nối nhanh và tạo mã QR chia sẻ.',
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                icon: Icons.folder_rounded,
                color: Colors.orange,
                title: 'Lưu trữ & Quản lý tệp',
                description: 'Cần để trích xuất file APK và lưu nhận tệp tin truyền qua WebShare.',
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                icon: Icons.notifications_rounded,
                color: Colors.teal,
                title: 'Thông báo hệ thống',
                description: 'Cần để cảnh báo tức thời khi có thiết bị gửi tệp sang máy bạn.',
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    await [
                      Permission.microphone,
                      Permission.camera,
                      Permission.notification,
                      Permission.storage,
                    ].request();
                    Get.snackbar(
                      'Đã cập nhật quyền',
                      'Cảm ơn bạn! Các tính năng đã sẵn sàng hoạt động.',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 3),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('CẤP TẤT CẢ QUYỀN TRUY CẬP', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildPermissionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
