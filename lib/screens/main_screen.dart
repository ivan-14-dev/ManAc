import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../providers/sync_provider.dart';
import '../services/connectivity_service.dart';
import 'stock_list_screen.dart';
import 'activities_screen.dart';
import 'sync_status_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StockListScreen(),
    const ActivitiesScreen(),
    const SyncStatusScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Stock Management',
    'Activities',
    'Sync Status',
    'Settings',
  ];

  final List<IconData> _icons = [
    Icons.inventory,
    Icons.history,
    Icons.sync,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Connection status indicator
          Consumer<ConnectivityService>(
            builder: (context, connectivity, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  connectivity.isConnected 
                      ? Icons.wifi 
                      : Icons.wifi_off,
                  color: connectivity.isConnected 
                      ? Colors.green 
                      : Colors.red,
                ),
              );
            },
          ),
          // Sync pending indicator
          Consumer<SyncProvider>(
            builder: (context, sync, child) {
              if (sync.pendingSyncCount > 0) {
                return Badge(
                  label: Text('${sync.pendingSyncCount}'),
                  child: const Icon(Icons.cloud_upload),
                );
              }
              return const Icon(Icons.cloud_done);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Side navigation for larger screens
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: _titles.asMap().entries.map((entry) {
              return NavigationRailDestination(
                icon: Icon(_icons[entry.key]),
                label: Text(entry.value),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _titles.asMap().entries.map((entry) {
          return NavigationDestination(
            icon: Icon(_icons[entry.key]),
            label: entry.value,
          );
        }).toList(),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddItemDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddStockItemDialog(),
    );
  }
}

class AddStockItemDialog extends StatefulWidget {
  const AddStockItemDialog({super.key});

  @override
  State<AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends State<AddStockItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  String _selectedUnit = 'pcs';
  String _selectedLocation = 'Main Warehouse';

  final List<String> _units = ['pcs', 'kg', 'g', 'lb', 'oz', 'l', 'ml', 'box', 'pack', 'dozen'];
  final List<String> _locations = ['Main Warehouse', 'Store A', 'Store B', 'Back Office'];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter category' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      items: _units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Min Quantity',
                  prefixIcon: Icon(Icons.warning),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter price' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode (Optional)',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _submitForm(context),
          child: const Text('Add Item'),
        ),
      ],
    );
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final stockProvider = Provider.of<StockProvider>(
        context,
        listen: false,
      );

      stockProvider.addStockItem(
        name: _nameController.text,
        category: _categoryController.text,
        quantity: int.parse(_quantityController.text),
        minQuantity: int.tryParse(_minQuantityController.text) ?? 10,
        unit: _selectedUnit,
        price: double.parse(_priceController.text),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        barcode: _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text,
        location: _selectedLocation,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
