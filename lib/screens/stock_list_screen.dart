import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/stock_item.dart';
import '../services/local_storage_service.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        return Column(
          children: [
            // Summary cards
            _buildSummaryCards(context),
            const Divider(),
            // Search and filters
            _buildSearchAndFilters(context),
            const Divider(),
            // Stock list
            Expanded(
              child: stockProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : stockProvider.filteredItems.isEmpty
                      ? _buildEmptyState()
                      : _buildStockList(context, stockProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SummaryCard(
            title: 'Total Items',
            value: stockProvider.totalItems.toString(),
            icon: Icons.inventory,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            title: 'Total Quantity',
            value: stockProvider.totalQuantity.toString(),
            icon: Icons.layers,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            title: 'Low Stock',
            value: stockProvider.lowStockCount.toString(),
            icon: Icons.warning,
            color: Colors.red,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            title: 'Total Value',
            value: '\$${stockProvider.totalValue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: stockProvider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        stockProvider.setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              stockProvider.setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: stockProvider.selectedCategory == 'All',
                  onSelected: (selected) {
                    stockProvider.setSelectedCategory('All');
                  },
                ),
                const SizedBox(width: 8),
                ...stockProvider.categories.where((c) => c != 'All').map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: stockProvider.selectedCategory == category,
                      onSelected: (selected) {
                        stockProvider.setSelectedCategory(category);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(BuildContext context, StockProvider stockProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stockProvider.filteredItems.length,
      itemBuilder: (context, index) {
        final item = stockProvider.filteredItems[index];
        return _StockItemCard(item: item);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first item to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockItemCard extends StatelessWidget {
  final StockItem item;

  const _StockItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.isLowStock ? Colors.red[100] : Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.isLowStock ? Icons.warning : Icons.inventory,
            color: item.isLowStock ? Colors.red : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!item.isSynced)
              const Icon(
                Icons.cloud_off,
                size: 16,
                color: Colors.orange,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${item.category} | ${item.location}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Qty: ${item.quantity} ${item.unit}',
                  style: TextStyle(
                    color: item.isLowStock ? Colors.red : null,
                    fontWeight: item.isLowStock ? FontWeight.bold : null,
                  ),
                ),
                if (item.isLowStock) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '(Low Stock)',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Min: ${item.minQuantity}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _showItemDetails(context, item, stockProvider),
        onLongPress: () => _showItemOptions(context, item, stockProvider),
      ),
    );
  }

  void _showItemDetails(
    BuildContext context,
    StockItem item,
    StockProvider stockProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ItemDetailsSheet(item: item),
    );
  }

  void _showItemOptions(
    BuildContext context,
    StockItem item,
    StockProvider stockProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ItemOptionsSheet(item: item),
    );
  }
}

class _ItemDetailsSheet extends StatelessWidget {
  final StockItem item;

  const _ItemDetailsSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.isLowStock ? Icons.warning : Icons.inventory,
                color: item.isLowStock ? Colors.red : Colors.blue,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailRow(label: 'Category', value: item.category),
          _DetailRow(label: 'Location', value: item.location),
          _DetailRow(label: 'Quantity', value: '${item.quantity} ${item.unit}'),
          _DetailRow(label: 'Min Quantity', value: item.minQuantity.toString()),
          _DetailRow(label: 'Price', value: '\$${item.price.toStringAsFixed(2)}'),
          if (item.description != null)
            _DetailRow(label: 'Description', value: item.description!),
          if (item.barcode != null)
            _DetailRow(label: 'Barcode', value: item.barcode!),
          _DetailRow(
            label: 'Status',
            value: item.isLowStock ? '⚠️ Low Stock' : '✅ In Stock',
          ),
          _DetailRow(
            label: 'Sync Status',
            value: item.isSynced ? '✅ Synced' : '⏳ Pending',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAdjustStockDialog(context);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Adjust Stock'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditItemDialog(context);
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AdjustStockDialog(item: item),
    );
  }

  void _showEditItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemOptionsSheet extends StatelessWidget {
  final StockItem item;

  const _ItemOptionsSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Add Stock'),
            onTap: () {
              Navigator.pop(context);
              _showAdjustStockDialog(context, 'in');
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle),
            title: const Text('Remove Stock'),
            onTap: () {
              Navigator.pop(context);
              _showAdjustStockDialog(context, 'out');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Item'),
            onTap: () {
              Navigator.pop(context);
              _showEditItemDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('View History'),
            onTap: () {
              Navigator.pop(context);
              _showHistoryDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Item', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, stockProvider);
            },
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AdjustStockDialog(item: item, defaultType: type),
    );
  }

  void _showEditItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ItemHistoryDialog(item: item),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    StockProvider stockProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              stockProvider.deleteStockItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AdjustStockDialog extends StatefulWidget {
  final StockItem item;
  final String? defaultType;

  const AdjustStockDialog({super.key, required this.item, this.defaultType});

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  String _type = 'in';

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType ?? 'in';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    return AlertDialog(
      title: Text(_type == 'in' ? 'Add Stock' : 'Remove Stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Current: ${widget.item.quantity} ${widget.item.unit}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: const Text('Add'),
                  selected: _type == 'in',
                  onSelected: (selected) {
                    setState(() {
                      _type = 'in';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterChip(
                  label: const Text('Remove'),
                  selected: _type == 'out',
                  onSelected: (selected) {
                    setState(() {
                      _type = 'out';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (Optional)',
              prefixIcon: Icon(Icons.note),
            ),
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
            final quantity = int.tryParse(_quantityController.text);
            if (quantity != null && quantity > 0) {
              stockProvider.adjustStock(
                stockItemId: widget.item.id,
                adjustment: quantity,
                type: _type,
                reason: _reasonController.text.isEmpty ? null : _reasonController.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class EditItemDialog extends StatefulWidget {
  final StockItem item;

  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _minQuantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  
  String _selectedUnit = 'pcs';

  final List<String> _units = ['pcs', 'kg', 'g', 'lb', 'oz', 'l', 'ml', 'box', 'pack', 'dozen'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _categoryController = TextEditingController(text: widget.item.category);
    _minQuantityController = TextEditingController(text: widget.item.minQuantity.toString());
    _priceController = TextEditingController(text: widget.item.price.toString());
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _locationController = TextEditingController(text: widget.item.location);
    _selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _minQuantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Min Quantity',
                      prefixIcon: Icon(Icons.warning),
                    ),
                    keyboardType: TextInputType.number,
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
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedItem = widget.item.copyWith(
              name: _nameController.text,
              category: _categoryController.text,
              minQuantity: int.tryParse(_minQuantityController.text) ?? widget.item.minQuantity,
              unit: _selectedUnit,
              price: double.tryParse(_priceController.text) ?? widget.item.price,
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
              location: _locationController.text,
            );
            stockProvider.updateStockItem(updatedItem);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ItemHistoryDialog extends StatelessWidget {
  final StockItem item;

  const ItemHistoryDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('History: ${item.name}'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: FutureBuilder(
          future: Future.value(
            LocalStorageService.getMovementsByItem(item.id),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final movements = snapshot.data ?? [];

            if (movements.isEmpty) {
              return const Center(
                child: Text('No history available'),
              );
            }

            return ListView.builder(
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final movement = movements[index];
                return ListTile(
                  leading: Icon(
                    movement.type == 'in'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: movement.type == 'in' ? Colors.green : Colors.red,
                  ),
                  title: Text('${movement.type == 'in' ? '+' : '-'}${movement.quantity}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movement.reason ?? ''),
                      Text(
                        '${movement.date}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
