import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus, XFile;
import '../../core/localization/app_localizations.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../domain/models/project_v2.dart';
import '../../data/models/calculation.dart';
import '../utils/calculation_display.dart';

/// Сервис для экспорта расчётов в PDF.
class PdfExportService {
  /// Кешированный шрифт Regular для кириллицы.
  static pw.Font? _cachedFontRegular;

  /// Кешированный шрифт Bold для кириллицы.
  static pw.Font? _cachedFontBold;

  /// Загрузить шрифт Regular с поддержкой кириллицы.
  static Future<pw.Font> _loadFont() async {
    if (_cachedFontRegular != null) return _cachedFontRegular!;
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    _cachedFontRegular = pw.Font.ttf(fontData);
    return _cachedFontRegular!;
  }

  /// Загрузить шрифт Bold с поддержкой кириллицы.
  static Future<pw.Font> _loadFontBold() async {
    if (_cachedFontBold != null) return _cachedFontBold!;
    final fontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    _cachedFontBold = pw.Font.ttf(fontData);
    return _cachedFontBold!;
  }

  /// Создать тему с кириллическим шрифтом.
  static Future<pw.ThemeData> _buildTheme() async {
    final fontRegular = await _loadFont();
    final fontBold = await _loadFontBold();
    return pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontRegular,
      boldItalic: fontBold,
    );
  }

  /// Поделиться PDF файлом.
  static Future<void> sharePdf(Uint8List data, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(data);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: fileName));
  }

  /// Сохранить PDF локально и вернуть путь к файлу.
  static Future<String> savePdfLocally(Uint8List data, String fileName) async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Попробуем сохранить во внешнее хранилище (Downloads)
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Переходим в папку Downloads
        final downloadsPath = directory.path.replaceFirst(
          RegExp(r'/Android/data/[^/]+/files'),
          '/Download',
        );
        directory = Directory(downloadsPath);
        // ignore: avoid_slow_async_io
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Windows, macOS, Linux
      directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }

    directory ??= await getApplicationDocumentsDirectory();

    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(data);

    return filePath;
  }

  /// Экспортировать расчёт в PDF.
  ///
  /// [saveLocally] - если true, сохраняет файл локально и возвращает путь.
  /// Если false, открывает диалог печати/шеринга.
  static Future<String?> exportCalculation(
    Calculation calculation,
    CalculatorDefinitionV2? definition, {
    BuildContext? buildContext,
    bool saveLocally = false,
  }) async {
    final theme = await _buildTheme();
    final resolvedDefinition =
        definition ?? CalculatorRegistry.getById(calculation.calculatorId);

    final loc =
        // ignore: use_build_context_synchronously
        buildContext == null ? null : AppLocalizations.of(buildContext);
    final calculatorName = (loc == null || resolvedDefinition == null)
        ? calculation.calculatorName
        : () {
            final translated = loc.translate(resolvedDefinition.titleKey).trim();
            if (translated.isEmpty ||
                translated == resolvedDefinition.titleKey) {
              return calculation.calculatorName;
            }
            return translated;
          }();

    final categoryLabel = buildContext == null
        ? calculation.category
        // ignore: use_build_context_synchronously
        : CalculationDisplay.historyCategoryLabel(buildContext, calculation);
    final pdf = pw.Document(
      theme: theme,
    );

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
                      'Калькулятор: $calculatorName',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Категория: $categoryLabel',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Дата: ${formatDate(calculation.createdAt)}',
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

    final pdfBytes = await pdf.save();

    if (saveLocally) {
      // Генерируем имя файла
      final fileName = 'calculation_${calculation.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await savePdfLocally(pdfBytes, fileName);
      return filePath;
    } else {
      // Показываем диалог печати/сохранения
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
      return null;
    }
  }

  static pw.Widget _buildInputsTable(String inputsJson) {
    try {
      final inputs = parseJson(inputsJson);
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
      final results = parseJson(resultsJson);
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

  @visibleForTesting
  static Map<String, double> parseJson(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (_) {
      return {};
    }
  }

  @visibleForTesting
  static String formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Проверяет, должна ли строка рендерироваться жирной в PDF.
  @visibleForTesting
  static bool isLineBold(String line) {
    return (line == line.toUpperCase() && line.trim().length > 2) ||
        line.startsWith('▸') ||
        line.startsWith('►') ||
        line.startsWith('•');
  }

  // ─────────────────────────────────────────────────────────────────
  // Project Export
  // ─────────────────────────────────────────────────────────────────

  /// Экспортировать проект в PDF.
  ///
  /// [saveLocally] - если true, сохраняет файл локально и возвращает путь.
  /// Если false, открывает диалог печати/шеринга.
  static Future<String?> exportProject(
    ProjectV2 project,
    BuildContext context, {
    bool saveLocally = false,
  }) async {
    final theme = await _buildTheme();
    // ignore: use_build_context_synchronously
    final loc = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final pdf = pw.Document(
      theme: theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context pdfContext) {
          return [
            // Заголовок
            pw.Header(
              level: 0,
              child: pw.Text(
                project.name,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // Адрес
            if (project.address != null && project.address!.isNotEmpty)
              pw.Row(
                children: [
                  pw.Text('📍 ', style: const pw.TextStyle(fontSize: 14)),
                  pw.Text(
                    project.address!,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            pw.SizedBox(height: 20),

            // Информация о проекте
            _buildProjectInfoSection(project, loc, dateFormat),
            pw.SizedBox(height: 20),

            // Статус и прогресс
            _buildStatusSection(project, loc),
            pw.SizedBox(height: 20),

            // Бюджет
            if (project.budgetTotal > 0)
              _buildBudgetSection(project, loc),
            pw.SizedBox(height: 20),

            // Расчёты
            if (project.calculations.isNotEmpty)
              _buildCalculationsSection(project, loc),
            pw.SizedBox(height: 20),

            // Материалы
            if (project.allMaterials.isNotEmpty)
              _buildMaterialsSection(project, loc),

            // Заметки
            if (project.notes != null && project.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text(loc.translate('project.notes'))),
              pw.SizedBox(height: 10),
              pw.Text(
                project.notes!,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ];
        },
        footer: (pw.Context pdfContext) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${loc.translate('app.name')} • ${dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (saveLocally) {
      // Генерируем имя файла из названия проекта
      final sanitizedName = sanitizeFileName(project.name);
      final fileName = 'project_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await savePdfLocally(pdfBytes, fileName);
      return filePath;
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
      return null;
    }
  }

  static pw.Widget _buildProjectInfoSection(
    ProjectV2 project,
    AppLocalizations loc,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${loc.translate('project.created')}: ${dateFormat.format(project.createdAt)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                '${loc.translate('project.updated')}: ${dateFormat.format(project.updatedAt)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          if (project.deadline != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              '${loc.translate('project.dashboard.deadline')}: ${dateFormat.format(project.deadline!)}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: project.isDeadlineOverdue ? PdfColors.red : PdfColors.black,
              ),
            ),
          ],
          if (project.description != null && project.description!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              project.description!,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildStatusSection(ProjectV2 project, AppLocalizations loc) {
    final statusLabel = _getStatusLabel(project.status, loc);
    final statusColor = _getStatusPdfColor(project.status);

    return pw.Row(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: statusColor.shade(50),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Text(
            statusLabel,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${loc.translate('project.dashboard.progress')}: ${project.progressPercent}%',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 4),
              pw.LinearProgressIndicator(
                value: project.progress,
                backgroundColor: PdfColors.grey300,
                valueColor: statusColor,
              ),
              if (project.tasksTotal > 0) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  '${loc.translate('project.dashboard.tasks')}: ${project.tasksCompleted}/${project.tasksTotal}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBudgetSection(ProjectV2 project, AppLocalizations loc) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            loc.translate('project.dashboard.budget'),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    loc.translate('project.dashboard.spent'),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    formatMoney(project.budgetSpent),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: project.isOverBudget ? PdfColors.red : PdfColors.black,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    loc.translate('project.dashboard.remaining'),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    formatMoney(project.budgetRemaining),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: project.budgetRemaining < 0 ? PdfColors.red : PdfColors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.LinearProgressIndicator(
            value: project.budgetUtilization.clamp(0, 1),
            backgroundColor: PdfColors.grey300,
            valueColor: project.isOverBudget ? PdfColors.red : PdfColors.blue,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${loc.translate('project.total')}: ${formatMoney(project.budgetTotal)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCalculationsSection(ProjectV2 project, AppLocalizations loc) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, child: pw.Text(loc.translate('project.calculations'))),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Расчёт',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Стоимость материалов',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Стоимость работ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...project.calculations.map(
              (calc) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(calc.name),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(formatMoney(calc.effectiveMaterialCost)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(formatMoney(calc.laborCost ?? 0)),
                  ),
                ],
              ),
            ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    loc.translate('project.total'),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    formatMoney(project.totalMaterialCost),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    formatMoney(project.totalLaborCost),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMaterialsSection(ProjectV2 project, AppLocalizations loc) {
    final materials = project.allMaterials;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, child: pw.Text(loc.translate('project.materials'))),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Материал',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Кол-во',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Цена',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Сумма',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            ...materials.map(
              (m) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(m.name, style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      '${m.quantity.toStringAsFixed(1)} ${m.unit}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      formatMoney(m.pricePerUnit),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      formatMoney(m.totalCost),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _getStatusLabel(ProjectStatus status, AppLocalizations loc) {
    switch (status) {
      case ProjectStatus.planning:
        return loc.translate('project.status.planning');
      case ProjectStatus.inProgress:
        return loc.translate('project.status.in_progress');
      case ProjectStatus.onHold:
        return loc.translate('project.status.on_hold');
      case ProjectStatus.completed:
        return loc.translate('project.status.completed');
      case ProjectStatus.cancelled:
        return loc.translate('project.status.cancelled');
      case ProjectStatus.problem:
        return loc.translate('project.status.problem');
    }
  }

  static PdfColor _getStatusPdfColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return PdfColors.blue;
      case ProjectStatus.inProgress:
        return PdfColors.orange;
      case ProjectStatus.onHold:
        return PdfColors.grey;
      case ProjectStatus.completed:
        return PdfColors.green;
      case ProjectStatus.cancelled:
        return PdfColors.red;
      case ProjectStatus.problem:
        return PdfColors.deepOrange;
    }
  }

  /// Очистка строки для использования в имени файла.
  /// Сохраняет буквы (включая кириллицу), цифры и дефисы.
  /// Все whitespace (пробелы, табы, переносы) заменяются на подчёркивания.
  @visibleForTesting
  static String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
        .replaceAll(RegExp(r'\s'), '_');
  }

  @visibleForTesting
  static String formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₽';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k ₽';
    }
    return '${amount.toStringAsFixed(0)} ₽';
  }

  // ─────────────────────────────────────────────────────────────────
  // Text-based Export (для калькуляторов через миксины)
  // ─────────────────────────────────────────────────────────────────

  /// Экспортировать результат калькулятора в PDF из текста.
  ///
  /// [title] — заголовок PDF (имя калькулятора).
  /// [text] — текст результата (из generateExportText()).
  /// [saveLocally] — если true, сохраняет локально и возвращает путь.
  static Future<String?> exportFromText({
    required String title,
    required String text,
    bool saveLocally = false,
  }) async {
    final theme = await _buildTheme();
    final pdf = pw.Document(
      theme: theme,
    );

    // Разбиваем текст по строкам для красивого рендера
    final lines = text.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400, height: 1),
            pw.SizedBox(height: 16),
            ...lines.map((line) {
              // Разделители (═══) рендерим как горизонтальную линию
              if (line.startsWith('═') || line.startsWith('─') || line.startsWith('---')) {
                return pw.Divider(color: PdfColors.grey300, height: 12);
              }
              // Пустые строки
              if (line.trim().isEmpty) {
                return pw.SizedBox(height: 8);
              }
              // Жирные заголовки (строки в верхнем регистре или начинающиеся с ▸/►/•)
              return pw.Text(
                line,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: isLineBold(line) ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              );
            }),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Прораб AI • ${formatDate(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (saveLocally) {
      final sanitizedTitle = sanitizeFileName(title);
      final fileName = '${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      return savePdfLocally(pdfBytes, fileName);
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
      return null;
    }
  }
}
