import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/models/clipboard_item_model.dart';

class ClipboardStorageService extends GetxService {
  static ClipboardStorageService get to => Get.find();

  final _box = GetStorage();
  static const _storageKey = 'clipboard_history_items';

  final RxList<ClipboardItemModel> items = <ClipboardItemModel>[].obs;
  final RxString lastCopiedContent = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void loadHistory() {
    final List<dynamic>? rawList = _box.read<List<dynamic>>(_storageKey);
    if (rawList != null) {
      items.value = rawList
          .map((e) => ClipboardItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _persist() {
    _box.write(_storageKey, items.map((e) => e.toJson()).toList());
  }

  Future<void> syncCurrentClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.trim().isNotEmpty) {
      addClip(text);
    }
  }

  void addClip(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Check duplicate of top item
    if (items.isNotEmpty && items.first.content == trimmed) {
      return;
    }

    // Remove existing if already in list to bring to top
    items.removeWhere((item) => item.content == trimmed && !item.isPinned);

    final newItem = ClipboardItemModel.fromContent(trimmed);
    items.insert(0, newItem);
    lastCopiedContent.value = trimmed;
    _persist();
  }

  void togglePin(String id) {
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final current = items[index];
      items[index] = current.copyWith(isPinned: !current.isPinned);
      // Sort pinned to top
      items.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.timestamp.compareTo(a.timestamp);
      });
      _persist();
    }
  }

  void deleteClip(String id) {
    items.removeWhere((e) => e.id == id);
    _persist();
  }

  void clearUnpinned() {
    items.removeWhere((e) => !e.isPinned);
    _persist();
  }

  Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    lastCopiedContent.value = content;
  }
}
