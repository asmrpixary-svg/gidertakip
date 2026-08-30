class CategoryModel {
  final int? id;
  final String name;
  final String type; // 'gelir' or 'gider'
  final bool isDefault;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      isDefault: (map['is_default'] as int?) == 1,
    );
  }
}
