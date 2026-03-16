import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/auth_provider.dart';
import '../models/equipment_checkout.dart';
import '../services/return_service.dart';

class EquipmentReturnScreen extends StatefulWidget {
  const EquipmentReturnScreen({super.key});

  @override
  State<EquipmentReturnScreen> createState() => _EquipmentReturnScreenState();
}

class _EquipmentReturnScreenState extends State<EquipmentReturnScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _flashIdController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  bool _isLoading = false;
  bool _showManualReturn = false;
  bool _showFlashReturn = false;

  @override
  void dispose() {
    _searchController.dispose();
    _flashIdController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  void _resetToSelection() {
    setState(() {
      _showManualReturn = false;
      _showFlashReturn = false;
    });
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
            content: Text('${checkout.equipmentName} retourné avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form after successful return
        _searchController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du retour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processFlashReturn() async {
    final flashId = _flashIdController.text.trim();
    final matricule = _matriculeController.text.trim();
    
    if (flashId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un ID d\'emprunt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (matricule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le matricule'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final returnService = ReturnService();
      final authProvider = context.read<AuthProvider>();
      
      // Use the new flashReturn method with both checkoutId and matricule
      final checkout = await returnService.flashReturn(
        checkoutId: flashId,
        borrowerMatricule: matricule,
        userId: authProvider.userId ?? 'system',
        userName: authProvider.userName ?? 'System',
      );

      if (mounted) {
        // Reload data
        context.read<EquipmentProvider>().loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${checkout.equipmentName} retourné avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        _flashIdController.clear();
        _matriculeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du retour: $e'),
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
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirmer le retour'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Équipement: ${checkout.equipmentName}'),
            Text('Quantité: ${checkout.quantity}'),
            Text('Emprunteur: ${checkout.borrowerName}'),
            Text('Salle: ${checkout.destinationRoom}'),
            const SizedBox(height: 16),
            Text(
              'Date de retour: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Après synchronisation, le système vérifiera que tout est revenu.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
            child: const Text('Confirmer'),
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
        checkout.destinationRoom.toLowerCase().contains(lowercaseQuery) ||
        checkout.id.toLowerCase().contains(lowercaseQuery),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Show return type selection if neither is selected
    if (!_showManualReturn && !_showFlashReturn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Retour d\'équipement'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_return,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'Comment souhaitez-vous effectuer le retour?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Cards in a responsive grid
              Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() => _showManualReturn = true);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search, color: Colors.blue, size: 40),
                                const SizedBox(height: 12),
                                const Text(
                                  'Retour\nManuel',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() => _showFlashReturn = true);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flash_on, color: Colors.orange, size: 40),
                                const SizedBox(height: 12),
                                const Text(
                                  'Retour\nFlash',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Flash Return Screen
    if (_showFlashReturn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Retour Flash'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _resetToSelection,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.flash_on,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Retour Flash',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez l\'ID d\'emprunt et le matricule pour traiter le retour.\nLa synchronisation se fait via ces deux informations.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // ID d'emprunt field
              TextField(
                controller: _flashIdController,
                decoration: InputDecoration(
                  labelText: 'ID d\'emprunt',
                  hintText: 'Entrez l\'ID de l\'emprunt',
                  prefixIcon: const Icon(Icons.qr_code),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Matricule field
              TextField(
                controller: _matriculeController,
                decoration: InputDecoration(
                  labelText: 'Matricule',
                  hintText: 'Entrez le matricule de l\'emprunteur',
                  prefixIcon: const Icon(Icons.badge),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _processFlashReturn,
                  icon: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Traitement...' : 'Confirmer le retour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Info card
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Si l\'ID n\'existe pas en local, un retour sera créé pour la synchronisation.',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Manual Return Screen (original implementation)
    final equipmentProvider = context.watch<EquipmentProvider>();
    final activeCheckouts = _getFilteredCheckouts(
      equipmentProvider.activeCheckouts,
      _searchController.text,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retour Manuel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _resetToSelection,
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par ID, équipement, emprunteur ou salle...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                          '${activeCheckouts.length} emprunts actifs',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Équipements actuellement empruntés',
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
                              'Aucun emprunt actif',
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
                          return _buildCheckoutCard(checkout);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutCard(EquipmentCheckout checkout) {
    final duration = DateTime.now().difference(checkout.checkoutTime);
    final days = duration.inDays;
    final hours = duration.inHours % 24;

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
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ACTIF',
                    style: TextStyle(
                      color: Colors.orange[800],
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    checkout.equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(checkout.borrowerName),
              ],
            ),
            const SizedBox(height: 8),
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
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Emprunté depuis: ${days}j ${hours}h',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReturnConfirmation(checkout),
                icon: const Icon(Icons.check),
                label: const Text('Confirmer le retour'),
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
