import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? photoUrl; // Base64 encoded image
  final List<String> serviceIds; // List of service IDs this employee can perform
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photoUrl,
    required this.serviceIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a new instance with updated fields
  EmployeeModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    List<String>? serviceIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      serviceIds: serviceIds ?? this.serviceIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert Firestore document to EmployeeModel
  factory EmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmployeeModel(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      photoUrl: data['photoUrl'],
      serviceIds: List<String>.from(data['serviceIds'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert EmployeeModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'serviceIds': serviceIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
