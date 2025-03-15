import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/employee_model.dart';
import 'package:flying_auto_services/models/user_model.dart';
import 'package:flying_auto_services/providers/auth_provider.dart';
import 'package:flying_auto_services/utils/image_utils.dart';

class EmployeeProviderState {
  final bool isLoading;
  final String? errorMessage;
  final List<EmployeeModel> employees;

  EmployeeProviderState({
    this.isLoading = false,
    this.errorMessage,
    this.employees = const [],
  });

  // Create a new instance with updated fields
  EmployeeProviderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<EmployeeModel>? employees,
  }) {
    return EmployeeProviderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      employees: employees ?? this.employees,
    );
  }
}

class EmployeeProvider extends StateNotifier<EmployeeProviderState> {
  final FirebaseFirestore _firestore;

  EmployeeProvider(this._firestore) : super(EmployeeProviderState()) {
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Get users with employee role
      // Note: We're not using orderBy with where to avoid the index requirement
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
          
      // We'll sort the results in memory instead
      List<EmployeeModel> employees = [];
      
      // For each user with employee role, get their employee data
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        
        // Check if there's an employee document for this user
        final employeeDoc = await _firestore.collection('employees').doc(userId).get();
        
        if (employeeDoc.exists) {
          // If employee data exists, combine with user data
          final employeeData = employeeDoc.data() as Map<String, dynamic>;
          
          employees.add(EmployeeModel(
            id: userId,
            name: userData['name'] ?? '',
            phoneNumber: userData['phoneNumber'] ?? '',
            photoUrl: userData['profileImageUrl'],
            serviceIds: List<String>.from(employeeData['serviceIds'] ?? []),
            isActive: employeeData['isActive'] ?? true,
            createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        } else {
          // If no employee data exists yet, create a basic employee model from user data
          employees.add(EmployeeModel(
            id: userId,
            name: userData['name'] ?? '',
            phoneNumber: userData['phoneNumber'] ?? '',
            photoUrl: userData['profileImageUrl'],
            serviceIds: [],
            isActive: true,
            createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }
      
      // Sort employees by name in memory
      employees.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      state = state.copyWith(employees: employees, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch employees: ${e.toString()}',
      );
    }
  }

  Future<String?> encodeImageToBase64(File imageFile) async {
    try {
      // Use the ImageUtils class to encode the image to base64
      // This will also handle compression to reduce the size
      final base64Image = await ImageUtils.encodeImageToBase64(imageFile);
      if (base64Image == null) {
        throw Exception('Failed to encode image to base64');
      }
      return base64Image;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to encode image: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> addEmployee({
    required String name,
    required String email,
    required String phoneNumber,
    required List<String> serviceIds,
    File? imageFile,
    bool isActive = true,
    String? city,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Create a new AuthProvider instance to register the user
      final authProvider = AuthProvider();
      
      // Encode image to base64 if provided
      String? photoUrl;
      if (imageFile != null) {
        photoUrl = await encodeImageToBase64(imageFile);
        if (photoUrl == null) {
          throw Exception('Failed to encode image');
        }
      }
      
      // Register user with employee role
      final userModel = await authProvider.registerUser(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        city: city,
        role: UserRole.employee,
      );
      
      if (userModel == null) {
        throw Exception('Failed to create user account for employee');
      }
      
      final id = userModel.id;
      final now = DateTime.now();

      // Create employee object
      final employee = EmployeeModel(
        id: id,
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        serviceIds: serviceIds,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );

      // Add employee-specific data to Firestore
      await _firestore
          .collection('employees')
          .doc(id)
          .set({
            'serviceIds': serviceIds,
            'isActive': isActive,
          });
      
      // If we have a photo URL, update the user profile image
      if (photoUrl != null) {
        await _firestore
            .collection('users')
            .doc(id)
            .update({'profileImageUrl': photoUrl});
      }

      // Update local state
      final updatedEmployees = [...state.employees, employee];
      state = state.copyWith(employees: updatedEmployees, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add employee: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateEmployee({
    required String id,
    required String name,
    required String phoneNumber,
    required List<String> serviceIds,
    File? imageFile,
    bool? isActive,
    String? email,
    String? city,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Find the employee in the current state
      final employeeIndex = state.employees.indexWhere((e) => e.id == id);
      if (employeeIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Employee not found',
        );
        return false;
      }

      final existingEmployee = state.employees[employeeIndex];

      // Encode image to base64 if a new image is provided
      String? photoUrl = existingEmployee.photoUrl;
      if (imageFile != null) {
        photoUrl = await encodeImageToBase64(imageFile);
        if (photoUrl == null) {
          throw Exception('Failed to encode image');
        }
      }

      // Create updated employee object
      final updatedEmployee = existingEmployee.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        serviceIds: serviceIds,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      // Update user data in Firestore
      final userUpdates = {
        'name': name,
        'phoneNumber': phoneNumber,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      if (photoUrl != null) {
        userUpdates['profileImageUrl'] = photoUrl;
      }
      
      if (email != null) {
        userUpdates['email'] = email;
      }
      
      if (city != null) {
        userUpdates['city'] = city;
      }
      
      // Update user data
      await _firestore
          .collection('users')
          .doc(id)
          .update(userUpdates);
          
      // Update employee-specific data
      await _firestore
          .collection('employees')
          .doc(id)
          .update({
            'serviceIds': serviceIds,
            'isActive': isActive ?? existingEmployee.isActive,
          });

      // Update local state
      final updatedEmployees = [...state.employees];
      updatedEmployees[employeeIndex] = updatedEmployee;
      state = state.copyWith(employees: updatedEmployees, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update employee: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteEmployee(String employeeId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Find the employee in the current state
      final employeeIndex = state.employees.indexWhere((e) => e.id == employeeId);
      if (employeeIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Employee not found',
        );
        return false;
      }

      // We don't actually delete the user, just update their role to customer
      // and remove their employee data
      
      // Update user role to customer
      await _firestore.collection('users').doc(employeeId).update({
        'role': 'customer',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Delete employee-specific data
      await _firestore.collection('employees').doc(employeeId).delete();

      // Update local state
      final updatedEmployees = [...state.employees];
      updatedEmployees.removeAt(employeeIndex);
      state = state.copyWith(employees: updatedEmployees, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete employee: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> toggleEmployeeStatus(String employeeId, bool isActive) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Find the employee in the current state
      final employeeIndex = state.employees.indexWhere((e) => e.id == employeeId);
      if (employeeIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Employee not found',
        );
        return false;
      }

      final existingEmployee = state.employees[employeeIndex];

      // Create updated employee object
      final updatedEmployee = existingEmployee.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _firestore
          .collection('employees')
          .doc(employeeId)
          .update({'isActive': isActive, 'updatedAt': FieldValue.serverTimestamp()});

      // Update local state
      final updatedEmployees = [...state.employees];
      updatedEmployees[employeeIndex] = updatedEmployee;
      state = state.copyWith(employees: updatedEmployees, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update employee status: ${e.toString()}',
      );
      return false;
    }
  }
}

// Provider for the employee state
final employeeProvider = StateNotifierProvider<EmployeeProvider, EmployeeProviderState>(
  (ref) => EmployeeProvider(FirebaseFirestore.instance),
);
