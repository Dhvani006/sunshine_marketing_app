class Product {
  final int id;
  final String name;
  final String image;
  final String description;
  final double price;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.price,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      image: json['image'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: int.parse(json['stock'].toString()),
    );
  }
} 