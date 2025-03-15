import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/employee_model.dart';
import 'package:flying_auto_services/models/order_model.dart';
import 'package:flying_auto_services/models/user_model.dart';
import 'package:flying_auto_services/providers/cart_provider.dart';
import 'package:flying_auto_services/providers/employee_provider.dart';
import 'package:flying_auto_services/services/user_preferences_service.dart';

class OrderProviderState {
  final bool isLoading;
  final String? errorMessage;
  final List<OrderModel> orders;

  OrderProviderState({
    this.isLoading = false,
    this.errorMessage,
    this.orders = const [],
  });

  OrderProviderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<OrderModel>? orders,
  }) {
    return OrderProviderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orders: orders ?? this.orders,
    );
  }
}

class OrderProvider extends StateNotifier<OrderProviderState> {
  final FirebaseFirestore _firestore;
  final EmployeeProviderState employeeState;
  UserModel? _currentUser;

  OrderProvider(this._firestore, this.employeeState)
    : super(OrderProviderState()) {
    _loadCurrentUser();
  }

  // Load current user from preferences
  Future<void> _loadCurrentUser() async {
    _currentUser = await UserPreferencesService.getUser();
    if (_currentUser != null) {
      await loadOrders();
    }
  }

  // Get current user
  UserModel? get currentUser => _currentUser;

  Future<void> loadOrders() async {
    try {
      state = state.copyWith(isLoading: true);

      // Make sure we have a user before proceeding
      if (_currentUser == null) {
        _currentUser = await UserPreferencesService.getUser();
        
        // If still null after trying to load, throw exception
        if (_currentUser == null) {
          state = state.copyWith(isLoading: false, errorMessage: 'No authenticated user found');
          return;
        }
      }

      // Get orders based on user role
      QuerySnapshot ordersSnapshot;
      // Declare filteredDocs at a higher scope so it's available later
      List<DocumentSnapshot> filteredDocs = [];
      
      if (_currentUser!.role == UserRole.admin) {
        // Admin sees all orders
        ordersSnapshot =
            await _firestore
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .get();
      } else if (_currentUser!.role == UserRole.employee) {
        // Employee sees orders assigned to them
        // Get all orders first, then filter manually to avoid needing a composite index
        ordersSnapshot = await _firestore
            .collection('orders')
            .get();
            
        // Filter the results manually to find orders with services assigned to this employee
        for (var doc in ordersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final services = data['services'] as List<dynamic>;
          
          // Check if any service is assigned to this employee
          bool isAssigned = services.any((service) => 
            service is Map<String, dynamic> && 
            service['assignedEmployeeId'] == _currentUser!.id
          );
          
          if (isAssigned) {
            filteredDocs.add(doc);
          }
        }
        
        // Sort manually by createdAt
        filteredDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
          return bTime.compareTo(aTime); // Descending order
        });
        
        // Instead of creating a new QuerySnapshot, we'll work with the filtered docs directly
        // and create OrderModel objects from them in the loop below
      } else {
        // Customer sees their own orders
        ordersSnapshot =
            await _firestore
                .collection('orders')
                .where('customerId', isEqualTo: _currentUser!.id)
                .orderBy('createdAt', descending: true)
                .get();
      }

      List<OrderModel> orders = [];
      
