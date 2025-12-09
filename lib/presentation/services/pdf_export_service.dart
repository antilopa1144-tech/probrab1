import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../data/models/calculation.dart';

/// Сервис для экспорта расчётов в PDF.
class PdfExportService {
  /// Экспортировать расчёт в PDF.
  static Future<void> exportCalculation(
    Calculation calculation,
    CalculatorDefinitionV2? definition,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Заголовок
            pw.Header(
              level: 0,
              child: pw.Text(
                calculation.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Информация о расчёте
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Калькулятор: ${calculation.calculatorName}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Категория: ${calculation.category}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Дата: ${_formatDate(calculation.createdAt)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                // Цены временно скрыты до интеграции с магазинами
                // pw.Column(
                //   crossAxisAlignment: pw.CrossAxisAlignment.end,
                //   children: [
                //     pw.Text(
                //       'Общая стоимость:',
                //       style: const pw.TextStyle(fontSize: 12),
                //     ),
                //     pw.SizedBox(height: 4),
                //     pw.Text(
                //       '${calculation.totalCost.toStringAsFixed(0)} ₽',
                //       style: pw.TextStyle(
                //         fontSize: 20,
                //         fontWeight: pw.FontWeight.bold,
                //         color: PdfColors.blue700,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Входные данные
            pw.Header(level: 1, child: pw.Text('Входные данные')),
            pw.SizedBox(height: 10),
            _buildInputsTable(calculation.inputsJson),
            pw.SizedBox(height: 20),

            // Результаты
            pw.Header(level: 1, child: pw.Text('Результаты расчёта')),
            pw.SizedBox(height: 10),
            _buildResultsTable(calculation.resultsJson),
            pw.SizedBox(height: 20),

            // Заметки
            if (calculation.notes != null && calculation.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('Заметки')),
              pw.SizedBox(height: 10),
              pw.Text(
                calculation.notes!,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ];
        },
      ),
    );

    // Показываем диалог печати/сохранения
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildInputsTable(String inputsJson) {
    try {
      final inputs = _parseJson(inputsJson);
      if (inputs.isEmpty) {
        return pw.Text('Нет данных');
      }

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Параметр',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Значение',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          ...inputs.entries.map(
            (entry) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.value.toStringAsFixed(2)),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (_) {
      return pw.Text('Ошибка форматирования данных');
    }
  }

  static pw.Widget _buildResultsTable(String resultsJson) {
    try {
      final results = _parseJson(resultsJson);
      if (results.isEmpty) {
        return pw.Text('Нет данных');
      }

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Результат',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Значение',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          ...results.entries.map(
            (entry) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.value.toStringAsFixed(2)),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (_) {
      return pw.Text('Ошибка форматирования данных');
    }
  }

  static Map<String, double> _parseJson(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (_) {
      return {};
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
