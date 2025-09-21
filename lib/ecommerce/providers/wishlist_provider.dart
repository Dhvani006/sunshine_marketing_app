import 'package:flutter/foundation.dart';

class WishlistItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int discount;

  WishlistItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.discount = 0,
  });
}

class WishlistProvider with ChangeNotifier {
  final Map<String, WishlistItem> _items = {};

  Map<String, WishlistItem> get items => {..._items};

  int get itemCount => _items.length;

  bool isInWishlist(String id) => _items.containsKey(id);

  void toggleWishlist({
    required String id,
    required String name,
    required String imageUrl,
    required double price,
    int discount = 0,
  }) {
    if (_items.containsKey(id)) {
      _items.remove(id);
    } else {
      _items.putIfAbsent(
        id,
        () => WishlistItem(
          id: id,
          name: name,
          imageUrl: imageUrl,
          price: price,
          discount: discount,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
} 