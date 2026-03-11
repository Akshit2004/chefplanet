class Dish {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final double rating;
  final int reviews;
  final int calories;
  final String preparationTime;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.rating,
    this.reviews = 0,
    required this.calories,
    required this.preparationTime,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['_id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      categoryId: json['categoryId'].toString(),
      rating: (json['rating'] as num).toDouble(),
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num).toInt(),
      preparationTime: json['preparationTime'] as String,
    );
  }
}
