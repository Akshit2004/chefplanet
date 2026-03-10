import 'package:flutter/foundation.dart';
import '../models/dish_model.dart';

class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(Dish dish, int quantity) {
    if (_items.containsKey(dish.id)) {
      _items.update(
        dish.id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          imageUrl: existingItem.imageUrl,
          price: existingItem.price,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        dish.id,
        () => CartItem(
          id: dish.id,
          name: dish.name,
          imageUrl: dish.imageUrl,
          price: dish.price,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String dishId) {
    _items.remove(dishId);
    notifyListeners();
  }

  void updateQuantity(String dishId, int quantity) {
    if (_items.containsKey(dishId)) {
      if (quantity <= 0) {
        _items.remove(dishId);
      } else {
        _items[dishId]!.quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
