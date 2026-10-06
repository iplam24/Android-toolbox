import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/privacy_controller.dart';

class PrivacyView extends GetView<PrivacyController> {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Privacy & Perms Audit',
        subtitle: 'Review dangerous permissions & tracker exposure',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.runAudit(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Risk Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All Apps', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('⚠️ High Risk', 'High', Colors.red),
                const SizedBox(width: 8),
                _buildFilterChip('Medium Risk', 'Medium', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('Low Risk', 'Low', Colors.green),
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
                  child: Text('No apps found matching criteria', style: TextStyle(color: Colors.grey)),
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
                                  '${item.riskLevel} (${item.riskScore})',
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  perm,
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
                              label: const Text('Manage Permissions', style: TextStyle(fontSize: 12)),
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
