import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/service_model.dart';
import 'package:flying_auto_services/utils/image_utils.dart';

class ServiceProviderState {
  final bool isLoading;
  final List<ServiceModel> services;
  final String? errorMessage;

  ServiceProviderState({
    required this.isLoading,
    required this.services,
    this.errorMessage,
  });

  ServiceProviderState copyWith({
    bool? isLoading,
    List<ServiceModel>? services,
    String? errorMessage,
  }) {
    return ServiceProviderState(
      isLoading: isLoading ?? this.isLoading,
      services: services ?? this.services,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ServiceProvider extends StateNotifier<ServiceProviderState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ServiceProvider()
      : super(
          ServiceProviderState(
            isLoading: true,
            services: [],
          ),
        ) {
    // Load services when provider is initialized
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      state = state.copyWith(isLoading: true);

      final servicesSnapshot = await _firestore.collection('services').get();
      await _processServicesSnapshot(servicesSnapshot);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load services: $e',
      );
    }
  }

  Future<void> fetchServices() async {
    try {
      state = state.copyWith(isLoading: true);

      final servicesSnapshot = await _firestore.collection('services').get();
      await _processServicesSnapshot(servicesSnapshot);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load services: ${e.toString()}',
      );
    }
  }

  Future<void> _processServicesSnapshot(QuerySnapshot snapshot) async {
    final services = snapshot.docs
        .map((doc) => ServiceModel.fromMap(Map<String, dynamic>.from(doc.data() as Map)..['id'] = doc.id))
        .toList();

    state = state.copyWith(
      isLoading: false,
      services: services,
    );
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

  Future<bool> addService({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    required bool isActive,
    File? imageFile,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      // Encode image to base64 if provided
      String? imageBase64;
      if (imageFile != null) {
        imageBase64 = await encodeImageToBase64(imageFile);
      }

      // Create new service document
      final docRef = _firestore.collection('services').doc();
      final now = DateTime.now();
      
      final newService = ServiceModel(
        id: docRef.id,
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        imageUrl: imageBase64,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(newService.toMap());

      // Update local state
      final updatedServices = [...state.services, newService];
      state = state.copyWith(services: updatedServices, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add service: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateService({
    required String id,
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    required bool isActive,
    File? imageFile,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      // Get existing service
      final serviceIndex = state.services.indexWhere((s) => s.id == id);
      if (serviceIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Service not found',
        );
        return false;
      }

      final existingService = state.services[serviceIndex];

      // Encode new image to base64 if provided
      String? imageBase64 = existingService.imageUrl;
      if (imageFile != null) {
        imageBase64 = await encodeImageToBase64(imageFile);
      }

      // Update service document
      final updatedService = existingService.copyWith(
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        imageUrl: imageBase64,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('services')
          .doc(id)
          .update(updatedService.toMap());

      // Update local state
      final updatedServices = [...state.services];
      updatedServices[serviceIndex] = updatedService;
      state = state.copyWith(services: updatedServices, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update service: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      state = state.copyWith(isLoading: true);

      // Get existing service
      final serviceIndex = state.services.indexWhere((s) => s.id == serviceId);
      if (serviceIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Service not found',
        );
        return false;
      }

      final existingService = state.services[serviceIndex];

      // Update status in Firestore
      await _firestore.collection('services').doc(serviceId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local state
      final updatedService = existingService.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      final updatedServices = [...state.services];
      updatedServices[serviceIndex] = updatedService;
      state = state.copyWith(services: updatedServices, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update service status: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    try {
      state = state.copyWith(isLoading: true);

      // Get existing service
      final serviceIndex = state.services.indexWhere((s) => s.id == serviceId);
      if (serviceIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Service not found',
        );
        return false;
      }

      // No need to delete image from storage since we're using base64

      // Delete service document
      await _firestore.collection('services').doc(serviceId).delete();

      // Update local state
      final updatedServices = [...state.services];
      updatedServices.removeAt(serviceIndex);
      state = state.copyWith(services: updatedServices, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete service: ${e.toString()}',
      );
      return false;
    }
  }
}

final serviceProvider =
    StateNotifierProvider<ServiceProvider, ServiceProviderState>((ref) {
  return ServiceProvider();
});
