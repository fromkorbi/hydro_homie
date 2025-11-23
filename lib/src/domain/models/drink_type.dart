class DrinkType {
  final String id;
  final String name;
  final int defaultSizeMl;
  final bool favorite;

  const DrinkType({
    required this.id,
    required this.name,
    required this.defaultSizeMl,
    this.favorite = false,
  });

  DrinkType copyWith({String? id, String? name, int? defaultSizeMl, bool? favorite}) {
    return DrinkType(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultSizeMl: defaultSizeMl ?? this.defaultSizeMl,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'defaultSizeMl': defaultSizeMl,
      'favorite': favorite,
    };
  }

  static DrinkType fromJson(Map<String, dynamic> json) {
    return DrinkType(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultSizeMl: (json['defaultSizeMl'] as num).toInt(),
      favorite: json['favorite'] as bool? ?? false,
    );
  }
}
