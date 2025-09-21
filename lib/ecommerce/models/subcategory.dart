class Subcategory {
  final int id;
  final String name;
  final String image;

  Subcategory({
    required this.id,
    required this.name,
    required this.image,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      image: json['image'],
    );
  }
}
