// ========================================
// Service de rapports complet
// Gère la génération de rapports avec données réelles (Firebase + Local)
// Permet la conservation des rapports en fichiers
// ========================================

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/equipment_checkout.dart';
import '../models/daily_report.dart';
import '../models/equipment.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import '../services/file_storage_service.dart';

// Fonction helper pour formater les dates en français
String _formatDateFrench(DateTime date) {
  const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
  const days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  final dayName = days[date.weekday - 1];
  final monthName = months[date.month - 1];
  return '$dayName ${date.day} $monthName ${date.year}';
}

String _formatDateShort(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formatMonthYear(DateTime date) {
  const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
  return '${months[date.month - 1]} ${date.year}';
}

String _formatDateForFilename(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Build PDF header widget
pw.Widget _buildPdfHeader(PdfColor primaryColor) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 16),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'MANAC',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Gestion de Stock',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Text(
          _formatDateFrench(DateTime.now()),
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
      ],
    ),
  );
}

/// Service pour générer des rapports avec données réelles
class ReportService {
  /// Récupère les données réelles (Firebase + Local) pour les rapports
  static Future<ReportData> getRealTimeData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now();
    final end = endDate ?? DateTime.now();

    // Récupérer les données locales
    final localCheckouts = LocalStorageService.getAllCheckouts();
    final localEquipment = LocalStorageService.getAllEquipment();

    // Tenter de récupérer les données Firebase
    List<EquipmentCheckout> firebaseCheckouts = [];
    try {
      firebaseCheckouts = await FirebaseService.getActiveCheckouts();
    } catch (e) {
      print('Erreur récupération Firebase checkouts: $e');
    }

    // Fusionner les données (éviter les doublons)
    final allCheckouts = _mergeCheckouts(localCheckouts, firebaseCheckouts);

    // Filtrer par date si nécessaire
    final filteredCheckouts = allCheckouts.where((c) {
      final checkoutDate = c.checkoutTime;
      return (startDate == null || checkoutDate.isAfter(start) || checkoutDate.isAtSameMomentAs(start)) &&
             (endDate == null || checkoutDate.isBefore(end) || checkoutDate.isAtSameMomentAs(end));
    }).toList();

