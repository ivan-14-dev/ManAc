import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? _currentUser;
  String? _userId;
  String? _userName;
  bool _isLoading = false;
  String _error = '';

  User? get currentUser => _currentUser;
  String? get userId => _userId;
  String? get userName => _userName;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String get error => _error;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      _currentUser = user;
      _userId = user.uid;
      _userName = user.displayName ?? 'User';
      
      // Save user info to local storage
      await LocalStorageService.setSetting('userId', user.uid);
      await LocalStorageService.setSetting('userName', _userName);
      
      // Add login activity
      await _addLoginActivity();
    } else {
      _currentUser = null;
      _userId = null;
      _userName = null;
    }
    notifyListeners();
  }

  Future<void> _addLoginActivity() async {
    final activity = Activity(
      id: const Uuid().v4(),
      type: 'login',
      title: 'User Logged In',
      description: 'User logged into the app',
      userId: _userId,
      userName: _userName,
    );
    await LocalStorageService.addActivity(activity);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password are required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _userId = credential.user?.uid;
      _userName = credential.user?.displayName ?? email.split('@')[0];
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _error = 'All fields are required';
      notifyListeners();
      return;
    }

    if (password.length < 6) {
      _error = 'Password must be at least 6 characters';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile with name
      await credential.user?.updateDisplayName(name);
      
      _userId = credential.user?.uid;
      _userName = name;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Add logout activity before signing out
    if (_userId != null) {
      final activity = Activity(
        id: const Uuid().v4(),
        type: 'logout',
        title: 'User Logged Out',
        description: 'User logged out of the app',
        userId: _userId,
        userName: _userName,
      );
      await LocalStorageService.addActivity(activity);
      await SyncService.queueForSync(
        action: 'create',
        collection: 'activities',
        data: activity.toMap(),
      );
    }

    await _auth.signOut();
    _userId = null;
    _userName = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      _error = 'Email is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _error = 'Password reset email sent';
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'User account is disabled';
      default:
        return 'Authentication failed: $code';
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
