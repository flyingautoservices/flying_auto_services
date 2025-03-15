import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/order_model.dart';
import 'package:flying_auto_services/providers/order_provider.dart';
import 'package:flying_auto_services/utils/app_colors.dart';
import 'package:intl/intl.dart';

import '../../widgets/custom_app_bar.dart';

class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      appBar: CustomAppBar(showLogo: true, centerTitle: true, height: 150),
      body:
          orderState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : orderState.orders.isEmpty
              ? _buildEmptyState()
              : _buildOrdersList(context, orderState.orders),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<OrderModel> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    // Format date
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(order.scheduledDate);
    final formattedTime = timeFormat.format(order.scheduledDate);

    // Format currency
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_BH',
      symbol: 'BHD ',
      decimalDigits: 3,
    );
    final formattedTotal = currencyFormat.format(order.totalAmount);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(context, order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const Divider(height: 24),
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
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.services.length} ${order.services.length == 1 ? 'service' : 'services'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formattedTotal,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    Color textColor = Colors.white;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case OrderStatus.confirmed:
        chipColor = Colors.blue;
        statusText = 'Confirmed';
        break;
      case OrderStatus.inProgress:
        chipColor = Colors.purple;
        statusText = 'In Progress';
        break;
      case OrderStatus.completed:
        chipColor = Colors.green;
        statusText = 'Completed';
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    // Format currency
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_BH',
      symbol: 'BHD ',
      decimalDigits: 3,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order Details',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...order.services.map(
                        (service) => _buildServiceItem(service, currencyFormat),
                      ),
                      const Divider(height: 32),
                      _buildOrderInfoSection(
                        'Scheduled Date',
                        DateFormat(
                          'EEEE, MMMM d, yyyy',
                        ).format(order.scheduledDate),
                      ),
                      _buildOrderInfoSection(
                        'Scheduled Time',
                        DateFormat('h:mm a').format(order.scheduledDate),
                      ),
                      _buildOrderInfoSection('Order ID', order.id),
                      _buildOrderInfoSection(
                        'Order Date',
                        DateFormat('MMM d, yyyy').format(order.createdAt),
                      ),
                      if (order.notes != null && order.notes!.isNotEmpty)
                        _buildOrderInfoSection('Notes', order.notes!),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            currencyFormat.format(order.totalAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (order.status == OrderStatus.pending)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Cancel order functionality would go here
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel Order'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildServiceItem(
    OrderServiceItem service,
    NumberFormat currencyFormat,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cleaning_services, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (service.assignedEmployeeName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Assigned to: ${service.assignedEmployeeName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Duration: ${service.durationMinutes} minutes',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildServiceStatusChip(service.status),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(service.price),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (service.quantity > 1)
                Text(
                  'x${service.quantity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatusChip(OrderServiceStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case OrderServiceStatus.pending:
        chipColor = Colors.orange.withOpacity(0.2);
        statusText = 'Pending';
        break;
      case OrderServiceStatus.assigned:
        chipColor = Colors.blue.withOpacity(0.2);
        statusText = 'Assigned';
        break;
      case OrderServiceStatus.inProgress:
        chipColor = Colors.purple.withOpacity(0.2);
        statusText = 'In Progress';
        break;
      case OrderServiceStatus.completed:
        chipColor = Colors.green.withOpacity(0.2);
        statusText = 'Completed';
        break;
      case OrderServiceStatus.cancelled:
        chipColor = Colors.red.withOpacity(0.2);
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor.withOpacity(1),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(title, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
