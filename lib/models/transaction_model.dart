import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class TransactionModel {
  final String id;
  final String customerId;
  final String? employeeId;
  final String serviceId;
  final String carMake;
  final String carModel;
  final String carNumber;
  final DateTime scheduledDate;
  final TransactionStatus status;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.customerId,
    this.employeeId,
    required this.serviceId,
    required this.carMake,
    required this.carModel,
    required this.carNumber,
    required this.scheduledDate,
    required this.status,
    required this.amount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  TransactionModel copyWith({
    String? id,
    String? customerId,
    String? employeeId,
    String? serviceId,
    String? carMake,
    String? carModel,
    String? carNumber,
    DateTime? scheduledDate,
    TransactionStatus? status,
    double? amount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      serviceId: serviceId ?? this.serviceId,
      carMake: carMake ?? this.carMake,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'employeeId': employeeId,
      'serviceId': serviceId,
      'carMake': carMake,
      'carModel': carModel,
      'carNumber': carNumber,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status.toString().split('.').last,
      'amount': amount,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      employeeId: map['employeeId'],
      serviceId: map['serviceId'] ?? '',
      carMake: map['carMake'] ?? '',
      carModel: map['carModel'] ?? '',
      carNumber: map['carNumber'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseTransactionStatus(map['status'] ?? 'pending'),
      amount: (map['amount'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status) {
      case 'inProgress':
        return TransactionStatus.inProgress;
      case 'completed':
        return TransactionStatus.completed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }
}
