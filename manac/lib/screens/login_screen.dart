// ========================================
// Écran de connexion / Inscription
// Permet aux utilisateurs de se connecter ou créer un compte
// Utilise Firebase Authentication (email/password) ou API locale
// ========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_api_service.dart';
import '../services/manac_config_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

// Widget d'écran de connexion avec état
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// État de l'écran de connexion
class _LoginScreenState extends State<LoginScreen> {
  // Clé pour valider le formulaire
  final _formKey = GlobalKey<FormState>();
  // Contrôleurs pour les champs de texte
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  // Mode de connexion (true = login, false = inscription)
  bool _isLogin = true;
  // Afficher/masquer le mot de passe
  bool _obscurePassword = true;
  // Type de connexion: 'firebase' ou 'local'
  String _loginMethod = 'firebase';
  // Indicateur de chargement pour API locale
  bool _isLoadingLocal = false;

  // Libérer les ressources des contrôleurs
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Widget pour le bouton de méthode de connexion
  Widget _buildLoginMethodButton(String label, String value, IconData icon) {
    final isSelected = _loginMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _loginMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Soumettre le formulaire (connexion ou inscription)
  // Tente Firebase et API locale simultanément, utilise celle qui réussit
  Future<void> _submit() async {
    // Si mode inscription, montrer un message
    if (!_isLogin) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryOrange),
              SizedBox(width: 8),
              Text('Information'),
            ],
          ),
          content: const Text(
            'Pour créer un compte, veuillez contacter l\'administrateur de l\'application.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Afficher indicateur de chargement
    setState(() => _isLoadingLocal = true);

    // Tenter les deux connexions simultanément
    final results = await Future.wait([
      _tryFirebaseLogin(authProvider, email, password),
      _tryLocalApiLogin(authProvider, email, password),
    ]);

    setState(() => _isLoadingLocal = false);

    // Vérifier si au moins une connexion a réussi
    final firebaseSuccess = results[0];
    final localApiSuccess = results[1];

    if (!firebaseSuccess && !localApiSuccess) {
      // Les deux ont échoué - afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de connexion. Vérifiez votre connexion réseau ou vos identifiants.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
    // Si l'une des deux a réussi, la navigation est gérée dans les méthodes
  }

  // Tenter la connexion Firebase
  Future<bool> _tryFirebaseLogin(AuthProvider authProvider, String email, String password) async {
    try {
      await authProvider.signIn(email: email, password: password);
      if (authProvider.isAuthenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Tenter la connexion API locale
  Future<bool> _tryLocalApiLogin(AuthProvider authProvider, String email, String password) async {
    if (!ManacConfigService.localApiEnabled) return false;
    
    try {
      final result = await LocalApiService.login(
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        await authProvider.saveLocalUser(result.user!, result.token ?? '');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter le provider d'authentification
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        // Dégradé orange-bleu en arrière-plan
        decoration: const BoxDecoration(
          gradient: AppTheme.orangeBlueGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo de l'application
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Titre selon le mode (connexion ou inscription)
                    Text(
                      _isLogin ? 'Bienvenue' : 'Créer un compte',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Sous-titre
                    Text(
                      _isLogin 
                          ? 'Connectez-vous pour continuer' 
                          : 'Inscrivez-vous pour commencer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Carte du formulaire
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[850] 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Sélecteur de méthode de connexion
                          if (ManacConfigService.localApiEnabled) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildLoginMethodButton(
                                      'Firebase',
                                      'firebase',
                                      Icons.cloud,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildLoginMethodButton(
                                      'API Locale',
                                      'local',
                                      Icons.dns,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Champ Nom (uniquement pour l'inscription)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (!_isLogin && (value == null || value.isEmpty)) {
                                  return 'Veuillez entrer votre nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Champ Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!value.contains('@')) {
                                return 'Veuillez entrer un email valide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Champ Mot de passe
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Le mot de passe doit contenir au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Message d'erreur
                          if (authProvider.error.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authProvider.error,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Bouton de soumission
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (authProvider.isLoading || _isLoadingLocal) ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: (authProvider.isLoading || _isLoadingLocal)
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLogin 
                                          ? (_loginMethod == 'local' ? 'Connexion API Locale' : 'Se connecter') 
                                          : 'S\'inscrire',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Bouton de contournement pour le développement
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const MainScreen()),
                              );
                            },
                            child: Text(
                              'Passer pour le moment (Mode dev)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Basculer entre connexion et inscription
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin 
                                    ? 'Pas de compte? ' 
                                    : 'Déjà un compte? ',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                    authProvider.clearError();
                                  });
                                },
                                child: Text(
                                  _isLogin ? 'S\'inscrire' : 'Se connecter',
                                  style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
