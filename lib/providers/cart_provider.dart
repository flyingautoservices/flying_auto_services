import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/service_model.dart';

class CartItem {
  final ServiceModel service;
  final int quantity;

  CartItem({
    required this.service,
    this.quantity = 1,
  });

  CartItem copyWith({
    ServiceModel? service,
    int? quantity,
  }) {
    return CartItem(
      service: service ?? this.service,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => service.price * quantity;
}

class CartState {
  final List<CartItem> items;
  final bool isExpanded;

  CartState({
    required this.items,
    this.isExpanded = false,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isExpanded,
  }) {
    return CartState(
      items: items ?? this.items,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}

class CartProvider extends StateNotifier<CartState> {
  CartProvider() : super(CartState(items: []));

  void addService(ServiceModel service) {
    final existingIndex = state.items.indexWhere((item) => item.service.id == service.id);
    
    if (existingIndex >= 0) {
      // Service already in cart, increase quantity
      final updatedItems = [...state.items];
      final currentItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + 1,
      );
      
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new service to cart
      final updatedItems = [...state.items, CartItem(service: service)];
      state = state.copyWith(items: updatedItems);
    }
  }

  void removeService(String serviceId) {
    final updatedItems = state.items.where((item) => item.service.id != serviceId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(String serviceId, int quantity) {
    if (quantity <= 0) {
      removeService(serviceId);
      return;
    }

    final updatedItems = [...state.items];
    final itemIndex = updatedItems.indexWhere((item) => item.service.id == serviceId);
    
    if (itemIndex >= 0) {
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(quantity: quantity);
      state = state.copyWith(items: updatedItems);
    }
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }

  void toggleCartExpansion() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }
}

final cartProvider = StateNotifierProvider<CartProvider, CartState>((ref) {
  return CartProvider();
});
