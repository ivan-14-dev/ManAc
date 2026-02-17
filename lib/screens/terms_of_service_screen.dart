import 'package:flutter/material.dart';
import '../services/app_language_service.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(language.translate('terms_of_service')),
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
                    Icons.description,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    language.translate('terms_of_service'),
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
              '1. Acceptation des conditions',
              'En utilisant l\'application Manac, vous acceptez d\'être lié par ces conditions d\'utilisation. '
              'Si vous n\'êtes pas d\'accord avec ces conditions, veuillez ne pas utiliser l\'application.',
            ),
            
            _buildSection(
              '2. Utilisation de l\'application',
              'Manac est une application de gestion de stock destinée aux organisations. '
              'Vous vous engagez à :\n\n'
              '• Utiliser l\'application conformément à sa destination\n'
              '• Ne pas tenter de contourner les mesures de sécurité\n'
              '• Ne pas utiliser l\'application à des fins illicites\n'
              '• Maintenir la confidentialité de vos identifiants',
            ),
            
            _buildSection(
              '3. Compte utilisateur',
              'Pour utiliser l\'application, vous devez créer un compte. Vous êtes responsable de :\n\n'
              '• La protection de votre mot de passe\n'
              '• Toutes les activités effectuées sous votre compte\n'
              '• La notification immédiate de toute utilisation non autorisée',
            ),
            
            _buildSection(
              '4. Propriété intellectuelle',
              'L\'application Manac et tout son contenu sont la propriété de Manac. '
              'Vous n\'êtes pas autorisé à :\n\n'
              '• Copier, modifier ou distribuer l\'application\n'
              '• Utiliser l\'application pour créer un produit similaire\n'
              '• Retirer les mentions de copyright',
            ),
            
            _buildSection(
              '5. Limitation de responsabilité',
              'Manac ne peut être tenu responsable de :\n\n'
              '• Tout dommage direct ou indirect résultant de l\'utilisation\n'
              '• Toute interruption de service\n'
              '• Toute perte de données\n'
              '• Tout dommage causé par des virus ou autres éléments nuisibles',
            ),
            
            _buildSection(
              '6. Résiliation',
              'Nous nous réservons le droit de résilier votre accès à l\'application à tout moment, '
              'sans préavis, si vous violez ces conditions d\'utilisation.',
            ),
            
            _buildSection(
              '7. Modifications',
              'Nous nous réservons le droit de modifier ces conditions à tout moment. '
              'Les modifications entrent en vigueur dès leur publication sur l\'application.',
            ),
            
            _buildSection(
              '8. Contact',
              'Pour toute question concernant ces conditions, veuillez contacter l\'administrateur de l\'application.',
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
