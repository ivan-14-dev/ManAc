// ========================================
// Provider d'authentification
// Gère la connexion, inscription et déconnexion des utilisateurs
// Utilise Firebase Authentication
// ========================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/manac_config_service.dart';

// Provider d'authentification avec ChangeNotifier pour la réactivité
class AuthProvider with ChangeNotifier {
  // Instance Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ManacConfigService _configService = ManacConfigService();
  
  // Utilisateur actuellement connecté
  User? _currentUser;
  String? _userId;
  String? _userName;
  // Indicateur de chargement
  bool _isLoading = false;
  // Message d'erreur
  String _error = '';

  // Getters pour accéder aux propriétés
  User? get currentUser => _currentUser;
  String? get userId => _userId;
  String? get userName => _userName;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String get error => _error;

  // Constructeur - initialise l'écouteur d'état d'authentification
  AuthProvider() {
    _init();
  }

  // Initialiser l'écouteur d'état d'authentification
  void _init() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Callback appelé quand l'état d'authentification change
  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      _currentUser = user;
      _userId = user.uid;
      _userName = user.displayName ?? 'Utilisateur';
      
      // Sauvegarder les infos utilisateur en stockage local
      await LocalStorageService.setSetting('userId', user.uid);
      await LocalStorageService.setSetting('userName', _userName);
      
      // Ajouter une activité de connexion
      await _addLoginActivity();
    } else {
      _currentUser = null;
      _userId = null;
      _userName = null;
    }
    notifyListeners();
  }

  // Ajouter une activité de connexion
  Future<void> _addLoginActivity() async {
    final activity = Activity(
      id: const Uuid().v4(),
      type: 'login',
      title: 'Connexion utilisateur',
      description: 'L\'utilisateur s\'est connecté à l\'application',
      userId: _userId,
      userName: _userName,
    );
    await LocalStorageService.addActivity(activity);
  }

  // Connexion avec email et mot de passe
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'L\'email et le mot de passe sont requis';
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
      
      // Sauvegarder l'état de connexion
      await _configService.setLoggedIn(true);
      _userName = credential.user?.displayName ?? email.split('@')[0];
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'Une erreur s\'est produite: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Inscription avec email, mot de passe et nom
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _error = 'Tous les champs sont requis';
      notifyListeners();
      return;
    }

    if (password.length < 6) {
      _error = 'Le mot de passe doit contenir au moins 6 caractères';
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
      
      // Mettre à jour le profil utilisateur avec le nom
      await credential.user?.updateDisplayName(name);
      
      _userId = credential.user?.uid;
      _userName = name;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'Une erreur s\'est produite: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Déconnexion de l'utilisateur
  Future<void> signOut() async {
    // Ajouter une activité de déconnexion avant de se déconnecter
    if (_userId != null) {
      final activity = Activity(
        id: const Uuid().v4(),
        type: 'logout',
        title: 'Déconnexion utilisateur',
        description: 'L\'utilisateur s\'est déconnecté de l\'application',
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
    
    // Supprimer l'état de connexion
    await _configService.setLoggedIn(false);
    notifyListeners();
  }

  // Réinitialiser le mot de passe par email
  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      _error = 'L\'email est requis';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _error = 'Email de réinitialisation du mot de passe envoyé';
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'Une erreur s\'est produite: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convertir le code d'erreur Firebase en message français
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'user-disabled':
        return 'Le compte utilisateur est désactivé';
      case 'API_KEY_NOT_VALID':
        return 'Clé API invalide. Veuillez vérifier la configuration Firebase.';
      case 'api-key-not-valid':
        return 'Clé API invalide. Veuillez vérifier la configuration Firebase.';
      default:
        return 'Échec de l\'authentification: $code';
    }
  }

  // Effacer le message d'erreur
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
