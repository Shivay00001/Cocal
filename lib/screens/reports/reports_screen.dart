import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../helpers/download_helper.dart';
import '../../helpers/download_helper_mobile.dart' as mobile;
import '../../services/excel_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Reports'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'excel') {
                _downloadExcelReport(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'excel',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, size: 20),
                    const SizedBox(width: 8),
                    const Text('Export to Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isPremium ? _buildReportsList(context, ref) : _buildUpgradePrompt(context),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock, size: 64, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Text('Weekly Reports', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Get detailed PDF reports with:\n• Calorie vs target analysis\n• Weight trend graphs\n• Macro breakdown\n• Personalized recommendations',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/premium'),
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Pro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard(
          context,
          ref,
          title: 'Today\'s Report',
          subtitle: DateFormat('MMM d, yyyy').format(DateTime.now()),
          start: DateTime.now(),
          end: DateTime.now(),
          isToday: true,
        ),
        const SizedBox(height: 20),
        const Text('Weekly Archives', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildWeekCard(context, ref, 1),
        const SizedBox(height: 12),
        _buildWeekCard(context, ref, 2),
        const SizedBox(height: 12),
        _buildWeekCard(context, ref, 3),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required DateTime start,
    required DateTime end,
    bool isToday = false,
  }) {
    return InkWell(
      onTap: isToday ? () => _downloadReport(context, ref, start, end, 'Today') : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isToday ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5)) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isToday ? Icons.today : Icons.date_range, color: AppTheme.primary),
          ),
          title: Text(title, style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(subtitle),
          trailing: isToday
              ? const Icon(Icons.download, color: AppTheme.primary)
              : const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildWeekCard(BuildContext context, WidgetRef ref, int weeksAgo) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + weeksAgo * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekStartStr = DateFormat('MMM d').format(weekStart);
    final weekEndStr = DateFormat('MMM d').format(weekEnd);

    return InkWell(
      onTap: () => _downloadReport(context, ref, weekStart, weekEnd, 'Week$weeksAgo'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.date_range, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weeksAgo == 1 ? 'This Week' : '${weeksAgo == 2 ? 'Last Week' : '$weeksAgo Weeks Ago'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('$weekStartStr - $weekEndStr', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.download, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReport(
    BuildContext context,
    WidgetRef ref,
    DateTime start,
    DateTime end,
    String fileName,
  ) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Generating report...')),
      );

      final reportService = ref.read(reportServiceProvider);
      final profile = ref.read(profileProvider);
      
      final foodService = ref.read(foodServiceProvider);
      final weightLogs = await foodService.getWeightLogs();
      
      Uint8List pdfBytes;
      try {
        pdfBytes = await reportService.generateReport(
          start,
          end,
          profile.asData?.value,
          foodLogs: [],
          weightLogs: weightLogs,
          exerciseLogs: [],
        );
      } catch (e) {
        pdfBytes = await reportService.generateReport(
          start,
          end,
          profile.asData?.value,
          foodLogs: [],
          weightLogs: weightLogs,
          exerciseLogs: [],
        );
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(start);
      await mobile.saveFile(
        'CoCal_Report_${fileName}_$dateStr.pdf',
        pdfBytes,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Report downloaded!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _downloadExcelReport(BuildContext context, WidgetRef ref) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Generating Excel report...')),
      );

      final excelService = ExcelService();
      final profile = ref.read(profileProvider).value;
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final foodService = ref.read(foodServiceProvider);
      final foodLogs = await foodService.getFoodLogsRange(weekStart, weekEnd);
      final weightLogs = await foodService.getWeightLogsRange(weekStart, weekEnd);
      final exerciseService = ref.read(exerciseServiceProvider);
      final exerciseLogs = await exerciseService.getExerciseLogsRange(weekStart, weekEnd);

      final summaries = await foodService.getDailySummariesRange(weekStart, weekEnd);

      final excelBytes = await excelService.generateReport(
        start: weekStart,
        end: weekEnd,
        summaries: summaries,
        foodLogs: foodLogs,
        weightLogs: weightLogs,
        profile: profile,
      );

      if (excelBytes != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(weekStart);
        await mobile.saveFile(
          'CoCal_Report_$dateStr.xlsx',
          Uint8List.fromList(excelBytes),
        );

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Excel report downloaded!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
