class ProductImage {
  final int imageId;
  final String imagePath;
  final bool isPrimary;
  final String? createdAt;

  ProductImage({
    required this.imageId,
    required this.imagePath,
    required this.isPrimary,
    this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      imageId: int.parse(json['Image_id'].toString()),
      imagePath: json['Image_path'] ?? '',
      isPrimary: json['Is_primary'] == '1' || json['Is_primary'] == 1,
      createdAt: json['Created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Image_id': imageId,
      'Image_path': imagePath,
      'Is_primary': isPrimary ? 1 : 0,
      'Created_at': createdAt,
    };
  }
}
