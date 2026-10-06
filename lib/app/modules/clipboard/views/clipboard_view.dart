import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/clipboard_controller.dart';

class ClipboardView extends GetView<ClipboardController> {
  const ClipboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Clipboard Manager',
        subtitle: 'History, pinned notes & quick actions',
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Clipboard',
            onPressed: () => controller.syncClipboard(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear Unpinned',
            onPressed: () => controller.clearAllUnpinned(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClipDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Clip'),
        backgroundColor: AppColors.clipboardColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('🔗 URLs', 'url'),
                const SizedBox(width: 8),
                _buildFilterChip('📞 Numbers', 'number'),
                const SizedBox(width: 8),
                _buildFilterChip('💻 Code', 'code'),
                const SizedBox(width: 8),
                _buildFilterChip('📝 Text', 'text'),
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
                        'No clipboard history yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Copy text anywhere or tap "Sync Clipboard"',
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
                  final formattedDate = DateFormat('MMM d, HH:mm').format(item.timestamp);

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
                                      item.type.toUpperCase(),
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
                                    onPressed: () => controller.togglePin(item.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Convert to QR',
                                    onPressed: () => controller.convertToQr(item.content),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                    visualDensity: VisualDensity.compact,
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
                              label: const Text('Copy', style: TextStyle(fontSize: 12)),
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
        title: const Text('Create New Clip'),
        content: TextField(
          controller: textController,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter text, link or notes...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => controller.addManualClip(textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
