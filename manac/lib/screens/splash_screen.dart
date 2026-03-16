// ========================================
// Écran de démarrage (Splash Screen)
// Affiche le logo et le nom de l'application
// avec une animation de dégradé orange-bleu
// ========================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Widget d'écran de démarrage avec état
class SplashScreen extends StatefulWidget {
  // Callback appelé quand l'initialisation est terminée
  final VoidCallback onInitialized;
  
  const SplashScreen({super.key, required this.onInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// État de l'écran de démarrage
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Contrôleur d'animation pour gérer les animations
  late AnimationController _controller;
  // Animation de fondu (opacity)
  late Animation<double> _fadeAnimation;
  // Animation d'échelle (zoom)
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur d'animation (durée: 1.5 secondes)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Configuration de l'animation de fondu (de 0 à 1)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    // Configuration de l'animation d'échelle (de 0.5 à 1.0)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    // Démarrer l'animation
    _controller.forward();
    
    // Naviguer vers l'écran principal après l'animation (2.5 secondes)
    Future.delayed(const Duration(milliseconds: 2500), () {
      widget.onInitialized();
    });
  }

  // Libérer les ressources du contrôleur
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Dégradé orange-bleu comme arrière-plan
        decoration: const BoxDecoration(
          gradient: AppTheme.orangeBlueGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Conteneur du logo avec effet de vitre
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Nom de l'application
                      const Text(
                        'ManAc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Sous-titre / Tagline
                      Text(
                        'Gestion de Stock',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Indicateur de chargement
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Texte de chargement
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
