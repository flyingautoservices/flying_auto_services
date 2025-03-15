import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flying_auto_services/models/employee_model.dart';

import 'package:flying_auto_services/providers/employee_provider.dart';
import 'package:flying_auto_services/providers/service_provider.dart';
import 'package:flying_auto_services/utils/app_colors.dart';
import 'package:flying_auto_services/utils/image_utils.dart';
import 'package:flying_auto_services/widgets/custom_app_bar.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class EmployeesManagementScreen extends ConsumerStatefulWidget {
  const EmployeesManagementScreen({super.key});

  @override
  ConsumerState<EmployeesManagementScreen> createState() =>
      _EmployeesManagementScreenState();
}

class _EmployeesManagementScreenState
    extends ConsumerState<EmployeesManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch employees when the screen initializes
    Future.microtask(() {
      ref.read(employeeProvider.notifier).fetchEmployees();
      ref.read(serviceProvider.notifier).fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        height: 150,
        showLogo: true,
        centerTitle: true,
      ),
      backgroundColor: AppColor.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Employee Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showEmployeeFormDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Employee'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Error message if any
          if (employeeState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                employeeState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Loading indicator
          if (employeeState.isLoading)
            const Center(child: CircularProgressIndicator()),

          // Employees List
          Expanded(
            child:
                employeeState.employees.isEmpty
                    ? const Center(child: Text('No employees found'))
                    : ListView.builder(
                      itemCount: employeeState.employees.length,
                      itemBuilder: (context, index) {
                        final employee = employeeState.employees[index];
                        return _buildEmployeeCard(employee);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey!, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppColor.primary.withOpacity(0.2),
          child:
              employee.photoUrl != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.memory(
                      ImageUtils.base64ToUint8List(employee.photoUrl!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                  : Icon(Icons.person, color: AppColor.primary),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Phone: ${employee.phoneNumber}'),
            const SizedBox(height: 4),
            _buildServicesList(employee.serviceIds),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Switch
            Switch(
              value: employee.isActive,
              onChanged: (value) {
                ref
                    .read(employeeProvider.notifier)
                    .toggleEmployeeStatus(employee.id, value);
              },
              activeColor: AppColor.primary,
            ),
            // Edit Button
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEmployeeFormDialog(context, employee),
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteEmployee(employee),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildServicesList(List<String> serviceIds) {
    final serviceState = ref.watch(serviceProvider);
    final services =
        serviceState.services
            .where((service) => serviceIds.contains(service.id))
            .toList();

    if (services.isEmpty) {
      return const Text('No services assigned');
    }

    return Wrap(
      spacing: 4,
      children:
          services
              .map(
                (service) => Chip(
                  label: Text(
                    service.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColor.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(2),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
    );
  }

  void _confirmDeleteEmployee(EmployeeModel employee) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete ${employee.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(employeeProvider.notifier)
                      .deleteEmployee(employee.id);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showEmployeeFormDialog(
    BuildContext context, [
    EmployeeModel? employee,
  ]) {
    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(employee: employee),
    );
  }
}

class EmployeeFormDialog extends ConsumerStatefulWidget {
  final EmployeeModel? employee;

  const EmployeeFormDialog({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  File? _imageFile;
  String? _base64Image;
  List<String> _selectedServiceIds = [];
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _phoneController.text = widget.employee!.phoneNumber;
      _selectedServiceIds = List.from(widget.employee!.serviceIds);
      _isActive = widget.employee!.isActive;
      _base64Image = widget.employee!.photoUrl;

      // Fetch the user email from Firestore
      _fetchUserEmail(widget.employee!.id);
    }
  }

  // Fetch user email from Firestore
  Future<void> _fetchUserEmail(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['email'] != null) {
          setState(() {
            _emailController.text = userData['email'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user email: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);
    final services = serviceState.services;

    // Convert services to MultiSelectItem format
    final items =
        services
            .map((service) => MultiSelectItem<String>(service.id, service.name))
            .toList();

    return AlertDialog(
      title: Text(
        widget.employee == null ? 'Add Employee' : 'Edit Employee',
        style: const TextStyle(color: AppColor.primary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColor.primary.withOpacity(0.2),
                    child:
                        _imageFile != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.file(
                                _imageFile!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                            : _base64Image != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.memory(
                                ImageUtils.base64ToUint8List(_base64Image!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                            : const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: AppColor.primary,
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone number field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Services multi-select dropdown
              MultiSelectDialogField<String>(
                items: items,
                title: const Text('Select Services'),
                selectedColor: AppColor.primary,
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                buttonIcon: const Icon(Icons.arrow_drop_down),
                buttonText: const Text('Select Services'),
                onConfirm: (values) {
                  setState(() {
                    _selectedServiceIds = values;
                  });
                },
                initialValue: _selectedServiceIds,
                chipDisplay: MultiSelectChipDisplay<String>(
                  onTap: (value) {
                    setState(() {
                      _selectedServiceIds.remove(value);
                    });
                  },
                  chipColor: AppColor.primary.withOpacity(0.1),
                  textStyle: const TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              // Active status switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active'),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    activeColor: AppColor.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveEmployee,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.employee == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImageUtils.pickImage(ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final email = _emailController.text.trim();

      if (widget.employee == null) {
        // Add new employee
        await ref
            .read(employeeProvider.notifier)
            .addEmployee(
              name: name,
              email: email,
              phoneNumber: phoneNumber,
              serviceIds: _selectedServiceIds,
              imageFile: _imageFile,
              isActive: _isActive,
            );
      } else {
        // Update existing employee
        await ref
            .read(employeeProvider.notifier)
            .updateEmployee(
              id: widget.employee!.id,
              name: name,
              email: email,
              phoneNumber: phoneNumber,
              serviceIds: _selectedServiceIds,
              imageFile: _imageFile,
              isActive: _isActive,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
