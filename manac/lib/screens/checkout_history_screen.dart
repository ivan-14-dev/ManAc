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
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: 'Sélectionner la période',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final equipment = widget.equipmentId.isNotEmpty 
        ? equipmentProvider.getEquipmentById(widget.equipmentId) 
        : null;
    
    // Get all checkouts or filtered by equipment
    List<EquipmentCheckout> allCheckouts;
    if (widget.equipmentId.isNotEmpty) {
      allCheckouts = equipmentProvider.allCheckouts
          .where((e) => e.equipmentId == widget.equipmentId)
          .toList();
    } else {
      allCheckouts = List.from(equipmentProvider.allCheckouts);
    }
    
    // Sort by most recent first
    allCheckouts.sort((a, b) => b.checkoutTime.compareTo(a.checkoutTime));

    // Apply filters
    final filteredCheckouts = allCheckouts.where((checkout) {
      // Filter by returned status
      if (_showReturnedOnly && !checkout.isReturned) return false;
      
      // Filter by date range
      if (_startDate != null && _endDate != null) {
        final checkoutDate = DateTime(
          checkout.checkoutTime.year,
          checkout.checkoutTime.month,
          checkout.checkoutTime.day,
        );
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        if (checkoutDate.isBefore(start) || checkoutDate.isAfter(end)) return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = checkout.borrowerName.toLowerCase().contains(query);
        final matchesCni = checkout.borrowerCni.toLowerCase().contains(query);
        final matchesRoom = checkout.destinationRoom.toLowerCase().contains(query);
        if (!matchesName && !matchesCni && !matchesRoom) return false;
      }
      
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(equipment?.name ?? 'Tous les emprunts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              const Text('Retournés', style: TextStyle(fontSize: 12)),
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
          // Search and Date Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search TextField
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, matricule ou salle...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                // Date Range Filter
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _startDate != null ? Colors.blue : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                size: 20,
                                color: _startDate != null ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null && _endDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'Filtrer par date',
                                style: TextStyle(
                                  color: _startDate != null ? Colors.blue : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_startDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: _clearDateFilter,
                        tooltip: 'Effacer le filtre',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  'Total',
                  filteredCheckouts.length.toString(),
                  Icons.history,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Actifs',
                  filteredCheckouts.where((e) => !e.isReturned).length.toString(),
                  Icons.outbound,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Retournés',
                  filteredCheckouts.where((e) => e.isReturned).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filteredCheckouts.length} résultat(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.sort, size: 16),
                  label: const Text('Plus recent'),
                  onPressed: () {
                    // Already sorted by most recent
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trié par date décroissante')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // History List
          Expanded(
            child: filteredCheckouts.isEmpty
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
                          'Aucun résultat',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _startDate != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            child: const Text('Effacer les filtres'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCheckouts.length,
                    itemBuilder: (context, index) {
                      final checkout = filteredCheckouts[index];
                      return _buildCheckoutCard(context, checkout, equipmentProvider);
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

  Widget _buildCheckoutCard(BuildContext context, EquipmentCheckout checkout, EquipmentProvider provider) {
    final equipment = provider.getEquipmentById(checkout.equipmentId);
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: checkout.isReturned ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    checkout.isReturned ? 'RETOURNÉ' : 'ACTIF',
                    style: TextStyle(
                      color: checkout.isReturned ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Qté: ${checkout.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            // Equipment Name
            if (equipment != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.inventory_2, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      equipment.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            
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
                if (checkout.destinationRoom.isNotEmpty) ...[
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
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Dates
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Emprunt: ${checkout.checkoutTime.day}/${checkout.checkoutTime.month}/${checkout.checkoutTime.year} ${checkout.checkoutTime.hour.toString().padLeft(2, '0')}:${checkout.checkoutTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (checkout.isReturned && checkout.returnTime != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.undo, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Retour: ${checkout.returnTime!.day}/${checkout.returnTime!.month}/${checkout.returnTime!.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ],
            ),
            
            // Duration
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Durée: ${days}j ${hours}h',
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
