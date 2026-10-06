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
}
