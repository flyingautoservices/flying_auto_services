import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/service_model.dart';
import 'package:flying_auto_services/providers/cart_provider.dart';
import 'package:flying_auto_services/providers/order_provider.dart';
import 'package:flying_auto_services/providers/service_provider.dart';
import 'package:flying_auto_services/utils/app_colors.dart';
import 'package:flying_auto_services/utils/image_utils.dart';
import 'package:flying_auto_services/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure services are loaded when screen is opened
    Future.microtask(() => ref.read(serviceProvider.notifier).loadServices());
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: const CustomAppBar(height: 150),
      backgroundColor: AppColor.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Our Services',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColor.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Cart at the bottom
          if (cartState.items.isNotEmpty)
            Align(alignment: Alignment.bottomCenter, child: CartWidget()),
          if (serviceState.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColor.secondary),
              ),
            )
          else if (serviceState.services.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.car_repair,
                      size: 64,
                      color: AppColor.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No services available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check back later',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.67,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: serviceState.services.length,
                itemBuilder: (context, index) {
                  final service = serviceState.services[index];
                  return ServiceGridItem(
                    service: service,
                    onAddToCart: () {}, // Kept for compatibility but not used
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ServiceGridItem extends ConsumerWidget {
  final ServiceModel service;
  final VoidCallback onAddToCart;

  const ServiceGridItem({
    Key? key,
    required this.service,
    required this.onAddToCart,
  }) : super(key: key);

  void _showServiceDetailsDialog(BuildContext context, ServiceModel service) {
    final currencyFormat = NumberFormat.currency(symbol: '\BHD');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(service.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.imageUrl != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      ImageUtils.base64ToUint8List(service.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                Text(
                  'Price: ${currencyFormat.format(service.price)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${service.durationMinutes} minutes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(service.description),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: ' \ BHD ');
    final cartState = ref.watch(cartProvider);
    final isInCart = cartState.items.any(
      (item) => item.service.id == service.id,
    );

    return InkWell(
      //make popup to show the service details
      onTap: () => _showServiceDetailsDialog(context, service),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              border: Border.all(
                color: isInCart ? AppColor.primary : AppColor.secondary,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              child:
                  service.imageUrl != null
                      ? Image.memory(
                        ImageUtils.base64ToUint8List(service.imageUrl!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                      : Container(
                        color: AppColor.primary.withOpacity(0.1),
                        child: const Center(
                          child: Icon(
                            Icons.car_repair,
                            size: 48,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 8),
          // Service name and add button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service name and price container
              Expanded(
                flex: 2,
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: isInCart ? AppColor.primary : AppColor.secondary,
                      width: 3,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currencyFormat.format(service.price),
                        style: TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  color: isInCart ? AppColor.primary : AppColor.secondary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    if (isInCart) {
                      ref.read(cartProvider.notifier).removeService(service.id);
                    } else {
                      ref.read(cartProvider.notifier).addService(service);
                    }
                  },
                  icon: Icon(
                    isInCart ? Icons.remove : Icons.add,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CartWidget extends ConsumerWidget {
  const CartWidget({Key? key}) : super(key: key);
  
  // Process checkout and create a new order
  Future<void> _processCheckout(BuildContext context, WidgetRef ref) async {
    final cartState = ref.read(cartProvider);
    
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing your order...'),
          ],
        ),
      ),
    );
    
    try {
      // Create order with smart employee assignment
      final success = await ref.read(orderProvider.notifier).createOrderFromCart(cartState);
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (success) {
        // Clear cart after successful order creation
        ref.read(cartProvider.notifier).clearCart();
        
        // Show success message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order Placed Successfully'),
            content: const Text(
              'Your order has been placed successfully. Our team will process it shortly.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cart header with total and expand button
          GestureDetector(
            onTap: () => ref.read(cartProvider.notifier).toggleCartExpansion(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '${cartState.totalItems} items',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        currencyFormat.format(cartState.totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        cartState.isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded cart items
          if (cartState.isExpanded)
            Container(
              height: 100,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: cartState.items.length,
                itemBuilder: (context, index) {
                  final item = cartState.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CartItemWidget(
                      item: item,
                      isLast: index == cartState.items.length - 1,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class CartItemWidget extends ConsumerWidget {
  final CartItem item;
  final bool isLast;

  const CartItemWidget({Key? key, required this.item, required this.isLast})
    : super(key: key);
    
  void _processCheckout(BuildContext context, WidgetRef ref) {
    // Call the parent widget's checkout method
    final cartWidget = context.findAncestorWidgetOfExactType<CartWidget>();
    if (cartWidget != null) {
      cartWidget._processCheckout(context, ref);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot process checkout at this time')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Stack(
          children: [
            // Service image and name
            Container(
              width: 70,
              height: 70,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              clipBehavior: Clip.antiAlias,
              child:
                  item.service.imageUrl != null
                      ? Image.memory(
                        ImageUtils.base64ToUint8List(item.service.imageUrl!),
                        fit: BoxFit.cover,
                      )
                      : Container(
                        color: AppColor.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.car_repair,
                          size: 24,
                          color: AppColor.primary,
                        ),
                      ),
            ),
            // Remove button
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(left: 55.0),
                child: InkWell(
                  onTap:
                      () => ref
                          .read(cartProvider.notifier)
                          .removeService(item.service.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isLast) ...[
          const SizedBox(width: 16),
          InkWell(
            onTap: () => _processCheckout(context, ref),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
