class Category {
  final String id;
  final String name;
  final List<String> deckIds;
  final DateTime createdAt;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.deckIds,
    required this.createdAt,
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      deckIds: List<String>.from(json['deckIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deckIds': deckIds,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    List<String>? deckIds,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      deckIds: deckIds ?? this.deckIds,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
