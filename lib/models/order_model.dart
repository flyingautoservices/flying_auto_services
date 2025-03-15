import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderServiceItem> services;
  final DateTime scheduledDate;
  final OrderStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.services,
    required this.scheduledDate,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  // Create from Firestore document
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      services: (data['services'] as List<dynamic>?)
          ?.map((service) => OrderServiceItem.fromMap(service))
          .toList() ?? [],
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'services': services.map((service) => service.toMap()).toList(),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status.name,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
    };
  }

  // Create a copy with updated fields
  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<OrderServiceItem>? services,
    DateTime? scheduledDate,
    OrderStatus? status,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      services: services ?? this.services,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }
}

class OrderServiceItem {
  final String serviceId;
  final String serviceName;
  final double price;
  final int quantity;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final OrderServiceStatus status;
  final int durationMinutes;

  OrderServiceItem({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.quantity,
    required this.durationMinutes,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.status = OrderServiceStatus.pending,
  });

  // Create from Map
  factory OrderServiceItem.fromMap(Map<String, dynamic> map) {
    return OrderServiceItem(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
      durationMinutes: map['durationMinutes'] ?? 0,
      assignedEmployeeId: map['assignedEmployeeId'],
      assignedEmployeeName: map['assignedEmployeeName'],
      status: OrderServiceStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => OrderServiceStatus.pending,
      ),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'quantity': quantity,
      'durationMinutes': durationMinutes,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'status': status.name,
    };
  }

  // Create a copy with updated fields
  OrderServiceItem copyWith({
    String? serviceId,
    String? serviceName,
    double? price,
    int? quantity,
    int? durationMinutes,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    OrderServiceStatus? status,
  }) {
    return OrderServiceItem(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      status: status ?? this.status,
    );
  }
}

enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled
}

enum OrderServiceStatus {
  pending,
  assigned,
  inProgress,
  completed,
  cancelled
}
