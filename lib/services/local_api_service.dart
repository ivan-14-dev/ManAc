// ========================================
// Service d'authentification API locale
// Permet la connexion vers une API locale sur le réseau
// ========================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'manac_config_service.dart';

/// Service pour l'authentification via API locale
class LocalApiService {
  static const String _loginEndpoint = '/api/auth/login';
  static const String _userEndpoint = '/api/users/me';

  /// Authentifie un utilisateur via l'API locale
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Vérifier si l'API locale est activée
      final isEnabled = ManacConfigService.localApiEnabled;
      if (!isEnabled) {
        return AuthResult(
          success: false,
          error: 'API locale désactivée',
        );
      }

      final apiUrl = ManacConfigService.localApiUrl;
      if (apiUrl.isEmpty) {
        return AuthResult(
          success: false,
          error: 'URL de l\'API non configurée',
        );
      }

      // Faire la requête de connexion
      final response = await http.post(
        Uri.parse('$apiUrl$_loginEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extraire le token et les informations utilisateur
        final token = data['token'] ?? data['access_token'] ?? '';
        final userData = data['user'] ?? data['data'] ?? {};

        if (token.isEmpty) {
          return AuthResult(
            success: false,
            error: 'Token non reçu',
          );
        }

        // Créer l'objet utilisateur
        final user = User.fromLocalApi(userData, token);

        return AuthResult(
          success: true,
          user: user,
          token: token,
        );
      } else if (response.statusCode == 401) {
        return AuthResult(
          success: false,
          error: 'Email ou mot de passe incorrect',
        );
      } else if (response.statusCode == 404) {
        return AuthResult(
          success: false,
          error: 'API non trouvée. Vérifiez l\'URL.',
        );
      } else {
        return AuthResult(
          success: false,
          error: 'Erreur serveur: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Gérer les erreurs de connexion
      String errorMessage = 'Erreur de connexion';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('HandshakeException')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez votre connexion réseau.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Délai d\'attente dépassé. Le serveur ne répond pas.';
      }
      
      return AuthResult(
        success: false,
        error: errorMessage,
      );
    }
  }

  /// Vérifie la connexion à l'API locale
  static Future<bool> checkConnection() async {
    try {
      final isEnabled = ManacConfigService.localApiEnabled;
      if (!isEnabled) return false;

      final apiUrl = ManacConfigService.localApiUrl;
      if (apiUrl.isEmpty) return false;

      final response = await http.get(
        Uri.parse('$apiUrl/api/health'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Teste la connexion avec les identifiants
  static Future<bool> testConnection(String apiUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/health'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Résultat de l'authentification
class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.error,
  });
}
