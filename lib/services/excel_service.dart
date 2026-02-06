import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'report_service.dart'; // Import for _MonthStat reuse or similar logic? 
// No, ReportService _MonthStat is private. I'll reimplement light aggregation logic here 
// or maybe make _MonthStat public. 
// For now, I'll reimplement to keep services decoupled enough.

class ExcelService {
  Future<List<int>?> generateReport({
    required DateTime start,
    required DateTime end,
    required List<DailySummary> summaries,
    required List<FoodLog> foodLogs,
    required List<WeightLog> weightLogs,
    required Profile? profile,
  }) async {
    final excel = Excel.createExcel();
    
    // 1. Overview Sheet
    _buildOverviewSheet(excel, summaries, weightLogs, profile);
    
    // 2. Food Logs Sheet
    _buildFoodLogsSheet(excel, foodLogs);
    
    // 3. Analysis Sheet
    _buildAnalysisSheet(excel, summaries, weightLogs, profile);

    // Remove default sheet
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1'); 
    }

    return excel.encode();
  }

  Future<List<int>?> generateYearlyReport({
    required int year,
    required List<DailySummary> summaries,
    required List<WeightLog> weightLogs,
    required List<ExerciseLog> exerciseLogs,
    required Profile? profile,
  }) async {
     final excel = Excel.createExcel();
     final sheet = excel['Yearly Summary $year'];

     // Headers
     final headers = [
       'Month', 'Avg Calories', 'Avg Protein (g)', 'Total Exercise (min)', 
       'Start Weight (kg)', 'End Weight (kg)', 'Change (kg)', 'Verdict'
     ];
     sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

     // Group data by month
     for (int month = 1; month <= 12; month++) {
        final monthName = DateFormat('MMMM').format(DateTime(year, month));
        
        // Filter for this month
        final monthSummaries = summaries.where((s) => s.logDate.month == month).toList();
        final monthWeights = weightLogs.where((w) => w.loggedAt.month == month).toList();
        final monthExercise = exerciseLogs.where((e) => e.loggedAt.month == month).toList();

        if (monthSummaries.isEmpty && monthWeights.isEmpty && monthExercise.isEmpty) {
          continue; // Skip empty months
        }

        // Calcs
        double avgCal = 0;
        double avgPro = 0;
        if (monthSummaries.isNotEmpty) {
           avgCal = monthSummaries.map((e) => e.totalCalories).reduce((a, b) => a + b) / monthSummaries.length;
           avgPro = monthSummaries.map((e) => e.totalProteinG).reduce((a, b) => a + b) / monthSummaries.length;
        }

        int totalExercise = 0;
        for (var e in monthExercise) totalExercise += e.durationMinutes;

        double startWt = 0;
        double endWt = 0;
        if (monthWeights.isNotEmpty) {
           monthWeights.sort((a,b) => a.loggedAt.compareTo(b.loggedAt));
           startWt = monthWeights.first.weightKg;
           endWt = monthWeights.last.weightKg;
        }
        
        double change = (startWt > 0 && endWt > 0) ? endWt - startWt : 0;
        String verdict = "Stable";
        if (change < -0.5) verdict = "Loss";
        if (change > 0.5) verdict = "Gain";

        sheet.appendRow([
          TextCellValue(monthName),
          IntCellValue(avgCal.round()),
          IntCellValue(avgPro.round()),
          IntCellValue(totalExercise),
          DoubleCellValue(startWt),
          DoubleCellValue(endWt),
          DoubleCellValue(change),
          TextCellValue(verdict),
        ]);
     }

     // Detailed Sheets
     _buildFoodLogsSheet(excel, []); // Maybe empty for yearly to avoid huge file? Or top foods?
     // Let's add all exercise logs in a separate sheet
     final exSheet = excel['Exercise Log $year'];
     exSheet.appendRow([TextCellValue('Date'), TextCellValue('Activity'), TextCellValue('Duration'), TextCellValue('Calories')]);
     for (var e in exerciseLogs) {
       exSheet.appendRow([
         TextCellValue(e.loggedAt.toIso8601String().split('T')[0]),
         TextCellValue(e.activityName),
         IntCellValue(e.durationMinutes),
         IntCellValue(e.caloriesBurned)
       ]);
     }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1'); 
    }
     return excel.encode();
  }

  void _buildOverviewSheet(Excel excel, List<DailySummary> summaries, List<WeightLog> weightLogs, Profile? profile) {
    final sheet = excel['Daily Overview'];
    
    // Headers
    final headers = [
      'Date', 'Calories', 'Target', 'Status', 
      'Protein (g)', 'Carbs (g)', 'Fat (g)', 'Sugar (g)', 
      'UPF Score', 'Weight (kg)', 'Notes'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // Map weight logs by date for easy lookup
    final weightMap = {
      for (var w in weightLogs) w.loggedAt: w
    };

    // Make sure we cover every day in the range? Or just days with data?
    // Using summaries is safer as it aggregates food data.
    for (final summary in summaries) {
      final date = summary.logDate.toIso8601String().split('T')[0];
      final weight = weightMap[summary.logDate];
      final target = profile?.dailyCalorieTarget ?? 2000;
      final status = summary.totalCalories > target ? 'Over' : 'Under';

      sheet.appendRow([
        TextCellValue(date),
        IntCellValue(summary.totalCalories),
        IntCellValue(target),
        TextCellValue(status),
        DoubleCellValue(summary.totalProteinG),
        DoubleCellValue(summary.totalCarbsG),
        DoubleCellValue(summary.totalFatG),
        DoubleCellValue(summary.totalSugarG),
        IntCellValue(summary.upfScore),
        weight != null ? DoubleCellValue(weight.weightKg) : TextCellValue('-'),
        weight?.notes != null ? TextCellValue(weight!.notes!) : TextCellValue(''),
      ]);
    }
  }

  void _buildFoodLogsSheet(Excel excel, List<FoodLog> logs) {
    if (logs.isEmpty) return; 
    final sheet = excel['Detailed Food Logs'];
    
    sheet.appendRow([
       TextCellValue('Date'), 
       TextCellValue('Time'), 
       TextCellValue('Food Item'), 
       TextCellValue('Brand'), 
       TextCellValue('Calories'), 
       TextCellValue('Protein (g)'), 
       TextCellValue('Carbs (g)'), 
       TextCellValue('Fat (g)')
    ]);

    final timeFormat = DateFormat('HH:mm');

    for (final log in logs) {
      final date = log.loggedAt.toIso8601String().split('T')[0];
      final time = timeFormat.format(log.loggedAt);

      sheet.appendRow([
        TextCellValue(date),
        TextCellValue(time),
        TextCellValue(log.foodName),
        TextCellValue(log.brandName ?? ''),
        IntCellValue(log.calories),
        DoubleCellValue(log.proteinG),
        DoubleCellValue(log.carbsG),
        DoubleCellValue(log.fatG),
      ]);
    }
  }

  void _buildAnalysisSheet(Excel excel, List<DailySummary> summaries, List<WeightLog> weights, Profile? profile) {
    final sheet = excel['Body Analysis'];

    sheet.appendRow([TextCellValue('Body & Nutrition Analysis')]);
    sheet.appendRow([TextCellValue('')]);

    // 1. Averages
    if (summaries.isNotEmpty) {
      final avgCal = summaries.map((e) => e.totalCalories).reduce((a, b) => a + b) / summaries.length;
      final avgPro = summaries.map((e) => e.totalProteinG).reduce((a, b) => a + b) / summaries.length;
      
      sheet.appendRow([TextCellValue('Average Daily Calories'), DoubleCellValue(avgCal)]);
      sheet.appendRow([TextCellValue('Average Protein Intake'), DoubleCellValue(avgPro)]);
    }

    // 2. Weight Trend
    if (weights.length >= 2) {
      weights.sort((a, b) => a.loggedAt.compareTo(b.loggedAt)); // ensure sorted
      final first = weights.first;
      final last = weights.last;
      final change = last.weightKg - first.weightKg;
      
      sheet.appendRow([TextCellValue('Weight Change'), DoubleCellValue(change), TextCellValue('kg')]);
      sheet.appendRow([TextCellValue('Trend'), TextCellValue(change < 0 ? 'Improving (Weight Loss)' : 'Gaining')]);
    }

    // 3. Protein Correlation (Simple)
    // simplistic logic: find days with high protein and see if weight next day was lower? 
    // Or just general correlation.
    // For MVP, just output text.
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('Insights:')]);
    sheet.appendRow([TextCellValue('consistent calorie deficit is key to weight loss.')]);
    if (profile != null && profile.goal == 'muscle_gain') {
       sheet.appendRow([TextCellValue('Ensure you are hitting your protein target of ${profile.proteinTargetG}g daily.')]);
    }
  }
}
