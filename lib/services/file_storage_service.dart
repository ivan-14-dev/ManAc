// ========================================
// Service de stockage de fichiers locaux
// Gère les fichiers JSON, photos CNI et photos d'emprunteurs
// ========================================

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour gérer le stockage local des fichiers
class FileStorageService {
  static const String _dataFolder = 'manac_data';
  static const String _photosFolder = 'manac_photos';
  static const String _cniFolder = 'cni';
  static const String _borrowersFolder = 'borrowers';
  static const String _reportsFolder = 'reports';

  /// Obtient le répertoire de base pour le stockage local
  static Future<Directory> get _baseDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final manacDir = Directory('${directory.path}/$_dataFolder');
    if (!await manacDir.exists()) {
      await manacDir.create(recursive: true);
    }
    return manacDir;
  }

  /// Obtient le répertoire pour les photos
  static Future<Directory> get _photosDirectory async {
    final baseDir = await _baseDirectory;
    final photosDir = Directory('${baseDir.path}/$_photosFolder');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }

  // ====================
  // Stockage des données JSON
  // ====================

  /// Sauvegarde des données JSON localement
  static Future<File> saveJsonData(String fileName, Map<String, dynamic> data) async {
    final baseDir = await _baseDirectory;
    final file = File('${baseDir.path}/$fileName.json');
    return file.writeAsString(jsonEncode(data));
  }

  /// Charge les données JSON depuis le stockage local
  static Future<Map<String, dynamic>?> loadJsonData(String fileName) async {
    try {
      final baseDir = await _baseDirectory;
      final file = File('${baseDir.path}/$fileName.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Erreur lors du chargement des données JSON: $e');
    }
    return null;
  }

  /// Liste tous les fichiers JSON disponibles
  static Future<List<String>> listJsonFiles() async {
    try {
      final baseDir = await _baseDirectory;
      final files = await baseDir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.path.split('/').last.replaceAll('.json', ''))
          .toList();
    } catch (e) {
      print('Erreur lors de la liste des fichiers JSON: $e');
      return [];
    }
  }

  /// Supprime un fichier JSON
  static Future<bool> deleteJsonData(String fileName) async {
    try {
      final baseDir = await _baseDirectory;
      final file = File('${baseDir.path}/$fileName.json');
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Erreur lors de la suppression du fichier JSON: $e');
    }
    return false;
  }

  // ====================
  // Stockage des photos CNI
  // ====================

  /// Sauvegarde une photo CNI localement
  static Future<String> saveCniPhoto(String borrowerId, File imageFile) async {
    final photosDir = await _photosDirectory;
    final cniDir = Directory('${photosDir.path}/$_cniFolder/$borrowerId');
    if (!await cniDir.exists()) {
      await cniDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'cni_$timestamp.jpg';
    final savedFile = await imageFile.copy('${cniDir.path}/$fileName');
    return savedFile.path;
  }

  /// Charge le chemin de la photo CNI
  static Future<String?> getCniPhotoPath(String borrowerId) async {
    try {
      final photosDir = await _photosDirectory;
      final cniDir = Directory('${photosDir.path}/$_cniFolder/$borrowerId');
      if (await cniDir.exists()) {
        final files = await cniDir.list().toList();
        final imageFiles = files.whereType<File>().where(
          (f) => f.path.endsWith('.jpg') || f.path.endsWith('.png')
        );
        if (imageFiles.isNotEmpty) {
          return imageFiles.first.path;
        }
      }
    } catch (e) {
      print('Erreur lors du chargement de la photo CNI: $e');
    }
    return null;
  }

  /// Liste toutes les photos CNI
  static Future<List<String>> listCniPhotos() async {
    try {
      final photosDir = await _photosDirectory;
      final cniDir = Directory('${photosDir.path}/$_cniFolder');
      if (await cniDir.exists()) {
        final dirs = await cniDir.list().toList();
        return dirs
            .whereType<Directory>()
            .map((d) => d.path.split('/').last)
            .toList();
      }
    } catch (e) {
      print('Erreur lors de la liste des photos CNI: $e');
    }
    return [];
  }

  // ====================
  // Stockage des photos d'emprunteurs
  // ====================

  /// Sauvegarde une photo d'emprunteur localement
  static Future<String> saveBorrowerPhoto(String borrowerId, File imageFile) async {
    final photosDir = await _photosDirectory;
    final borrowersDir = Directory('${photosDir.path}/$_borrowersFolder/$borrowerId');
    if (!await borrowersDir.exists()) {
      await borrowersDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'photo_$timestamp.jpg';
    final savedFile = await imageFile.copy('${borrowersDir.path}/$fileName');
    return savedFile.path;
  }

  /// Charge le chemin de la photo d'emprunteur
  static Future<String?> getBorrowerPhotoPath(String borrowerId) async {
    try {
      final photosDir = await _photosDirectory;
      final borrowersDir = Directory('${photosDir.path}/$_borrowersFolder/$borrowerId');
      if (await borrowersDir.exists()) {
        final files = await borrowersDir.list().toList();
        final imageFiles = files.whereType<File>().where(
          (f) => f.path.endsWith('.jpg') || f.path.endsWith('.png')
        );
        if (imageFiles.isNotEmpty) {
          return imageFiles.first.path;
        }
      }
    } catch (e) {
      print("Erreur lors du chargement de la photo d'emprunteur: $e");
    }
    return null;
  }

  // ====================
  // Stockage des rapports
  // ====================

  /// Sauvegarde un rapport localement
  static Future<String> saveReport(File pdfFile, String reportName) async {
    final baseDir = await _baseDirectory;
    final reportsDir = Directory('${baseDir.path}/$_reportsFolder');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    
    final savedFile = await pdfFile.copy('${reportsDir.path}/$reportName');
    return savedFile.path;
  }

  /// Liste tous les rapports
  static Future<List<FileSystemEntity>> listReports() async {
    try {
      final baseDir = await _baseDirectory;
      final reportsDir = Directory('${baseDir.path}/$_reportsFolder');
      if (await reportsDir.exists()) {
        return reportsDir.list().toList();
      }
    } catch (e) {
      print('Erreur lors de la liste des rapports: $e');
    }
    return [];
  }

  // ====================
  // Synchronisation avec Firebase
  // ====================

  /// Téléverse une photo vers Firebase Storage
  static Future<String?> uploadPhotoToFirebase(
    File imageFile, 
    String folder, 
    String fileName
  ) async {
    try {
      final firebaseStorage = firebase_storage.FirebaseStorage.instance;
      final ref = firebaseStorage.ref().child(folder).child(fileName);
      
      final uploadTask = ref.putFile(
        imageFile,
        firebase_storage.SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );
      
      final downloadUrl = await uploadTask.then((taskSnapshot) => taskSnapshot.ref.getDownloadURL());
      return downloadUrl;
    } catch (e) {
      print('Erreur lors du téléversement vers Firebase: $e');
      return null;
    }
  }

  /// Sauvegarde les données dans Firestore
  static Future<bool> saveToFirestore(
    String collection, 
    String docId, 
    Map<String, dynamic> data
  ) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).set(data);
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde Firestore: $e');
      return false;
    }
  }

  /// Charge les données depuis Firestore
  static Future<Map<String, dynamic>?> loadFromFirestore(
    String collection, 
    String docId
  ) async {
    try {
      final doc = await FirebaseFirestore.instance.collection(collection).doc(docId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('Erreur lors du chargement Firestore: $e');
    }
    return null;
  }

  // ====================
  // Utilitaires
  // ====================

  /// Nettoie les fichiers temporaires
  static Future<void> cleanTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = await tempDir.list().toList();
      for (final file in files) {
        if (file is File && file.path.contains('manac_')) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Erreur lors du nettoyage des fichiers temporaires: $e');
    }
  }

  /// Obtient la taille totale du stockage utilisé
  static Future<int> getStorageUsed() async {
    try {
      int totalSize = 0;
      final baseDir = await _baseDirectory;
      await for (final entity in baseDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('Erreur lors du calcul de la taille du stockage: $e');
      return 0;
    }
  }

  /// Formate la taille en octets pour l'affichage
  static String formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
  }
}
