import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../models/equipment_checkout.dart';

class CheckoutHistoryScreen extends StatefulWidget {
  final String equipmentId;

  const CheckoutHistoryScreen({super.key, required this.equipmentId});

  @override
  State<CheckoutHistoryScreen> createState() => _CheckoutHistoryScreenState();
}

class _CheckoutHistoryScreenState extends State<CheckoutHistoryScreen> {
  bool _showReturnedOnly = false;

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final equipment = equipmentProvider.getEquipmentById(widget.equipmentId);
    
    final allCheckouts = equipmentProvider.allCheckouts
        .where((e) => e.equipmentId == widget.equipmentId)
        .toList()
      ..sort((a, b) => b.checkoutTime.compareTo(a.checkoutTime));

    final displayedCheckouts = _showReturnedOnly
        ? allCheckouts.where((e) => e.isReturned).toList()
        : allCheckouts;

    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${equipment?.name ?? 'Equipment'}'),
        actions: [
          Row(
            children: [
              const Text('Returned only'),
              Switch(
                value: _showReturnedOnly,
                onChanged: (value) => setState(() => _showReturnedOnly = value),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  'Total',
                  allCheckouts.length.toString(),
                  Icons.history,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Active',
                  allCheckouts.where((e) => !e.isReturned).length.toString(),
                  Icons.outbound,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Returned',
                  allCheckouts.where((e) => e.isReturned).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ),
          
          // History List
          Expanded(
            child: displayedCheckouts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_showReturnedOnly ? 'returned' : ''} history',
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
                    itemCount: displayedCheckouts.length,
                    itemBuilder: (context, index) {
                      final checkout = displayedCheckouts[index];
                      return _buildCheckoutCard(context, checkout);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutCard(BuildContext context, EquipmentCheckout checkout) {
    final returnDuration = checkout.returnTime != null
        ? checkout.returnTime!.difference(checkout.checkoutTime)
        : DateTime.now().difference(checkout.checkoutTime);
    final days = returnDuration.inDays;
    final hours = returnDuration.inHours % 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: checkout.isReturned ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    checkout.isReturned ? 'RETURNED' : 'ACTIVE',
                    style: TextStyle(
                      color: checkout.isReturned ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Qty: ${checkout.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Borrower Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(checkout.borrowerName),
              ],
            ),
            const SizedBox(height: 8),
            
            // CNI and Room
            Row(
              children: [
                const Icon(Icons.badge, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(checkout.borrowerCni),
                const SizedBox(width: 16),
                const Icon(Icons.room, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    checkout.destinationRoom,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Dates
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Out: ${checkout.checkoutTime.toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (checkout.isReturned && checkout.returnTime != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.undo, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Ret: ${checkout.returnTime!.toString().split('.')[0]}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ],
            ),
            
            // Duration
            if (checkout.isReturned)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Duration: ${days}d ${hours}h',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ),
            
            // Notes
            if (checkout.notes != null && checkout.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkout.notes!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
