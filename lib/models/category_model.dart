class CategoryItem {
  final int? id;
  final String name;
  final String type; // 'income' or 'expense'
  final bool isCustom;

  CategoryItem({
    this.id,
    required this.name,
    required this.type,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      isCustom: (map['is_custom'] as int?) == 1,
    );
  }
}
