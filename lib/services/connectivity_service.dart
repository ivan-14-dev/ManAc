import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity;
  List<ConnectivityResult> _connectionResults = [];
  DateTime? _lastConnectedAt;
  DateTime? _lastDisconnectedAt;
  bool _wasOffline = false;

  ConnectivityService({required Connectivity connectivity})
      : _connectivity = connectivity {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result);
    });
    _connectivity.checkConnectivity().then((result) {
      _handleConnectivityChange(result);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _connectionResults.isNotEmpty;
    final isConnected = results.isNotEmpty && 
        results.any((r) => r != ConnectivityResult.none);

    if (wasConnected && !isConnected) {
      // Went offline
      _lastDisconnectedAt = DateTime.now();
      _wasOffline = true;
      if (_lastConnectedAt != null) {
        SyncService().syncConnectionHours(
          _lastConnectedAt!,
          _lastDisconnectedAt!,
        );
      }
    } else if (!wasConnected && isConnected) {
      // Came online
      _lastConnectedAt = DateTime.now();
      if (_wasOffline) {
        // Trigger sync when coming back online
        SyncService().autoSync();
        _wasOffline = false;
      }
    }

    _connectionResults = results;
    notifyListeners();
  }

  List<ConnectivityResult> get connectionResults => _connectionResults;

  bool get isConnected =>
      _connectionResults.isNotEmpty && 
      _connectionResults.any((r) => r != ConnectivityResult.none);

  DateTime? get lastConnectedAt => _lastConnectedAt;

  DateTime? get lastDisconnectedAt => _lastDisconnectedAt;

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && 
        results.any((r) => r != ConnectivityResult.none);
  }
}