    return ReportData(
      checkouts: filteredCheckouts,
      equipment: localEquipment,
      startDate: start,
      endDate: end,
    );
  }

  /// Fusionne les données locales et Firebase en évitant les doublons
  static List<EquipmentCheckout> _mergeCheckouts(
    List<EquipmentCheckout> local,
    List<EquipmentCheckout> firebase,
  ) {
    final Map<String, EquipmentCheckout> merged = {};
    
    // Ajouter les données locales
    for (final checkout in local) {
      merged[checkout.id] = checkout;
    }
    
    // Ajouter ou mettre à jour avec les données Firebase
    for (final checkout in firebase) {
      if (merged.containsKey(checkout.id)) {
        // Utiliser la plus récente
        final existing = merged[checkout.id]!;
        if (checkout.checkoutTime.isAfter(existing.checkoutTime)) {
          merged[checkout.id] = checkout;
        }
      } else {
        merged[checkout.id] = checkout;
      }
    }
    
    return merged.values.toList()..sort((a, b) => b.checkoutTime.compareTo(a.checkoutTime));
  }

  /// Génère un rapport journalier avec données réelles
  static Future<DailyReport> generateDailyReportWithRealData({
    required DateTime date,
    String userId = 'system',
    String userName = 'System',
  }) async {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    // Obtenir les données réelles
    final data = await getRealTimeData(
      startDate: dateStart,
      endDate: dateEnd,
    );

    final todayCheckouts = data.checkouts;
    final todayReturns = todayCheckouts.where((c) => c.isReturned && c.returnTime != null).toList();

    final totalCheckouts = todayCheckouts.length;
    final totalReturns = todayReturns.length;
    final totalItemsCheckedOut = todayCheckouts.fold(0, (sum, e) => sum + e.quantity);
    final totalItemsReturned = todayReturns.fold(0, (sum, e) => sum + e.quantity);

    // Générer un résumé détaillé
    final summary = _generateDetailedSummary(
      totalCheckouts,
      totalReturns,
      totalItemsCheckedOut,
      totalItemsReturned,
      todayCheckouts,
      todayReturns,
    );

    final report = DailyReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: dateStart,
      totalCheckouts: totalCheckouts,
      totalReturns: totalReturns,
      totalItemsCheckedOut: totalItemsCheckedOut,
      totalItemsReturned: totalItemsReturned,
      checkoutIds: todayCheckouts.map((e) => e.id).toList(),
      returnIds: todayReturns.map((e) => e.id).toList(),
      summary: summary,
      generatedBy: userName,
      generatedAt: DateTime.now(),
    );

    // Sauvegarder localement
    await LocalStorageService.addDailyReport(report);

    return report;
  }

  /// Génère un résumé détaillé pour le rapport
  static String _generateDetailedSummary(
    int totalCheckouts,
    int totalReturns,
    int totalItemsCheckedOut,
    int totalItemsReturned,
    List<EquipmentCheckout> checkouts,
    List<EquipmentCheckout> returns,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== RAPPORT JOURNALIER ÉQUIPEMENTS ===');
    buffer.writeln('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('');
    buffer.writeln('RÉSUMÉ:');
    buffer.writeln('- Total des emprunts: $totalCheckouts');
    buffer.writeln('- Total des retours: $totalReturns');
    buffer.writeln('- Articles empruntés: $totalItemsCheckedOut');
    buffer.writeln('- Articles retournés: $totalItemsReturned');
    buffer.writeln('- En cours: ${totalItemsCheckedOut - totalItemsReturned}');
    buffer.writeln('');
    
    if (checkouts.isNotEmpty) {
      buffer.writeln('DÉTAILS DES EMPRUNTS:');
      for (final checkout in checkouts) {
        buffer.writeln('- ${checkout.equipmentName} (${checkout.quantity}x) -> ${checkout.borrowerName} (Salle: ${checkout.destinationRoom}) à ${checkout.checkoutTime.hour}:${checkout.checkoutTime.minute.toString().padLeft(2, '0')}');
      }
      buffer.writeln('');
    }

    if (returns.isNotEmpty) {
      buffer.writeln('DÉTAILS DES RETOURS:');
      for (final ret in returns) {
        buffer.writeln('- ${ret.equipmentName} (${ret.quantity}x) retourné par ${ret.borrowerName} à ${ret.returnTime!.hour}:${ret.returnTime!.minute.toString().padLeft(2, '0')}');
      }
    }

    return buffer.toString();
  }

  /// Génère un rapport complet en PDF
  static Future<File> generateCompletePdfReport({
    required DailyReport report,
    required List<EquipmentCheckout> checkouts,
    required List<Equipment> equipment,
  }) async {
    final pdf = pw.Document();
    
    final primaryColor = PdfColor.fromHex('#FF6B35');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête ICT University Cisco Lab
            _buildICTHeader(primaryColor),
            pw.SizedBox(height: 20),
            
            // Titre
            pw.Center(
              child: pw.Text(
                'RAPPORT D\'EMPRUNT ET RETOUR MATERIEL',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Période du rapport
            pw.Center(
              child: pw.Text(
                'Rapport Du ${_formatDateShort(report.date)} Au ${_formatDateShort(report.date.add(const Duration(days: 1)))}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Tableau des activités
            _buildActivityTable(checkouts),
            pw.SizedBox(height: 20),
            
            // Statistiques récapitulatives
            _buildSummaryBox(
              report.totalCheckouts,
              report.totalReturns,
              report.totalItemsCheckedOut,
              report.totalItemsReturned,
              primaryColor,
            ),
            pw.SizedBox(height: 20),
            
            // Pied de page
            _buildPdfFooter(report.generatedBy, report.generatedAt),
          ];
        },
      ),
    );

    // Sauvegarder le PDF
    final output = await getApplicationDocumentsDirectory();
    final fileName = 'rapport_complet_${_formatDateForFilename(report.date)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// En-tête ICT University Cisco Lab
  static pw.Widget _buildICTHeader(PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: primaryColor.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryColor),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'ICT University',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'CISCO LAB - TECHNICAL TEAM',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Tableau des activités avec les nouvelles colonnes
  static pw.Widget _buildActivityTable(List<EquipmentCheckout> checkouts) {
    final sortedCheckouts = List<EquipmentCheckout>.from(checkouts)
      ..sort((a, b) => b.checkoutTime.compareTo(a.checkoutTime));
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),   // N°
        1: const pw.FlexColumnWidth(3),   // NOM
        2: const pw.FlexColumnWidth(2.5), // MATRICULE
        3: const pw.FlexColumnWidth(3),  // MATERIEL
        4: const pw.FlexColumnWidth(2),   // DATE
        5: const pw.FlexColumnWidth(2),   // HEURE CHECKOUT
        6: const pw.FlexColumnWidth(2),   // HEURE RETOUR
        7: const pw.FlexColumnWidth(2.5), // ADMIN CHECKOUT
        8: const pw.FlexColumnWidth(2.5), // ADMIN RETURN
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('N°', isHeader: true),
            _buildTableCell('NOM', isHeader: true),
            _buildTableCell('MATRICULE', isHeader: true),
            _buildTableCell('MATERIEL', isHeader: true),
            _buildTableCell('DATE', isHeader: true),
            _buildTableCell('HEURE\nCHECKOUT', isHeader: true),
            _buildTableCell('HEURE\nRETOUR', isHeader: true),
            _buildTableCell('ADMIN\nCHECKOUT', isHeader: true),
            _buildTableCell('ADMIN\nRETOUR', isHeader: true),
          ],
        ),
        // Data rows
        ...sortedCheckouts.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final checkout = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('$index'),
              _buildTableCell(checkout.borrowerName),
              _buildTableCell(checkout.borrowerCni),
              _buildTableCell('${checkout.equipmentName}\n(Qté: ${checkout.quantity})'),
              _buildTableCell(_formatDateShort(checkout.checkoutTime)),
              _buildTableCell(checkout.isReturned 
                  ? '${checkout.checkoutTime.hour.toString().padLeft(2, '0')}:${checkout.checkoutTime.minute.toString().padLeft(2, '0')}'
                  : '-'),
              _buildTableCell(checkout.isReturned && checkout.returnTime != null
                  ? '${checkout.returnTime!.hour.toString().padLeft(2, '0')}:${checkout.returnTime!.minute.toString().padLeft(2, '0')}'
                  : '-'),
              _buildTableCell(checkout.userName.isNotEmpty ? checkout.userName : 'System'),
              _buildTableCell(checkout.isReturned ? (checkout.userName.isNotEmpty ? checkout.userName : 'System') : '-'),
            ],
          );
        }),
      ],
    );
  }

  /// Boîte de résumé
  static pw.Widget _buildSummaryBox(
    int totalCheckouts,
    int totalReturns,
    int totalItemsOut,
    int totalItemsReturned,
    PdfColor primaryColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RÉSUMÉ',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Empriunts', '$totalCheckouts', primaryColor),
              _buildSummaryItem('Total Retours', '$totalReturns', PdfColors.green),
              _buildSummaryItem('En Cours', '${totalItemsOut - totalItemsReturned}', PdfColors.blue),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfStatsSection(
    int checkouts,
    int returns,
    int inProgress,
    int itemsOut,
    int itemsReturned,
    PdfColor primaryColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STATISTIQUES DU JOUR',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildPdfStatCard('Emprunts', '$checkouts', primaryColor),
              _buildPdfStatCard('Retours', '$returns', PdfColors.green),
              _buildPdfStatCard('En cours', '$inProgress', PdfColors.blue),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Articles empruntés: $itemsOut',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Articles retournés: $itemsReturned',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfSummarySection(String summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RÉSUMÉ DÉTAILLÉ',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            summary,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEquipmentTable(
    List<EquipmentCheckout> checkouts,
    List<Equipment> equipment,
  ) {
    final activeCheckouts = checkouts.where((c) => !c.isReturned).toList();
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Équipement', isHeader: true),
            _buildTableCell('Emprunteur', isHeader: true),
            _buildTableCell('Salle', isHeader: true),
            _buildTableCell('Qté', isHeader: true),
            _buildTableCell('Heure', isHeader: true),
          ],
        ),
        // Data
        ...activeCheckouts.map((checkout) => pw.TableRow(
          children: [
            _buildTableCell(checkout.equipmentName),
            _buildTableCell(checkout.borrowerName),
            _buildTableCell(checkout.destinationRoom),
            _buildTableCell('${checkout.quantity}'),
            _buildTableCell('${checkout.checkoutTime.hour}:${checkout.checkoutTime.minute.toString().padLeft(2, '0')}'),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfFooter(String generatedBy, DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Généré par: $generatedBy',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Date de génération: ${_formatDateTime(generatedAt)}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sauvegarde le rapport dans le stockage local
  static Future<String> saveReportToFile(File pdfFile, DailyReport report) async {
    final fileName = 'rapport_${_formatDateForFilename(report.date)}.pdf';
    return await FileStorageService.saveReport(pdfFile, fileName);
  }

  /// Liste tous les rapports sauvegardés
  static Future<List<FileSystemEntity>> listSavedReports() async {
    return await FileStorageService.listReports();
  }

  /// Partage le rapport
  static Future<void> shareReport(File pdfFile, DailyReport report) async {
    final fileName = 'rapport_${_formatDateForFilename(report.date)}.pdf';
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Rapport Journalier - ${_formatDateShort(report.date)}',
      text: 'Rapport journalier ManAc du ${_formatDateFrench(report.date)}',
    );
  }

  /// Génère un rapport mensuel
  static Future<File> generateMonthlyReportPdf(
    List<DailyReport> reports,
    int year,
    int month,
  ) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#FF6B35');
    final monthName = _formatMonthYear(DateTime(year, month));

    // Calculer les statistiques mensuelles
    int totalCheckouts = 0;
    int totalReturns = 0;
    int totalItemsOut = 0;
    int totalItemsReturned = 0;

    for (final report in reports) {
      totalCheckouts += report.totalCheckouts;
      totalReturns += report.totalReturns;
      totalItemsOut += report.totalItemsCheckedOut;
      totalItemsReturned += report.totalItemsReturned;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              _buildPdfHeader(primaryColor),
              pw.SizedBox(height: 20),
              
              pw.Center(
                child: pw.Text(
                  'RAPPORT MENSUEL',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              
              pw.Center(
                child: pw.Text(
                  monthName.toUpperCase(),
                  style: const pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Statistiques mensuelles
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STATISTIQUES DU MOIS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildPdfStatCard('$totalCheckouts', 'Emprunts', primaryColor),
                        _buildPdfStatCard('$totalReturns', 'Retours', PdfColors.green),
                        _buildPdfStatCard('${reports.length}', 'Jours rapportés', PdfColors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Liste des rapports journaliers
              pw.Text(
                'RAPPORTS JOURNALIERS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['Date', 'Emprunts', 'Retours', 'Articles en cours'],
                data: reports.map((r) => [
                  _formatDateShort(r.date),
                  '${r.totalCheckouts}',
                  '${r.totalReturns}',
                  '${r.totalItemsCheckedOut - r.totalItemsReturned}',
                ]).toList(),
              ),
              
              pw.Spacer(),
              
              // Pied de page
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Rapport mensuel ManAc',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Généré le: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final fileName = 'rapport_mensuel_${year}_$month.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
}

/// Classe pour transporter les données de rapport
class ReportData {
  final List<EquipmentCheckout> checkouts;
  final List<Equipment> equipment;
  final DateTime startDate;
  final DateTime endDate;

  ReportData({
    required this.checkouts,
    required this.equipment,
    required this.startDate,
    required this.endDate,
  });

  List<EquipmentCheckout> get activeCheckouts => 
      checkouts.where((c) => !c.isReturned).toList();

  List<EquipmentCheckout> get returnedCheckouts => 
      checkouts.where((c) => c.isReturned).toList();

  int get totalItemsOut => 
      checkouts.fold(0, (sum, c) => sum + c.quantity);

  int get totalItemsReturned => 
      returnedCheckouts.fold(0, (sum, c) => sum + c.quantity);
}
