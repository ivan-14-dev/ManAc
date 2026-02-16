// ========================================
// Service de génération de rapports PDF
// Crée des rapports journaliers exportables en PDF
// ========================================

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_report.dart';

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

/// Service pour générer des rapports PDF
class PdfReportService {
  /// Génère un PDF pour un rapport journalier
  static Future<File> generateDailyReportPdf(DailyReport report) async {
    final pdf = pw.Document();
    
    // Valeurs par défaut pour les données manquantes (sécurité supplémentaire)
    final checkouts = report.totalCheckouts;
    final returns = report.totalReturns;
    final itemsOut = report.totalItemsCheckedOut;
    final itemsReturned = report.totalItemsReturned;
    final summary = report.summary.isNotEmpty ? report.summary : 'Aucun résumé disponible';
    final generatedBy = report.generatedBy.isNotEmpty ? report.generatedBy : 'Système';
    final generatedAt = report.generatedAt;
    final date = report.date;

    // Définir les couleurs
    final primaryColor = PdfColor.fromHex('#FF6B35'); // Orange
    final secondaryColor = PdfColor.fromHex('#2196F3'); // Blue

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo
              _buildHeader(primaryColor),
              pw.SizedBox(height: 20),
              
              // Titre du rapport
              pw.Center(
                child: pw.Text(
                  'RAPPORT JOURNALIER',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              
              // Date du rapport
              pw.Center(
                child: pw.Text(
                  _formatDateFrench(date),
                  style: const pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Statistiques principales
              _buildStatsSection(
                checkouts,
                returns,
                itemsOut - itemsReturned,
                itemsOut,
                itemsReturned,
                primaryColor,
                secondaryColor,
              ),
              pw.SizedBox(height: 20),
              
              // Résumé détaillé
              _buildSummarySection(summary),
              pw.SizedBox(height: 20),
              
              // Détails des activités
              _buildActivitiesSection(summary),
              
              // Pied de page
              pw.Spacer(),
              _buildFooter(generatedBy, generatedAt),
            ],
          );
        },
      ),
    );

    // Sauvegarder le PDF
    final output = await getApplicationDocumentsDirectory();
    final fileName = 'rapport_${_formatDateForFilename(date)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  static pw.Widget _buildHeader(PdfColor primaryColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ManAc',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.Text(
              'Gestion de Stock',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: primaryColor.shade(0.1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            '${DateTime.now().year}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatsSection(
    int checkouts,
    int returns,
    int inProgress,
    int itemsOut,
    int itemsReturned,
    PdfColor primaryColor,
    PdfColor secondaryColor,
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
              color: secondaryColor,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Emprunts',
                '$checkouts',
                primaryColor,
              ),
              _buildStatCard(
                'Retours',
                '$returns',
                PdfColors.green,
              ),
              _buildStatCard(
                'En cours',
                '$inProgress',
                secondaryColor,
              ),
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

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
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

  static pw.Widget _buildSummarySection(String summary) {
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
            'RÉSUMÉ',
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

  static pw.Widget _buildActivitiesSection(String summary) {
    // Parser les activités du résumé
    final activities = summary.split('\n').where((s) => s.trim().isNotEmpty).toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAILS DES ACTIVITÉS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        if (activities.isEmpty)
          pw.Text(
            'Aucune activité ce jour',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          )
        else
          pw.Container(
            height: 150,
            child: pw.ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '• ',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.orange,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          activity,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildFooter(String generatedBy, DateTime generatedAt) {
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

  // Pied de page pour le rapport mensuel
  static pw.Widget _buildFooterMonth() {
    final now = DateTime.now();
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
            'Rapport mensuel ManAc',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Généré le: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Partage le rapport PDF
  static Future<void> shareReport(File pdfFile, DailyReport report) async {
    final fileName = 'rapport_${_formatDateForFilename(report.date)}.pdf';
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Rapport Journalier - ${_formatDateShort(report.date)}',
      text: 'Rapport journalier ManAc du ${_formatDateFrench(report.date)}',
    );
  }

  /// Imprime le rapport PDF
  static Future<void> printReport(File pdfFile) async {
    // Note: L'impression nécessite des configurations supplémentaires sur certaines plateformes
    // Pour mobile, on utilise plutôt le partage
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Impression Rapport',
    );
  }

  /// Génère un rapport mensuel en PDF
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
              _buildHeader(primaryColor),
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
                        _buildStatCard('$totalCheckouts', 'Emprunts', primaryColor),
                        _buildStatCard('$totalReturns', 'Retours', PdfColors.green),
                        _buildStatCard('${reports.length}', 'Jours rapportés', PdfColors.blue),
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
              _buildFooterMonth(),
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
