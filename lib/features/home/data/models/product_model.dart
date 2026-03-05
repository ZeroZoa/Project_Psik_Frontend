class ProductModel {
  final int id;
  final String name;
  final String? brand;
  final int? price;
  final String? description;
  final String? imageUrl;
  final String? link;

  ProductModel({
    required this.id,
    required this.name,
    this.brand,
    this.price,
    this.description,
    this.imageUrl,
    this.link,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      price: json['price'] as int?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      link: json['link'] as String?,
    );
  }
}