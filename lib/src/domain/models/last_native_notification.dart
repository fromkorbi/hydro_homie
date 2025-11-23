class LastNativeNotification {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;

  const LastNativeNotification({required this.id, required this.title, required this.body, required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static LastNativeNotification? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return LastNativeNotification(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
