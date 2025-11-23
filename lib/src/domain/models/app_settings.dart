class AppSettings {
  final int dailyTargetMl;
  final int? reminderIntervalMinutes;
  final bool useWorkManager;
  final bool useInexact;
  final bool showOngoingNotification;

  const AppSettings({
    required this.dailyTargetMl,
    this.reminderIntervalMinutes,
    this.useWorkManager = false,
    this.useInexact = false,
    this.showOngoingNotification = false,
  });

  AppSettings copyWith({int? dailyTargetMl, int? reminderIntervalMinutes, bool? useWorkManager, bool? useInexact, bool? showOngoingNotification}) {
    return AppSettings(
      dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      useWorkManager: useWorkManager ?? this.useWorkManager,
      useInexact: useInexact ?? this.useInexact,
      showOngoingNotification: showOngoingNotification ?? this.showOngoingNotification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyTargetMl': dailyTargetMl,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'useWorkManager': useWorkManager,
      'useInexact': useInexact,
      'showOngoingNotification': showOngoingNotification,
    };
  }

  static AppSettings fromJson(Map<String, dynamic> json) {
    return AppSettings(
      dailyTargetMl: (json['dailyTargetMl'] as num?)?.toInt() ?? 2000,
      reminderIntervalMinutes: json['reminderIntervalMinutes'] as int?,
      useWorkManager: json['useWorkManager'] as bool? ?? false,
      useInexact: json['useInexact'] as bool? ?? false,
      showOngoingNotification: json['showOngoingNotification'] as bool? ?? false,
    );
  }

  static AppSettings defaultSettings() {
    return const AppSettings(dailyTargetMl: 2000, reminderIntervalMinutes: null, useWorkManager: false, useInexact: false, showOngoingNotification: false);
  }
}
