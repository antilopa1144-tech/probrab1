import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/models/shareable_content.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/localization/app_localizations.dart';

/// Экран для генерации и шаринга QR кода калькулятора
class CalculatorQrShareScreen extends StatefulWidget {
  final ShareableCalculator calculator;
  final String? calculatorDisplayName;

  const CalculatorQrShareScreen({
    super.key,
    required this.calculator,
    this.calculatorDisplayName,
  });

  @override
  State<CalculatorQrShareScreen> createState() =>
      _CalculatorQrShareScreenState();
}

class _CalculatorQrShareScreenState extends State<CalculatorQrShareScreen> {
  late String _deepLink;
  bool _useCompactFormat = true;

  @override
  void initState() {
    super.initState();
    _updateDeepLink();
  }

  void _updateDeepLink() {
    setState(() {
      _deepLink = DeepLinkService.instance.createCalculatorLink(
        widget.calculator,
        compact: _useCompactFormat,
      );
    });
  }

  String _getDisplayName(AppLocalizations loc) =>
      widget.calculatorDisplayName ??
      widget.calculator.calculatorName ??
      loc.translate('share.qr.default_calculator');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final displayName = _getDisplayName(loc);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('share.qr.title')),
        actions: [
          IconButton(
            onPressed: () => _shareLink(loc, displayName),
            icon: const Icon(Icons.share_rounded),
            tooltip: loc.translate('share.qr.share_link'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Название калькулятора
            Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('share.qr.prefilled_data'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // QR код
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _deepLink,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                embeddedImage: const AssetImage('assets/icons/app_icon.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(48, 48),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Информация о входных данных
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.input_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('share.qr.entered_data'),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.calculator.inputs.isEmpty)
                      Text(
                        loc.translate('share.qr.no_data'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...widget.calculator.inputs.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatInputName(entry.key, loc),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Text(
                                _formatInputValue(entry.value),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Переключатель формата
            SwitchListTile(
              value: _useCompactFormat,
              onChanged: (value) {
                setState(() {
                  _useCompactFormat = value;
                  _updateDeepLink();
                });
              },
              title: Text(loc.translate('share.qr.compact_qr')),
              subtitle: Text(loc.translate('share.qr.compact_qr_hint')),
            ),

            const SizedBox(height: 16),

            // Ссылка
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('share.qr.direct_link'),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _deepLink,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _copyLink(loc),
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(loc.translate('share.qr.copy_link')),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Инструкция
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('share.qr.how_to_share'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.translate('share.qr.instructions'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Known input parameter keys for localization
  static const _knownInputKeys = <String>[
    'area', 'length', 'width', 'height', 'layers', 'count', 'depth',
    'thickness', 'perimeter', 'roomArea', 'wallArea', 'ceilingArea',
    'floorArea', 'reserve', 'reservePercent', 'pricePerUnit', 'ceilingType',
    'gypsumType', 'brickType', 'mortarThickness', 'wallType', 'brickLength',
    'brickWidth', 'brickHeight', 'tileWidth', 'tileHeight', 'tileLength',
    'seamWidth', 'groutWidth', 'roomCount', 'socketCount', 'switchCount',
    'lightCount', 'cableLength', 'plasterThickness', 'puttyThickness',
    'layerThickness', 'rollWidth', 'rollLength', 'patternRepeat',
    'paintConsumption', 'coatsCount', 'boardWidth', 'boardLength',
    'boardThickness', 'doorWidth', 'doorHeight', 'windowWidth', 'windowHeight',
    'windowCount', 'doorCount', 'price', 'quantity', 'total', 'step',
    'spacing', 'overlap',
  ];

  String _formatInputName(String key, AppLocalizations loc) {
    // Check for known key (direct or case-insensitive)
    final lowerKey = key.toLowerCase();
    for (final knownKey in _knownInputKeys) {
      if (knownKey == key || knownKey.toLowerCase() == lowerKey) {
        return loc.translate('share.input_params.$knownKey');
      }
    }

    // Fallback: format camelCase to readable text
    final formatted = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)!.toLowerCase()}',
    );
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _formatInputValue(double value) {
    // Remove trailing zeros
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _copyLink(AppLocalizations loc) async {
    await Clipboard.setData(ClipboardData(text: _deepLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('share.qr.link_copied')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareLink(AppLocalizations loc, String displayName) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${loc.translate('share.qr.calculation', {'name': displayName})}\n\n'
            '${loc.translate('share.qr.open_in_app')}\n'
            '$_deepLink',
        subject: loc.translate('share.qr.calculation', {'name': displayName}),
      ),
    );
  }
}
