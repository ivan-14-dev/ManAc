import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import '../widgets/safe_image.dart';
import 'checkout_history_screen.dart';

// Checkout type enum
enum CheckoutType { student, staff, view }

class EquipmentCheckoutScreen extends StatefulWidget {
  const EquipmentCheckoutScreen({super.key});

  @override
  State<EquipmentCheckoutScreen> createState() => _EquipmentCheckoutScreenState();
}

class _EquipmentCheckoutScreenState extends State<EquipmentCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _borrowerNameController = TextEditingController();
  final TextEditingController _borrowerCniController = TextEditingController();
  final TextEditingController _borrowerEmailController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _destinationRoomController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Equipment? _selectedEquipment;
  String? _cniPhotoPath;
  String? _equipmentPhotoPath;
  bool _isLoading = false;
  CheckoutType? _selectedCheckoutType;
  String? _lastCheckoutId;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _borrowerNameController.dispose();
    _borrowerCniController.dispose();
    _borrowerEmailController.dispose();
    _quantityController.dispose();
    _destinationRoomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Show checkout type selection
  void _showCheckoutTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisir le type d\'emprunt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Student Checkout Button
            SizedBox(
              width: double.infinity,
              child: Card(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedCheckoutType = CheckoutType.student);
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.school, color: Colors.blue, size: 28),
                        SizedBox(width: 16),
                        Text(
                          'Emprunt Étudiant',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Staff Checkout Button
            SizedBox(
              width: double.infinity,
              child: Card(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedCheckoutType = CheckoutType.staff);
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.badge, color: Colors.orange, size: 28),
                        SizedBox(width: 16),
                        Text(
                          'Emprunt Personnel',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // View Checkout History Button
            SizedBox(
              width: double.infinity,
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutHistoryScreen(equipmentId: ''),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.green, size: 28),
                        SizedBox(width: 16),
                        Text(
                          'Voir les emprunts',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _resetToTypeSelection() {
    setState(() {
      _selectedCheckoutType = null;
      _clearForm();
    });
  }

  Future<void> _pickCniPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        setState(() {
          _cniPhotoPath = photo.path;
        });
      }
    } catch (e) {
      _showError('Failed to capture CNI photo: $e');
    }
  }

  Future<void> _pickEquipmentPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        setState(() {
          _equipmentPhotoPath = photo.path;
        });
      }
    } catch (e) {
      _showError('Failed to capture equipment photo: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEquipment == null) {
      _showError('Please select an equipment');
      return;
    }

    // For students, CNI photo is required
    if (_selectedCheckoutType == CheckoutType.student && _cniPhotoPath == null) {
      _showError('Please capture CNI photo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final equipmentProvider = context.read<EquipmentProvider>();
      
      await equipmentProvider.checkoutEquipment(
        equipmentId: _selectedEquipment!.id,
        borrowerName: _borrowerNameController.text.trim(),
        borrowerCni: _borrowerCniController.text.trim(),
        borrowerEmail: _borrowerEmailController.text.trim(),
        cniPhotoPath: _cniPhotoPath ?? '',
        destinationRoom: _destinationRoomController.text.trim(),
        quantity: int.parse(_quantityController.text),
        equipmentPhotoPath: _equipmentPhotoPath,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Generate readable checkout ID
      final now = DateTime.now();
      final checkoutId = 'EM${now.year}${(now.month).toString().padLeft(2, '0')}${(now.day).toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
      
      // Show success message with checkout ID
      if (mounted) {
        // Show dialog with checkout ID
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 8),
                Text('Succès'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Équipement emprunté avec succès!'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Votre ID d\'emprunt:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        checkoutId,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Conservez ce code pour le retour de l\'équipement.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_borrowerEmailController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Un email de confirmation a été envoyé.',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearForm();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Failed to checkout equipment: $e.toString()');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _borrowerNameController.clear();
    _borrowerCniController.clear();
    _borrowerEmailController.clear();
    _quantityController.text = '1';
    _destinationRoomController.clear();
    _notesController.clear();
    setState(() {
      _selectedEquipment = null;
      _cniPhotoPath = null;
      _equipmentPhotoPath = null;
      _lastCheckoutId = null;
    });
  }

  void _showEquipmentSelector() {
    final equipmentProvider = context.read<EquipmentProvider>();
    final availableEquipment = equipmentProvider.equipment.where((e) => e.isAvailable).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Equipment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: availableEquipment.isEmpty
                  ? const Center(
                      child: Text('No available equipment'),
                    )
                  : ListView.builder(
                      itemCount: availableEquipment.length,
                      itemBuilder: (context, index) {
                        final equipment = availableEquipment[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: equipment.photoPath != null && equipment.photoPath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SafeImage(
                                        imagePath: equipment.photoPath,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.inventory_2),
                            ),
                            title: Text(equipment.name),
                            subtitle: Text('Available: ${equipment.availableQuantity}/${equipment.totalQuantity}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              setState(() {
                                _selectedEquipment = equipment;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show checkout type selector if none selected
    if (_selectedCheckoutType == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Emprunt'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quel type d\'emprunt souhaitez-vous effectuer?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCheckoutType = CheckoutType.student);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.school, color: Colors.blue, size: 32),
                            const SizedBox(width: 16),
                            const Text(
                              'Emprunt Étudiant',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCheckoutType = CheckoutType.staff);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.badge, color: Colors.orange, size: 32),
                            const SizedBox(width: 16),
                            const Text(
                              'Emprunt Personnel',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutHistoryScreen(equipmentId: ''),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.history, color: Colors.green, size: 32),
                            const SizedBox(width: 16),
                            const Text(
                              'Voir les emprunts',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Build the checkout form based on checkout type
    final isStaff = _selectedCheckoutType == CheckoutType.staff;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStaff ? 'Emprunt Personnel' : 'Emprunt Étudiant'),
        backgroundColor: isStaff ? Colors.orange : Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _resetToTypeSelection,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Equipment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _selectedEquipment != null
                        ? Card(
                            color: Colors.blue[50],
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _selectedEquipment!.photoPath != null && _selectedEquipment!.photoPath!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SafeImage(
                                          imagePath: _selectedEquipment!.photoPath,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.inventory_2),
                              ),
                              title: Text(_selectedEquipment!.name),
                              subtitle: Text('Qty: ${_selectedEquipment!.availableQuantity} available'),
                              trailing: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _selectedEquipment = null),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _showEquipmentSelector,
                            icon: const Icon(Icons.inventory_2),
                            label: const Text('Select Equipment'),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Borrower Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStaff ? 'Information du Personnel' : 'Information de l\'Étudiant',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _borrowerNameController,
                      decoration: InputDecoration(
                        labelText: isStaff ? 'Nom du Personnel' : 'Nom de l\'Étudiant',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter borrower name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _borrowerCniController,
                      decoration: InputDecoration(
                        labelText: isStaff ? 'Matricule' : 'Matricule',
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      validator: (value) => value!.isEmpty 
                          ? (isStaff ? 'Enter matricule' : 'Enter matricule') 
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _borrowerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optionnel)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // CNI Photo - Only required for students
                    if (!isStaff) ...[
                      _cniPhotoPath != null
                          ? Column(
                              children: [
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SafeImage(
                                    imagePath: _cniPhotoPath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _pickCniPhoto,
                                        icon: const Icon(Icons.camera_alt),
                                        label: const Text('Retake CNI Photo'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: _pickCniPhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Capture CNI Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Checkout Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checkout Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Enter quantity';
                        final qty = int.tryParse(value);
                        if (qty == null || qty <= 0) return 'Invalid quantity';
                        if (_selectedEquipment != null && qty > _selectedEquipment!.availableQuantity) {
                          return 'Only ${_selectedEquipment!.availableQuantity} available';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _destinationRoomController,
                      decoration: InputDecoration(
                        labelText: isStaff ? 'Salle (Optionnel)' : 'Salle (Hall)',
                        prefixIcon: const Icon(Icons.room),
                      ),
                      validator: isStaff 
                          ? null  // Room is optional for staff
                          : (value) => value!.isEmpty ? 'Enter destination room' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    // Equipment Photo (Optional)
                    const Text(
                      'Equipment Photo (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _equipmentPhotoPath != null
                        ? Column(
                            children: [
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SafeImage(
                                  imagePath: _equipmentPhotoPath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickEquipmentPhoto,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Retake Photo'),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: _pickEquipmentPhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture Equipment Photo'),
                          ),
                    
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        prefixIcon: const Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Auto-filled timestamp info
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Checkout Time',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateTime.now().toString().split('.')[0],
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
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
                onPressed: _isLoading ? null : _submitCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStaff ? Colors.orange : Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CONFIRM CHECKOUT',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