      // For employees, we need to use the filtered docs directly
      if (_currentUser!.role == UserRole.employee) {
        // Convert filtered docs to OrderModel objects
        orders = filteredDocs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      } else {
        // For other roles, use the query snapshot
        orders = ordersSnapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
      }

      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load orders: $e',
      );
    }
  }

  // Create a new order from cart items with smart employee assignment
  Future<bool> createOrderFromCart(CartState cartState) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      if (_currentUser == null) {
        throw Exception('No authenticated user found');
      }

      if (cartState.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Convert cart items to order service items
      final orderServiceItems = await _prepareOrderServiceItems(
        cartState.items,
      );

      // Calculate total amount
      final totalAmount = orderServiceItems.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      // Create new order
      final newOrder = OrderModel(
        id: '', // Will be set by Firestore
        customerId: _currentUser!.id,
        customerName: _currentUser!.name,
        services: orderServiceItems,
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        status: OrderStatus.pending,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('orders')
          .add(newOrder.toFirestore());

      // Update local state
      final orderWithId = newOrder.copyWith(id: docRef.id);
      final updatedOrders = [...state.orders, orderWithId];
      state = state.copyWith(orders: updatedOrders, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create order: $e',
      );
      return false;
    }
  }

  // Prepare order service items with employee assignment
  Future<List<OrderServiceItem>> _prepareOrderServiceItems(
    List<CartItem> cartItems,
  ) async {
    // Get all employees who can perform services
    final employees =
        employeeState.employees.where((emp) => emp.isActive).toList();

    if (employees.isEmpty) {
      throw Exception('No active employees available');
    }

    // Get service details for each cart item
    final orderServiceItems = <OrderServiceItem>[];

    // Track employee assignments for load balancing
    final employeeAssignments = <String, List<OrderServiceItem>>{};
    for (var employee in employees) {
      employeeAssignments[employee.id] = [];
    }

    // Get the last service time for each employee to prioritize those who haven't done services recently
    final employeeLastServiceTime = await _getEmployeeLastServiceTimes(
      employees,
    );

    // Sort employees by last service time (oldest first)
    employees.sort((a, b) {
      final aTime = employeeLastServiceTime[a.id] ?? DateTime(2000);
      final bTime = employeeLastServiceTime[b.id] ?? DateTime(2000);
      return aTime.compareTo(bTime);
    });

    // For each cart item, find the best employee to assign
    for (var cartItem in cartItems) {
      // Get service details
      final serviceDoc =
          await _firestore
              .collection('services')
              .doc(cartItem.service.id)
              .get();
      if (!serviceDoc.exists) {
        continue; // Skip if service doesn't exist
      }

      // Find employees who can perform this service
      final eligibleEmployees =
          employees
              .where((emp) => emp.serviceIds.contains(cartItem.service.id))
              .toList();

      if (eligibleEmployees.isEmpty) {
        // If no eligible employee, add without assignment
        orderServiceItems.add(
          OrderServiceItem(
            serviceId: cartItem.service.id,
            serviceName: cartItem.service.name,
            price: cartItem.service.price,
            quantity: cartItem.quantity,
            durationMinutes: cartItem.service.durationMinutes,
            status: OrderServiceStatus.pending,
          ),
        );
        continue;
      }

      // Sort eligible employees by workload (least busy first)
      eligibleEmployees.sort((a, b) {
        final aWorkload = employeeAssignments[a.id]?.length ?? 0;
        final bWorkload = employeeAssignments[b.id]?.length ?? 0;
        return aWorkload.compareTo(bWorkload);
      });

      // Assign to the least busy eligible employee
      final assignedEmployee = eligibleEmployees.first;

      final orderServiceItem = OrderServiceItem(
        serviceId: cartItem.service.id,
        serviceName: cartItem.service.name,
        price: cartItem.service.price,
        quantity: cartItem.quantity,
        durationMinutes: cartItem.service.durationMinutes,
        assignedEmployeeId: assignedEmployee.id,
        assignedEmployeeName: assignedEmployee.name,
        status: OrderServiceStatus.assigned,
      );

      orderServiceItems.add(orderServiceItem);

      // Update employee workload
      employeeAssignments[assignedEmployee.id]?.add(orderServiceItem);
    }

    return orderServiceItems;
  }

  // Get the last time each employee performed a service
  Future<Map<String, DateTime>> _getEmployeeLastServiceTimes(
    List<EmployeeModel> employees,
  ) async {
    final result = <String, DateTime>{};

    for (var employee in employees) {
      // Find the most recent order where this employee was assigned
      // Using two separate queries to avoid composite index requirement
      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .where('status', isEqualTo: 'inProgress')
              .get();

      // Get completed orders separately
      final completedOrdersSnapshot =
          await _firestore
              .collection('orders')
              .where('status', isEqualTo: 'completed')
              .get();

      // Combine the results
      final allDocs = [...ordersSnapshot.docs, ...completedOrdersSnapshot.docs];

      // Sort manually by updatedAt
      allDocs.sort((a, b) {
        final aTime = (a.data()['updatedAt'] as Timestamp).toDate();
        final bTime = (b.data()['updatedAt'] as Timestamp).toDate();
        return bTime.compareTo(aTime); // Descending order
      });

      // Take only the first 10
      final limitedDocs = allDocs.take(10).toList();

      for (var doc in limitedDocs) {
        final order = OrderModel.fromFirestore(doc);

        // Check if employee was assigned to any service in this order
        final assignedService = order.services.firstWhere(
          (service) => service.assignedEmployeeId == employee.id,
          orElse:
              () => OrderServiceItem(
                serviceId: '',
                serviceName: '',
                price: 0,
                quantity: 0,
                durationMinutes: 0,
              ),
        );

        if (assignedService.assignedEmployeeId != null) {
          result[employee.id] = order.updatedAt;
          break; // Found the most recent assignment
        }
      }
    }

    return result;
  }

  // Update service status for an order
  Future<void> updateServiceStatus(
    String orderId,
    List<String> serviceIds,
    OrderServiceStatus newStatus,
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Get the order document
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      // Convert to OrderModel
      final order = OrderModel.fromFirestore(orderDoc);
      
      // Update the status of the specified services
      final updatedServices = order.services.map((service) {
        if (serviceIds.contains(service.serviceId)) {
          return service.copyWith(status: newStatus);
        }
        return service;
      }).toList();
      
      // Determine the overall order status based on service statuses
      OrderStatus newOrderStatus = order.status;
      
      // If all services are completed, mark the order as completed
      if (updatedServices.every((s) => s.status == OrderServiceStatus.completed)) {
        newOrderStatus = OrderStatus.completed;
      } 
      // If any service is in progress and none are just assigned, mark as in progress
      else if (updatedServices.any((s) => s.status == OrderServiceStatus.inProgress) && 
               !updatedServices.any((s) => s.status == OrderServiceStatus.assigned)) {
        newOrderStatus = OrderStatus.inProgress;
      }
      
      // Update the order in Firestore
      await _firestore.collection('orders').doc(orderId).update({
        'services': updatedServices.map((s) => s.toMap()).toList(),
        'status': newOrderStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local state
      final updatedOrder = order.copyWith(
        services: updatedServices,
        status: newOrderStatus,
        updatedAt: DateTime.now(),
      );
      
      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) {
          return updatedOrder;
        }
        return o;
      }).toList();
      
      state = state.copyWith(orders: updatedOrders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

// Provider for the order state
final orderProvider = StateNotifierProvider<OrderProvider, OrderProviderState>(
  (ref) =>
      OrderProvider(FirebaseFirestore.instance, ref.watch(employeeProvider)),
);
