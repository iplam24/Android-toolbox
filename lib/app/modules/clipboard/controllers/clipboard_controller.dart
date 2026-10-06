import 'package:get/get.dart';
import '../../../core/services/clipboard_storage_service.dart';
import '../../../core/services/system_tools_service.dart';
import '../../../data/models/clipboard_item_model.dart';
import '../../../routes/app_routes.dart';

class ClipboardController extends GetxController {
  final clipboardService = ClipboardStorageService.to;
  final systemTools = SystemToolsService.to;

  final RxString selectedFilter = 'all'.obs; // all, url, number, code, text
  final RxString searchQuery = ''.obs;

  List<ClipboardItemModel> get filteredItems {
    var list = clipboardService.items.toList();

    if (selectedFilter.value != 'all') {
      list = list.where((item) => item.type == selectedFilter.value).toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((item) => item.content.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  @override
  void onInit() {
    super.onInit();
    syncClipboard();
  }

  Future<void> syncClipboard() async {
    await clipboardService.syncCurrentClipboard();
  }

  void addManualClip(String text) {
    if (text.trim().isNotEmpty) {
      clipboardService.addClip(text.trim());
      Get.back();
      Get.snackbar('Clip Saved', 'Added to clipboard history');
    }
  }

  void copyClip(ClipboardItemModel item) {
    clipboardService.copyToClipboard(item.content);
    systemTools.vibrate(durationMs: 50);
    Get.snackbar(
      'Copied to Clipboard',
      item.content.length > 50 ? '${item.content.substring(0, 50)}...' : item.content,
      duration: const Duration(seconds: 2),
    );
  }

  void togglePin(String id) {
    clipboardService.togglePin(id);
  }

  void deleteClip(String id) {
    clipboardService.deleteClip(id);
  }

  void clearAllUnpinned() {
    clipboardService.clearUnpinned();
    Get.snackbar('Cleared', 'Unpinned clips removed');
  }

  void convertToQr(String content) {
    Get.toNamed(AppRoutes.QR, arguments: {'initialText': content});
  }
}
