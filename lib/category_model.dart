
class Category {
  int? categoryId;
  String name;
  String type; // 'income' or 'expense'
  String iconKey;
  String colorHex;

  Category({
    this.categoryId,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'type': type,
      'icon_key': iconKey,
      'color_hex': colorHex,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: map['category_id'],
      name: map['name'],
      type: map['type'],
      iconKey: map['icon_key'],
      colorHex: map['color_hex'],
    );
  }
}
