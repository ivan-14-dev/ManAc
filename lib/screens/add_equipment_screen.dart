import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/equipment_provider.dart';
import '../widgets/safe_image.dart';

class EquipmentEntry {
  String serialNumber;
  String location;

  EquipmentEntry({required this.serialNumber, required this.location});
}

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Controllers for new equipment entry
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // List to store multiple equipment entries
  final List<EquipmentEntry> _equipmentEntries = [];

  String? _photoPath;
  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'Computer',
    'Monitor',
    'Keyboard',
    'Mouse',
    'Printer',
    'Scanner',
    'Projector',
    'Network Equipment',
    'Cables',
    'Accessories',
    'Other',
  ];

  void _addEquipmentEntry() {
    if (_serialNumberController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in serial number and storage location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _equipmentEntries.add(EquipmentEntry(
        serialNumber: _serialNumberController.text.trim(),
        location: _locationController.text.trim(),
      ));
      _serialNumberController.clear();
      _locationController.clear();
    });
  }

  void _removeEquipmentEntry(int index) {
    setState(() {
      _equipmentEntries.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        setState(() {
          _photoPath = photo.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
    }
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_equipmentEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one equipment entry'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final equipmentProvider = context.read<EquipmentProvider>();
      
      // Save each equipment entry
      for (final entry in _equipmentEntries) {
        await equipmentProvider.addEquipment(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          description: _descriptionController.text.trim(),
          serialNumber: entry.serialNumber,
          location: entry.location,
          quantity: 1,
          value: 0,
          photoPath: _photoPath,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_equipmentEntries.length} equipment(s) added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add equipment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Equipment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Section
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _photoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SafeImage(
                              imagePath: _photoPath,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Basic Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BASIC INFORMATION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Equipment Name *',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'Enter equipment name' : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _categoryController.text.isEmpty ? null : _categoryController.text,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _categoryController.text = value ?? '';
                        },
                        validator: (value) => value == null ? 'Select a category' : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Identification
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'IDENTIFICATION',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addEquipmentEntry,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Input fields for new entry
                      TextFormField(
                        controller: _serialNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Serial Number *',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Storage Location *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      // List of added equipment entries
                      if (_equipmentEntries.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Added Equipment (${_equipmentEntries.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _equipmentEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _equipmentEntries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(color: Colors.blue[800]),
                                  ),
                                ),
                                title: Text(
                                  entry.serialNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(entry.location),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeEquipmentEntry(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEquipment,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'ADD EQUIPMENT',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
