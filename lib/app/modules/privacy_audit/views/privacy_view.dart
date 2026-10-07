import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/usage_guide_sheet.dart';
import '../../../data/models/privacy_audit_model.dart';
import '../controllers/privacy_controller.dart';

const _privacyUsageGuide = UsageGuideData(
  title: 'Kiểm toán quyền riêng tư & Ứng dụng',
  description: 'Quét và đánh giá mức độ rủi ro bảo mật của mọi ứng dụng trên máy dựa trên các quyền nhạy cảm (Máy ảnh, Micro thu âm, Vị trí GPS, Danh bạ cá nhân, Tin nhắn SMS) để phòng ngừa rò rỉ dữ liệu cá nhân.',
  steps: [
    'Quan sát danh sách ứng dụng được phân loại theo mức độ rủi ro kèm điểm số bảo mật.',
    'Chọn tab "⚠️ Nguy cơ cao" để xem các ứng dụng sở hữu nhiều quyền nhạy cảm nhất trên máy.',
    'Xem các huy hiệu quyền hạn được cấp (Micro, Vị trí, Danh bạ, Tin nhắn, Máy ảnh...).',
    'Nhấn nút "Quản lý quyền" để mở ngay trang Cài đặt ứng dụng của Android.',
    'Thu hồi hoặc gỡ bỏ các quyền không cần thiết đối với các ứng dụng không đáng tin cậy.',
  ],
  tips: [
    'Quyền Vị trí chạy nền, Ghi âm Micro và Đọc tin nhắn SMS là các quyền có độ rủi ro cao nhất.',
    'Cẩn thận với các ứng dụng tiện ích đơn giản (như đèn pin, máy tính) nhưng lại đòi quyền truy cập danh bạ hay vị trí.',
    'Bấm biểu tượng làm mới ở thanh tiêu đề để quét lại toàn bộ ứng dụng trên máy.',
  ],
);

class PrivacyView extends GetView<PrivacyController> {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quyền riêng tư',
        subtitle: 'Kiểm toán quyền nhạy cảm & bảo mật ứng dụng',
        usageGuide: _privacyUsageGuide,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Quét lại quyền',
            onPressed: () => controller.runAudit(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Hướng dẫn cách dùng nhanh
          const UsageGuideBanner(guide: _privacyUsageGuide),

          // Risk Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('⚠️ Nguy cơ cao', 'High', Colors.red),
                const SizedBox(width: 8),
                _buildFilterChip('Nguy cơ vừa', 'Medium', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('Nguy cơ thấp', 'Low', Colors.green),
              ],
            ),
          ),

          // Audit List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = controller.filteredList;
              if (list.isEmpty) {
                return const Center(
                  child: Text('Không tìm thấy ứng dụng nào khớp tiêu chí lọc', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: list.length,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final riskColor = item.riskLevel == 'High'
                      ? Colors.red
                      : (item.riskLevel == 'Medium' ? Colors.orange : Colors.green);

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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.appName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      item.packageName,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: riskColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: riskColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  '${item.riskLevelText} (${item.riskScore}đ)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: riskColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: item.permissions.map((perm) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  PrivacyAuditModel.formatPermission(perm),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.settings_outlined, size: 14),
                              label: const Text('Quản lý quyền', style: TextStyle(fontSize: 12)),
                              onPressed: () => controller.openAppSettings(item.packageName),
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

  Widget _buildFilterChip(String label, String value, [Color? color]) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        selectedColor: color ?? AppColors.privacyColor,
        checkmarkColor: Colors.white,
        onSelected: (_) => controller.selectedFilter.value = value,
      );
    });
  }
}
