// lib/features/sync/domain/settings_sync.dart - 设置同步模型
/// 设置同步模型
class SettingsSync {
  final String key;
  final dynamic value;
  final DateTime lastModified;
  final bool isSynced;

  const SettingsSync({
    required this.key,
    required this.value,
    required this.lastModified,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'lastModified': lastModified.toIso8601String(),
    'isSynced': isSynced,
  };

  factory SettingsSync.fromJson(Map<String, dynamic> json) {
    return SettingsSync(
      key: json['key'] as String,
      value: json['value'],
      lastModified: DateTime.parse(json['lastModified'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  SettingsSync copyWith({
    String? key,
    dynamic value,
    DateTime? lastModified,
    bool? isSynced,
  }) {
    return SettingsSync(
      key: key ?? this.key,
      value: value ?? this.value,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

/// 设置同步项
class SettingsSyncItem {
  final String category;
  final List<SettingsSync> items;

  const SettingsSyncItem({
    required this.category,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory SettingsSyncItem.fromJson(Map<String, dynamic> json) {
    return SettingsSyncItem(
      category: json['category'] as String,
      items: (json['items'] as List)
          .map((e) => SettingsSync.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
