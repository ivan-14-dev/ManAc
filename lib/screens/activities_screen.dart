import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_storage_service.dart';
import '../models/activity.dart';

// Fonction helper pour formater les dates
String _formatDateTime(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<Activity> _activities = [];
  bool _isLoading = false;
  String _filterType = 'All';

  final List<String> _activityTypes = [
    'All',
    'stock_in',
    'stock_out',
    'stock_adjustment',
    'sync',
    'login',
    'logout',
    'connection',
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    _activities = LocalStorageService.getRecentActivities(limit: 100);

    setState(() {
      _isLoading = false;
    });
  }

  List<Activity> get _filteredActivities {
    if (_filterType == 'All') {
      return _activities;
    }
    return _activities.where((a) => a.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: _activityTypes.map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_formatTypeLabel(type)),
                  selected: _filterType == type,
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? type : 'All';
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        // Activities list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredActivities.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadActivities,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _filteredActivities[index];
                          return _ActivityCard(activity: activity);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  String _formatTypeLabel(String type) {
    switch (type) {
      case 'stock_in':
        return 'Stock In';
      case 'stock_out':
        return 'Stock Out';
      case 'stock_adjustment':
        return 'Adjustments';
      case 'sync':
        return 'Sync';
      case 'login':
        return 'Login';
      case 'logout':
        return 'Logout';
      case 'connection':
        return 'Connection';
      default:
        return type;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activities found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor().withOpacity(0.1),
          child: Icon(
            _getActivityIcon(),
            color: _getActivityColor(),
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(activity.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(activity.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                if (activity.userName != null) ...[
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activity.userName!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
                if (!activity.isSynced)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.cloud_off,
                      size: 14,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _showActivityDetails(context),
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (activity.type) {
      case 'stock_in':
        return Icons.arrow_downward;
      case 'stock_out':
        return Icons.arrow_upward;
      case 'stock_adjustment':
        return Icons.edit;
      case 'sync':
        return Icons.sync;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'connection':
        return Icons.wifi;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case 'stock_in':
        return Colors.green;
      case 'stock_out':
        return Colors.red;
      case 'stock_adjustment':
        return Colors.orange;
      case 'sync':
        return Colors.blue;
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.grey;
      case 'connection':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _showActivityDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${activity.description}'),
            const SizedBox(height: 8),
            Text('Type: ${activity.type}'),
            const SizedBox(height: 8),
            Text('Time: ${_formatDateTime(activity.timestamp)}'),
            if (activity.userName != null) ...[
              const SizedBox(height: 8),
              Text('User: ${activity.userName}'),
            ],
            if (activity.metadata != null) ...[
              const SizedBox(height: 16),
              const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...activity.metadata!.entries.map((entry) {
                return Text('${entry.key}: ${entry.value}');
              }),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Sync Status: '),
                Icon(
                  activity.isSynced ? Icons.check_circle : Icons.pending,
                  color: activity.isSynced ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
