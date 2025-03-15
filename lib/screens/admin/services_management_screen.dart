import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flying_auto_services/models/service_model.dart';
import 'package:flying_auto_services/providers/service_provider.dart';
import 'package:flying_auto_services/utils/app_colors.dart';
import 'package:flying_auto_services/utils/image_utils.dart';
import 'package:flying_auto_services/widgets/custom_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ServicesManagementScreen> createState() =>
      _ServicesManagementScreenState();
}

class _ServicesManagementScreenState
    extends ConsumerState<ServicesManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure services are loaded when screen is opened
    Future.microtask(() => ref.read(serviceProvider.notifier).loadServices());
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);

    return Scaffold(
      appBar: const CustomAppBar(height: 150),
      backgroundColor: AppColor.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Services Manager',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColor.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: FloatingActionButton(
              backgroundColor: AppColor.secondary,
              onPressed: () => _showServiceFormDialog(context),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
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
                      'Add a new service to get started',
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: serviceState.services.length,
                itemBuilder: (context, index) {
                  final service = serviceState.services[index];
                  return ServiceListItem(
                    service: service,
                    onEdit: () => _showServiceFormDialog(context, service),
                    onDelete: () => _confirmDeleteService(context, service),
                    onToggleStatus:
                        (isActive) => ref
                            .read(serviceProvider.notifier)
                            .toggleServiceStatus(service.id, isActive),
                  );
                },
              ),
            ),
          if (serviceState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                serviceState.errorMessage!,
                style: const TextStyle(color: AppColor.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showServiceFormDialog(
    BuildContext context, [
    ServiceModel? existingService,
  ]) async {
    await showDialog(
      context: context,
      builder: (context) => ServiceFormDialog(service: existingService),
    );
  }

  Future<void> _confirmDeleteService(
    BuildContext context,
    ServiceModel service,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Service'),
                content: Text(
                  'Are you sure you want to delete ${service.name}? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed && mounted) {
      await ref.read(serviceProvider.notifier).deleteService(service.id);
    }
  }
}

class ServiceListItem extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleStatus;

  const ServiceListItem({
    Key? key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'BHD ',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image with border
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.secondary, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child:
                  service.imageUrl != null
                      ? ImageUtils.base64ToImage(
                        service.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.car_repair,
                              size: 50,
                              color: AppColor.secondary,
                            ),
                      )
                      : const Icon(
                        Icons.car_repair,
                        size: 50,
                        color: AppColor.secondary,
                      ),
            ),
          ),
          const SizedBox(width: 16),
          // Service details container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.secondary, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Service title
                      Expanded(
                        child: Text(
                          service.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              service.isActive
                                  ? AppColor.success.withOpacity(0.2)
                                  : AppColor.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                service.isActive
                                    ? AppColor.success
                                    : AppColor.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Service description
                  Text(
                    service.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColor.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Service price
                  Text(
                    currencyFormat.format(service.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColor.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Toggle status switch
                      Row(
                        children: [
                          Text(
                            service.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  service.isActive
                                      ? AppColor.success
                                      : AppColor.error,
                            ),
                          ),
                          Switch(
                            value: service.isActive,
                            onChanged: onToggleStatus,
                            activeColor: AppColor.success,
                            inactiveThumbColor: AppColor.error,
                          ),
                        ],
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColor.info),
                        onPressed: onEdit,
                        tooltip: 'Edit service',
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColor.error),
                        onPressed: onDelete,
                        tooltip: 'Delete service',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceFormDialog extends ConsumerStatefulWidget {
  final ServiceModel? service;

  const ServiceFormDialog({Key? key, this.service}) : super(key: key);

  @override
  ConsumerState<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  File? _imageFile;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing an existing service
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _descriptionController.text = widget.service!.description;
      _priceController.text = widget.service!.price.toString();
      _durationController.text = widget.service!.durationMinutes.toString();
      _isActive = widget.service!.isActive;
    } else {
      // Default values for new service
      _durationController.text = '60'; // Default 60 minutes
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imageFile = await ImageUtils.pickImage(ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        _imageFile = imageFile;
      });
    }
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final duration = int.parse(_durationController.text.trim());

      bool success;
      if (widget.service == null) {
        // Add new service
        success = await ref
            .read(serviceProvider.notifier)
            .addService(
              name: name,
              description: description,
              price: price,
              durationMinutes: duration,
              isActive: _isActive,
              imageFile: _imageFile,
            );
      } else {
        // Update existing service
        success = await ref
            .read(serviceProvider.notifier)
            .updateService(
              id: widget.service!.id,
              name: name,
              description: description,
              price: price,
              durationMinutes: duration,
              isActive: _isActive,
              imageFile: _imageFile,
            );
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Service' : 'Add New Service',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                // Image picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColor.secondary, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child:
                          _imageFile != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : widget.service?.imageUrl != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ImageUtils.base64ToImage(
                                  widget.service!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const _ImagePlaceholder(),
                                ),
                              )
                              : const _ImagePlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(
                      _imageFile != null || widget.service?.imageUrl != null
                          ? 'Change Image'
                          : 'Select Image',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a service name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Price field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (BHD)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Duration field
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Active status switch
                Row(
                  children: [
                    const Text('Service Status:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            _isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color:
                                  _isActive ? AppColor.success : AppColor.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                            activeColor: AppColor.success,
                            inactiveThumbColor: AppColor.error,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.secondary,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(isEditing ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_photo_alternate, size: 40, color: AppColor.secondary),
        SizedBox(height: 4),
        Text(
          'Add Image',
          style: TextStyle(color: AppColor.secondary, fontSize: 12),
        ),
      ],
    );
  }
}
