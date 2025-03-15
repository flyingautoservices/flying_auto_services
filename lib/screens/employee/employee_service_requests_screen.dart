import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/order_model.dart';
import 'package:flying_auto_services/providers/order_provider.dart';
import 'package:flying_auto_services/utils/app_colors.dart';
import 'package:intl/intl.dart';

import '../../widgets/custom_app_bar.dart';

class EmployeeServiceRequestsScreen extends ConsumerStatefulWidget {
  const EmployeeServiceRequestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeServiceRequestsScreen> createState() =>
      _EmployeeServiceRequestsScreenState();
}

class _EmployeeServiceRequestsScreenState
    extends ConsumerState<EmployeeServiceRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load orders when screen initializes
    Future.microtask(() {
      ref.read(orderProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);

    // Filter orders assigned to the current employee
    final pendingOrders =
        orderState.orders
            .where(
              (order) =>
                  order.status == OrderStatus.pending ||
                  order.status == OrderStatus.inProgress,
            )
            .toList();

    final completedOrders =
        orderState.orders
            .where((order) => order.status == OrderStatus.completed)
            .toList();

    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pending Requests'),
            Tab(text: 'Completed Requests'),
          ],
        ),
      ),
      body:
          orderState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsList(pendingOrders, true),
                  _buildRequestsList(completedOrders, false),
                ],
              ),
    );
  }

  Widget _buildRequestsList(List<OrderModel> orders, bool isPending) {
    if (orders.isEmpty) {
      return _buildEmptyState(isPending);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderItem(order, isPending);
      },
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.pending_actions : Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isPending ? 'No pending requests' : 'No completed requests',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'You don\'t have any pending service requests'
                : 'Your completed service requests will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order, bool isPending) {
    final formattedDate = DateFormat('MMM d, yyyy').format(order.scheduledDate);
    final formattedTime = DateFormat('h:mm a').format(order.scheduledDate);

    // Get only services assigned to the current employee
    final currentUser = ref.read(orderProvider.notifier).currentUser;
    final myServices =
        order.services
            .where((service) => service.assignedEmployeeId == currentUser?.id)
            .toList();

    if (myServices.isEmpty) {
      return const SizedBox(); // Don't show orders without services for this employee
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
          ),

          // Order details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Customer: ${order.customerName}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date and time
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$formattedDate at $formattedTime',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Services assigned to this employee
                const Text(
                  'My Services:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...myServices.map((service) => _buildServiceItem(service)),

                // Action buttons
                if (isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => _updateServiceStatus(
                                  order.id,
                                  myServices,
                                  OrderServiceStatus.inProgress,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Start Service'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => _updateServiceStatus(
                                  order.id,
                                  myServices,
                                  OrderServiceStatus.completed,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Complete Service'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(OrderServiceItem service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.cleaning_services,
              size: 16,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${service.quantity} × ${currencyFormat.format(service.price)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          _buildServiceStatusChip(service.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case OrderStatus.inProgress:
        chipColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case OrderStatus.completed:
        chipColor = AppColor.success;
        statusText = 'Completed';
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildServiceStatusChip(OrderServiceStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case OrderServiceStatus.assigned:
        chipColor = Colors.orange;
        statusText = 'Assigned';
        break;
      case OrderServiceStatus.inProgress:
        chipColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case OrderServiceStatus.completed:
        chipColor = AppColor.success;
        statusText = 'Completed';
        break;
      case OrderServiceStatus.cancelled:
        chipColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _updateServiceStatus(
    String orderId,
    List<OrderServiceItem> services,
    OrderServiceStatus newStatus,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Update service status in Firestore
      await ref
          .read(orderProvider.notifier)
          .updateServiceStatus(
            orderId,
            services.map((s) => s.serviceId).toList(),
            newStatus,
          );

      // Reload orders
      await ref.read(orderProvider.notifier).loadOrders();

      // Close loading dialog and show success message
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == OrderServiceStatus.inProgress
                  ? 'Service started successfully'
                  : 'Service completed successfully',
            ),
            backgroundColor: AppColor.success,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error message
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
