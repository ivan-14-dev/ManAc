import 'package:flutter/material.dart';
import '../services/app_language_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(language.translate('privacy_policy')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.privacy_tip,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    language.translate('privacy_policy'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Content
            _buildSection(
              '1. Collecte des données',
              'Manac collecte uniquement les informations nécessaires au fonctionnement de l\'application, notamment :\n\n'
              '• Adresse email (authentification via Firebase Authentication)\n'
              '• Données de gestion de stock (articles, mouvements, catégories)\n'
              '• Données de synchronisation et sessions de connexion\n'
              '• Aucune donnée non nécessaire n\'est collectée.',
            ),
            
            _buildSection(
              '2. Stockage des données',
              'Les données sont stockées :\n\n'
              '📱 Localisation sur l\'appareil via SQLite (mode hors ligne)\n'
              '☁️ Sur les serveurs sécurisés de Firebase Cloud Firestore\n\n'
              'Les données sont synchronisées automatiquement lorsque l\'appareil est connecté à Internet.',
            ),
            
            _buildSection(
              '3. Sécurité et protection',
              'Nous mettons en œuvre :\n\n'
              '✓ Authentification sécurisée via Firebase\n'
              '✓ Règles de sécurité Firestore\n'
              '✓ Protection des accès utilisateurs\n'
              '✓ Isolation des données par compte utilisateur\n\n'
              'Cependant, aucun système n\'est totalement invulnérable.',
            ),
            
            _buildSection(
              '4. Partage des données',
              'Manac :\n\n'
              '❌ Ne vendez pas les données\n'
              '❌ Ne partage pas les données à des tiers\n'
              '✅ Utiliser uniquement les services techniques de Firebase pour le fonctionnement de l\'application',
            ),
            
            _buildSection(
              '5. Utilisation des données',
              'Les utilisateurs n\'ont pas le droit d\'utiliser les informations collectées à des fins personnelles. '
              'Toutes les données sont destinées uniquement à la gestion du stock de l\'organisation.',
            ),
            
            _buildSection(
              '6. Responsabilité',
              'L\'utilisateur est responsable :\n\n'
              '• De la confidentialité de son mot de passe\n'
              '• De l\'exactitude des données saisies\n'
              '• De l\'utilisation conforme à la loi\n\n'
              'Manac ne peut être tenu responsable des pertes liées à une mauvaise utilisation ou à un accès non autorisé provoqué par l\'utilisateur.',
            ),
            
            const SizedBox(height: 24),
            Text(
              'Dernière mise à jour: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
