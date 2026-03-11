class Category {
  final String id;
  final String name;
  final String imageUrl;

  Category({required this.id, required this.name, required this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'].toString(),
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}
