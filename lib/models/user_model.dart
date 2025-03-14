import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  customer,
  employee,
  admin,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? city;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.city,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? city,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'city': city,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      city: map['city'],
      role: _parseUserRole(map['role'] ?? 'customer'),
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static UserRole _parseUserRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
        return UserRole.employee;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}
// city
// "Manama"
// (string)


// createdAt
// March 14, 2025 at 3:46:26 PM UTC+3
// (timestamp)


// email
// "hussain@test.com"
// (string)


// id
// "23b76a7b-eed9-4a7b-8ee5-31505872f59e"
// (string)


// name
// "hussain"
// (string)


// phoneNumber
// "31122113"
// (string)


// profileImageUrl
// null
// (null)


// role
// "customer"
// (string)


// updatedAt
// March 14, 2025 at 3:46:26 PM UTC+3
// (timestamp)