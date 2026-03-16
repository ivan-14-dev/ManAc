import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import '../widgets/safe_image.dart';
import 'checkout_history_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.equipment.name;
    _descriptionController.text = widget.equipment.description;
    _locationController.text = widget.equipment.location;
    _quantityController.text = widget.equipment.totalQuantity.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    
    final updatedEquipment = widget.equipment.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      totalQuantity: int.tryParse(_quantityController.text) ?? widget.equipment.totalQuantity,
    );

    await equipmentProvider.updateEquipment(updatedEquipment);
    
    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment updated successfully!')),
      );
    }
  }

  Future<void> _deleteEquipment() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Are you sure you want to delete ${widget.equipment.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final equipmentProvider = Provider.of<EquipmentProvider>(context);
              await equipmentProvider.deleteEquipment(widget.equipment.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Equipment' : widget.equipment.name),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEquipment,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Photo
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.equipment.photoPath != null && widget.equipment.photoPath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeImage(
                        imagePath: widget.equipment.photoPath,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            ),
            
            const SizedBox(height: 24),
            
            // Status Card
            Card(
              color: widget.equipment.isAvailable ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusItem(
                      'Total',
                      '${widget.equipment.totalQuantity}',
                      Icons.inventory,
                    ),
                    _buildStatusItem(
                      'Available',
                      '${widget.equipment.availableQuantity}',
                      Icons.check_circle,
                    ),
                    _buildStatusItem(
                      'Checked Out',
                      '${widget.equipment.totalQuantity - widget.equipment.availableQuantity}',
                      Icons.outbound,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Details Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DETAILS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isEditing)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      _buildDetailRow('Name', widget.equipment.name),
                    
                    const SizedBox(height: 12),
                    
                    if (_isEditing)
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      )
                    else
                      _buildDetailRow('Description', widget.equipment.description),
                    
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('Category', widget.equipment.category),
                    
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('Serial Number', widget.equipment.serialNumber),
                    
                    const SizedBox(height: 12),
                    
                    if (_isEditing)
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      _buildDetailRow('Location', widget.equipment.location),
                    
                    const SizedBox(height: 12),
                    
                    if (_isEditing)
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Total Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      )
                    else
                      _buildDetailRow('Total Quantity', '${widget.equipment.totalQuantity}'),
                    
                    const SizedBox(height: 12),
                    
                    _buildDetailRow(
                      'Value',
                      '${widget.equipment.value.toStringAsFixed(2)} XOF',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildDetailRow(
                      'Purchase Date',
                      widget.equipment.purchaseDate.toString().split(' ')[0],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('Status', widget.equipment.status.toUpperCase()),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _nameController.text = widget.equipment.name;
                        _descriptionController.text = widget.equipment.description;
                        _locationController.text = widget.equipment.location;
                        _quantityController.text = widget.equipment.totalQuantity.toString();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutHistoryScreen(
                              equipmentId: widget.equipment.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('VIEW CHECKOUT HISTORY'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
