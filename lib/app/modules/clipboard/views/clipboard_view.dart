import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../controllers/clipboard_controller.dart';

const _clipboardUsageGuide = UsageGuideData(
  title: 'Bộ nhớ tạm & Lịch sử sao chép',
  description: 'Tự động lưu trữ nội dung bạn sao chép (văn bản, link URL, số điện thoại, code...), tránh mất mát dữ liệu quan trọng khi bạn vô tình sao chép nội dung mới đè lên.',
  steps: [
    'Mỗi khi bạn sao chép (Copy) văn bản từ bất kỳ ứng dụng nào, mở app và bấm biểu tượng "Đồng bộ" 🔄 trên thanh tiêu đề để lưu ngay vào danh sách.',
    'Bấm nút (+) "Tạo ghi chú" ở góc dưới màn hình để tự tạo ghi chú hoặc lưu lại thông tin cần nhớ.',
    'Dùng thanh bộ lọc phía trên (Tất cả, Liên kết, Số điện thoại, Mã lệnh, Văn bản) để tìm lại nhanh nội dung mong muốn.',
    'Bấm biểu tượng Ghim 📌 để giữ lại các mục quan trọng (các mục này sẽ không bị xóa khi dọn dẹp hàng loạt).',
    'Bấm "Sao chép" để nạp lại nội dung vào bộ nhớ tạm, hoặc bấm biểu tượng QR để chuyển ngay thành mã QR cho máy khác quét.',
  ],
  tips: [
    'Bấm biểu tượng chổi quét 🧹 trên thanh tiêu đề để dọn sạch các mục chưa ghim, giúp danh sách luôn gọn gàng.',
    'Dữ liệu được lưu trữ ngoại tuyến hoàn toàn trên điện thoại, đảm bảo an toàn tuyệt đối.',
  ],
);

class ClipboardView extends GetView<ClipboardController> {
  const ClipboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Bộ nhớ tạm',
        subtitle: 'Lịch sử sao chép, ghim ghi chú & công cụ',
        usageGuide: _clipboardUsageGuide,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Đồng bộ Clipboard',
            onPressed: () => controller.syncClipboard(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Dọn dẹp mục chưa ghim',
            onPressed: () => controller.clearAllUnpinned(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClipDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo ghi chú'),
        backgroundColor: AppColors.clipboardColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner Hướng dẫn cách dùng nhanh
          const UsageGuideBanner(guide: _clipboardUsageGuide),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('🔗 Liên kết', 'url'),
                const SizedBox(width: 8),
                _buildFilterChip('📞 Số điện thoại', 'number'),
                const SizedBox(width: 8),
                _buildFilterChip('💻 Mã lệnh', 'code'),
                const SizedBox(width: 8),
                _buildFilterChip('📝 Văn bản', 'text'),
              ],
            ),
          ),

          // List of Clips
          Expanded(
            child: Obx(() {
              final items = controller.filteredItems;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.content_paste_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có lịch sử sao chép',
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sao chép văn bản ở bất kỳ app nào hoặc bấm "Đồng bộ"',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final formattedDate = DateFormat('dd/MM, HH:mm').format(item.timestamp);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(item.type).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _getTypeLabel(item.type),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getTypeColor(item.type),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      item.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                      size: 18,
                                      color: item.isPinned ? AppColors.clipboardColor : Colors.grey,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: item.isPinned ? 'Bỏ ghim' : 'Ghim ghi chú',
                                    onPressed: () => controller.togglePin(item.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Chuyển sang mã QR',
                                    onPressed: () => controller.convertToQr(item.content),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Xóa',
                                    onPressed: () => controller.deleteClip(item.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            item.content,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: const Text('Sao chép', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () => controller.copyClip(item),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        selectedColor: AppColors.clipboardColor,
        checkmarkColor: Colors.white,
        onSelected: (_) => controller.selectedFilter.value = value,
      );
    });
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'url':
        return 'LIÊN KẾT';
      case 'number':
        return 'SỐ';
      case 'code':
        return 'MÃ LỆNH';
      default:
        return 'VĂN BẢN';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'url':
        return Colors.blue;
      case 'number':
        return Colors.green;
      case 'code':
        return Colors.amber;
      default:
        return Colors.purple;
    }
  }

  void _showAddClipDialog(BuildContext context) {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Tạo ghi chú mới'),
        content: TextField(
          controller: textController,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập văn bản, liên kết hoặc nội dung cần nhớ...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => controller.addManualClip(textController.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
