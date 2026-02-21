import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../providers/equipment_provider.dart';
import '../models/daily_report.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_report_service.dart';
import '../services/report_service.dart';

// Fonctions helper pour formater les dates en français
String _formatDateFrench(DateTime date) {
  const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
  const days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  final dayName = days[date.weekday - 1];
  final monthName = months[date.month - 1];
  return '$dayName ${date.day} $monthName ${date.year}';
}

String _formatMonthYear(DateTime date) {
  const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
  return '${months[date.month - 1]} ${date.year}';
}

String _formatDayWeek(DateTime date) {
  const days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  return '${days[date.weekday - 1]} ${date.day}';
}

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  bool _isGenerating = false;
  DateTime _selectedMonth = DateTime.now();
  bool _useRealData = true; // Par défaut, utiliser les données réelles

  @override
  void initState() {
    super.initState();
    _checkDailyReportTime();
  }

  Future<void> _checkDailyReportTime() async {
    // Check if daily report has been generated today
    final todayReport = await LocalStorageService.getDailyReportByDate(DateTime.now());
    if (todayReport == null) {
      // Check if it's 17:00 or later
      final now = DateTime.now();
      if (now.hour >= 17) {
        // Auto-generate daily report
        _generateDailyReport();
      }
    }
  }

  Future<void> _generateDailyReport() async {
    setState(() => _isGenerating = true);

    try {
      final equipmentProvider = context.read<EquipmentProvider>();
      
      if (_useRealData) {
        // Générer avec les données réelles (Firebase + Local)
        await ReportService.generateDailyReportWithRealData(
          date: DateTime.now(),
          userName: 'System',
        );
      } else {
        // Générer avec les données locales uniquement
        await equipmentProvider.generateDailyReport();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport journalier généré avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de la génération du rapport: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showReportDetails(DailyReport report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rapport Journalier',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _formatDateFrench(report.date),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportSection('RÉSUMÉ', [
                        _buildReportRow('Total Checkouts', '${report.totalCheckouts}'),
                        _buildReportRow('Total Returns', '${report.totalReturns}'),
                        _buildReportRow('Items Checked Out', '${report.totalItemsCheckedOut}'),
                        _buildReportRow('Items Returned', '${report.totalItemsReturned}'),
                        const SizedBox(height: 8),
                        _buildReportRow('Generated By', report.generatedBy),
                        _buildReportRow('Generated At', report.generatedAt.toString().split('.')[0]),
                      ]),
                      const SizedBox(height: 16),
                      const Text(
                        'RÉSUMÉ DÉTAILLÉ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(report.summary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _exportReport(report);
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('EXPORTER EN PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _exportReport(DailyReport report) async {
    // Afficher un menu pour choisir l'action
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Exporter le rapport',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Générer PDF'),
              subtitle: const Text('Créer un fichier PDF du rapport'),
              onTap: () {
                Navigator.pop(context);
                _generateAndExportPdf(report);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save, color: Colors.blue),
              title: const Text('Sauvegarder en fichier'),
              subtitle: const Text('Enregistrer le rapport localement'),
              onTap: () {
                Navigator.pop(context);
                _saveReportToFile(report);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.green),
              title: const Text('Générer et sauvegarder'),
              subtitle: const Text('Créer PDF et l\'enregistrer'),
              onTap: () {
                Navigator.pop(context);
                _generateAndSavePdf(report);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndExportPdf(DailyReport report) async {
    try {
      setState(() => _isGenerating = true);
      
      // Générer le PDF
      final pdfFile = await PdfReportService.generateDailyReportPdf(report);
      
      // Partager le PDF
      await PdfReportService.shareReport(pdfFile, report);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport exporté avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveReportToFile(DailyReport report) async {
    try {
      setState(() => _isGenerating = true);
      
      // Générer le PDF
      final pdfFile = await PdfReportService.generateDailyReportPdf(report);
      
      // Sauvegarder le fichier
      final savedPath = await ReportService.saveReportToFile(pdfFile, report);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport sauvegardé: $savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateAndSavePdf(DailyReport report) async {
    try {
      setState(() => _isGenerating = true);
      
      // Obtenir les données réelles pour un rapport complet
      final data = await ReportService.getRealTimeData(
        startDate: report.date,
        endDate: report.date.add(const Duration(days: 1)),
      );
      
      // Générer un rapport complet avec les données réelles
      final pdfFile = await ReportService.generateCompletePdfReport(
        report: report,
        checkouts: data.checkouts,
        equipment: data.equipment,
      );
      
      // Sauvegarder le fichier
      final savedPath = await ReportService.saveReportToFile(pdfFile, report);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport complet sauvegardé: $savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  List<DailyReport> _getMonthlyReports(int year, int month) {
    return LocalStorageService.getDailyReportsByMonth(year, month);
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final monthlyReports = _getMonthlyReports(_selectedMonth.year, _selectedMonth.month);

    return Column(
      children: [
        // Today's Report Status
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Toggle pour données réelles
              Card(
                color: _useRealData ? Colors.green[50] : Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _useRealData ? Icons.cloud_done : Icons.storage,
                        color: _useRealData ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _useRealData ? 'Données en temps réel' : 'Données locales uniquement',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _useRealData ? Colors.green[800] : Colors.grey[800],
                              ),
                            ),
                            Text(
                              _useRealData ? 'Synchronisation Firebase active' : 'Utilisation des données en cache',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useRealData,
                        onChanged: (value) {
                          setState(() => _useRealData = value);
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Report status card
              FutureBuilder<DailyReport?>(
            future: equipmentProvider.getTodayReport(),
            builder: (context, snapshot) {
              final todayReport = snapshot.data;
              return Card(
                color: todayReport != null ? Colors.green[50] : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        todayReport != null ? Icons.check_circle : Icons.schedule,
                        color: todayReport != null ? Colors.green : Colors.orange,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayReport != null ? 'Rapport généré' : 'Rapport non généré',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: todayReport != null ? Colors.green[800] : Colors.orange[800],
                              ),
                            ),
                            Text(
                              todayReport != null
                                  ? 'Generated at ${todayReport.generatedAt.hour}:${todayReport.generatedAt.minute.toString().padLeft(2, '0')}'
                                  : 'Will be generated automatically at 17:00',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (todayReport == null)
                        ElevatedButton(
                          onPressed: _isGenerating ? null : _generateDailyReport,
                          child: _isGenerating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('GENERATE NOW'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        ),
        ),

        // Month Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              Expanded(
                child: Text(
                  _formatMonthYear(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Monthly Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${monthlyReports.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Rapports',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${monthlyReports.fold(0, (sum, r) => sum + r.totalCheckouts)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'Emprunts',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${monthlyReports.fold(0, (sum, r) => sum + r.totalReturns)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Retours',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Reports List
        Expanded(
          child: monthlyReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assessment,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun rapport pour ${_formatMonthYear(_selectedMonth)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: monthlyReports.length,
                  itemBuilder: (context, index) {
                    final report = monthlyReports[index];
                    return _buildReportCard(context, report);
                  },
                ),
        ),

        // Bouton pour voir les rapports sauvegardés
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSavedReports(),
              icon: const Icon(Icons.folder),
              label: const Text('VOIR LES RAPPORTS SAUVEGARDÉS'),
            ),
          ),
        ),
      ],
    );
  }

  void _showSavedReports() async {
    final savedReports = await ReportService.listSavedReports();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rapports sauvegardés',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (savedReports.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun rapport sauvegardé',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Générez un rapport et sauvegardez-le',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: savedReports.length,
                    itemBuilder: (context, index) {
                      final file = savedReports[index];
                      final fileName = file.path.split('/').last;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(fileName),
                          subtitle: Text(file.path),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.blue),
                                onPressed: () async {
                                  await Share.shareXFiles([XFile(file.path)]);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await file.delete();
                                  Navigator.pop(context);
                                  _showSavedReports(); // Refresh
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, DailyReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assessment, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDayWeek(report.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge('${report.totalCheckouts} emprunts', Colors.orange),
                        const SizedBox(width: 8),
                        _buildBadge('${report.totalReturns} retours', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
