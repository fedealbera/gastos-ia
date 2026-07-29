import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../features/expenses/domain/entities/expense.dart';

class ExportHelper {
  static Future<void> exportExpensesToExcel({
    required List<Expense> expenses,
    required String periodTitle,
  }) async {
    final excel = Excel.createExcel();
    
    // Rename default sheet to Resumen
    excel.rename('Sheet1', 'Resumen');
    final Sheet summarySheet = excel['Resumen'];
    
    // Sheet 1: Resumen
    // Add title
    summarySheet.appendRow([
      TextCellValue('INFORME DE GASTOS - GASTOS IA'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Período: $periodTitle'),
    ]);
    summarySheet.appendRow([]); // Empty row
    
    // Headers for summary
    summarySheet.appendRow([
      TextCellValue('Categoría'),
      TextCellValue('Total Gastado (\$)'),
    ]);
    
    // Calculate category summary
    final Map<String, double> categoryTotals = {};
    double totalSpent = 0.0;
    for (final exp in expenses) {
      categoryTotals[exp.categoryName] = (categoryTotals[exp.categoryName] ?? 0.0) + exp.amount;
      totalSpent += exp.amount;
    }
    
    categoryTotals.forEach((categoryName, amount) {
      summarySheet.appendRow([
        TextCellValue(categoryName),
        DoubleCellValue(amount),
      ]);
    });
    
    summarySheet.appendRow([]); // Empty row
    summarySheet.appendRow([
      TextCellValue('TOTAL GENERAL'),
      DoubleCellValue(totalSpent),
    ]);
    
    // Sheet 2: Detalle de Gastos
    final Sheet detailSheet = excel['Detalle de Gastos'];
    
    // Title
    detailSheet.appendRow([
      TextCellValue('DETALLE DE TRANSACCIONES POR CATEGORÍA'),
    ]);
    detailSheet.appendRow([
      TextCellValue('Período: $periodTitle'),
    ]);
    detailSheet.appendRow([]);
    
    // Group expenses by category
    final Map<String, List<Expense>> groupedExpenses = {};
    for (final exp in expenses) {
      groupedExpenses.putIfAbsent(exp.categoryName, () => []).add(exp);
    }
    
    // Sort categories alphabetically
    final sortedCategoryNames = groupedExpenses.keys.toList()..sort();
    
    for (final categoryName in sortedCategoryNames) {
      final categoryExpenses = groupedExpenses[categoryName]!;
      categoryExpenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      
      // Header for this category section
      detailSheet.appendRow([
        TextCellValue('CATEGORÍA: ${categoryName.toUpperCase()}'),
      ]);
      
      // Column Headers
      detailSheet.appendRow([
        TextCellValue('Fecha'),
        TextCellValue('Descripción'),
        TextCellValue('Monto (\$)'),
      ]);
      
      double categorySum = 0.0;
      for (final exp in categoryExpenses) {
        final dateStr = DateFormat('dd/MM/yyyy').format(exp.expenseDate);
        final desc = exp.description?.isNotEmpty == true ? exp.description! : exp.categoryName;
        detailSheet.appendRow([
          TextCellValue(dateStr),
          TextCellValue(desc),
          DoubleCellValue(exp.amount),
        ]);
        categorySum += exp.amount;
      }
      
      // Subtotal for the category
      detailSheet.appendRow([
        TextCellValue('Total $categoryName'),
        TextCellValue(''),
        DoubleCellValue(categorySum),
      ]);
      
      detailSheet.appendRow([]); // Spacing row
    }
    
    // Save excel file
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final tempDir = await getTemporaryDirectory();
      
      // Clean period title for file name
      final cleanTitle = periodTitle.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
      final filePath = '${tempDir.path}/reporte_gastos_$cleanTitle.xlsx';
      
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Reporte de Gastos - $periodTitle',
        text: 'Aquí tienes el reporte de gastos para el período: $periodTitle',
      );
    }
  }
}
