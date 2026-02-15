import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../models/equipment_checkout.dart';
import '../widgets/safe_image.dart';

class EquipmentReturnScreen extends StatefulWidget {
  const EquipmentReturnScreen({super.key});

  @override
  State<EquipmentReturnScreen> createState() => _EquipmentReturnScreenState();
}

class _EquipmentReturnScreenState extends State<EquipmentReturnScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _processReturn(EquipmentCheckout checkout) async {
    setState(() => _isLoading = true);

    try {
      final equipmentProvider = context.read<EquipmentProvider>();
      
      await equipmentProvider.returnEquipment(
        checkoutId: checkout.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${checkout.equipmentName} returned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to return equipment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReturnConfirmation(EquipmentCheckout checkout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipment: ${checkout.equipmentName}'),
            Text('Quantity: ${checkout.quantity}'),
            Text('Borrower: ${checkout.borrowerName}'),
            Text('Destination Room: ${checkout.destinationRoom}'),
            const SizedBox(height: 16),
            Text(
              'Return Time: ${DateTime.now().toString().split('.')[0]}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processReturn(checkout);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  List<EquipmentCheckout> _getFilteredCheckouts(
    List<EquipmentCheckout> checkouts,
    String query,
  ) {
    if (query.isEmpty) return checkouts;
    final lowercaseQuery = query.toLowerCase();
    return checkouts.where((checkout) =>
        checkout.equipmentName.toLowerCase().contains(lowercaseQuery) ||
        checkout.borrowerName.toLowerCase().contains(lowercaseQuery) ||
        checkout.borrowerCni.toLowerCase().contains(lowercaseQuery) ||
        checkout.destinationRoom.toLowerCase().contains(lowercaseQuery),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final activeCheckouts = _getFilteredCheckouts(
      equipmentProvider.activeCheckouts,
      _searchController.text,
    );

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by equipment, borrower, or room...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.outbound, color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activeCheckouts.length} Active Checkouts',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Items currently checked out',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Active Checkouts List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeCheckouts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No active checkouts',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: activeCheckouts.length,
                      itemBuilder: (context, index) {
                        final checkout = activeCheckouts[index];
                        return _buildCheckoutCard(context, checkout);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCheckoutCard(BuildContext context, EquipmentCheckout checkout) {
    final duration = DateTime.now().difference(checkout.checkoutTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Equipment Photo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: checkout.equipmentPhotoPath != null && checkout.equipmentPhotoPath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SafeImage(
                            imagePath: checkout.equipmentPhotoPath,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.inventory_2, size: 32, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkout.equipmentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${checkout.quantity}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Time since checkout
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hours > 24 ? Colors.red[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${hours}h ${minutes}m',
                    style: TextStyle(
                      color: hours > 24 ? Colors.red[800] : Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Borrower Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(checkout.borrowerName),
                const SizedBox(width: 16),
                const Icon(Icons.badge, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(checkout.borrowerCni),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.room, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(checkout.destinationRoom),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  checkout.checkoutTime.toString().split('.')[0],
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            
            // CNI Photo Preview
            if (checkout.cniPhotoPath.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'CNI: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SafeImage(
                          imagePath: checkout.cniPhotoPath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Notes
            if (checkout.notes != null && checkout.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkout.notes!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Return Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showReturnConfirmation(checkout),
                icon: const Icon(Icons.undo),
                label: const Text('RETURN EQUIPMENT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
