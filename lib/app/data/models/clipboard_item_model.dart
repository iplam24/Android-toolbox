class ClipboardItemModel {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isPinned;
  final String type; // 'url', 'number', 'code', 'text'

  ClipboardItemModel({
    required this.id,
    required this.content,
    required this.timestamp,
    this.isPinned = false,
    required this.type,
  });

  factory ClipboardItemModel.fromContent(String text, {bool pinned = false}) {
    final trimmed = text.trim();
    String detectedType = 'text';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      detectedType = 'url';
    } else if (RegExp(r'^[0-9+\-\s()]{7,15}$').hasMatch(trimmed)) {
      detectedType = 'number';
    } else if (trimmed.contains('{') || trimmed.contains(';') || trimmed.contains('def ') || trimmed.contains('class ')) {
      detectedType = 'code';
    }

    return ClipboardItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      timestamp: DateTime.now(),
      isPinned: pinned,
      type: detectedType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isPinned': isPinned,
        'type': type,
      };

  factory ClipboardItemModel.fromJson(Map<String, dynamic> json) =>
      ClipboardItemModel(
        id: json['id'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isPinned: json['isPinned'] as bool? ?? false,
        type: json['type'] as String? ?? 'text',
      );

  ClipboardItemModel copyWith({bool? isPinned}) {
    return ClipboardItemModel(
      id: id,
      content: content,
      timestamp: timestamp,
      isPinned: isPinned ?? this.isPinned,
      type: type,
    );
  }
}
