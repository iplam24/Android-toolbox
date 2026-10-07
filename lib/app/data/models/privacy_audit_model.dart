class PrivacyAuditModel {
  final String packageName;
  final String appName;
  final List<String> permissions;
  final int riskScore;

  PrivacyAuditModel({
    required this.packageName,
    required this.appName,
    required this.permissions,
    required this.riskScore,
  });

  factory PrivacyAuditModel.fromMap(Map<dynamic, dynamic> map) {
    return PrivacyAuditModel(
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? '',
      permissions: (map['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      riskScore: (map['riskScore'] as num?)?.toInt() ?? 0,
    );
  }

  String get riskLevel {
    if (riskScore >= 8) return 'High';
    if (riskScore >= 4) return 'Medium';
    return 'Low';
  }

  String get riskLevelText {
    if (riskScore >= 8) return 'Nguy cơ cao';
    if (riskScore >= 4) return 'Nguy cơ vừa';
    return 'Nguy cơ thấp';
  }

  static String formatPermission(String perm) {
    final clean = perm.replaceAll('android.permission.', '');
    switch (clean) {
      case 'CAMERA':
        return '📷 Máy ảnh';
      case 'RECORD_AUDIO':
        return '🎙️ Ghi âm Micro';
      case 'ACCESS_FINE_LOCATION':
        return '📍 Vị trí chính xác';
      case 'ACCESS_COARSE_LOCATION':
        return '📍 Vị trí tương đối';
      case 'ACCESS_BACKGROUND_LOCATION':
        return '🛰️ Vị trí chạy nền';
      case 'READ_CONTACTS':
        return '👥 Đọc danh bạ';
      case 'WRITE_CONTACTS':
        return '👥 Ghi danh bạ';
      case 'READ_SMS':
        return '💬 Đọc tin nhắn SMS';
      case 'SEND_SMS':
        return '💬 Gửi tin nhắn SMS';
      case 'READ_CALL_LOG':
        return '📞 Đọc nhật ký gọi';
      case 'READ_PHONE_STATE':
        return '📱 Trạng thái máy';
      case 'READ_EXTERNAL_STORAGE':
        return '📁 Đọc bộ nhớ';
      case 'WRITE_EXTERNAL_STORAGE':
        return '📁 Ghi bộ nhớ';
      case 'MANAGE_EXTERNAL_STORAGE':
        return '🗄️ Toàn quyền bộ nhớ';
      default:
        return clean;
    }
  }
}
