import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rustore_update/flutter_rustore_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../localization/app_localizations.dart';
import 'remote_config_service.dart';

/// Сервис проверки и установки обновлений через RuStore.
///
/// Два уровня обновлений:
/// 1. **Мягкое** — RuStore обнаружил новую версию. Показываем диалог
///    с кнопками «Обновить» / «Позже».
/// 2. **Принудительное** — текущая версия ниже `min_app_version` из
///    Firebase Remote Config. Показываем модальный экран без возможности
///    отказа.
class UpdateService {
  UpdateService._();

  static bool _checking = false;

  /// Вызывать один раз после первого frame (из _HomeSelector).
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_checking || kIsWeb) return;
    _checking = true;

    try {
      // 1. Принудительное обновление через Remote Config
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final forceUpdate =
          await RemoteConfigService.isUpdateRequired(currentVersion);

      if (forceUpdate && context.mounted) {
        _showForceUpdateDialog(context);
        return;
      }

      // 2. Мягкое обновление через RuStore SDK
      if (context.mounted) {
        await _checkRuStoreUpdate(context);
      }
    } catch (e) {
      debugPrint('UpdateService: check failed: $e');
    } finally {
      _checking = false;
    }
  }

  /// Проверка через RuStore In-App Updates SDK.
  static Future<void> _checkRuStoreUpdate(BuildContext context) async {
    try {
      final info = await RustoreUpdateClient.info();
      final availability = info.updateAvailabilityValue;

      if (availability == UpdateAvailability.available && context.mounted) {
        _showSoftUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('UpdateService: RuStore check failed: $e');
    }
  }

  /// Запуск скачивания через RuStore SDK (flexible update).
  static Future<void> _startDownload() async {
    try {
      await RustoreUpdateClient.download();

      // Слушаем статус загрузки
      RustoreUpdateClient.stateStream.listen((response) {
        final status = response.installStatusValue;
        if (status == InstallStatus.downloaded) {
          // Обновление скачано — запускаем установку
          RustoreUpdateClient.completeUpdateFlexible();
        }
      });
    } catch (e) {
      debugPrint('UpdateService: download failed: $e');
    }
  }

  /// Запуск немедленного (принудительного) обновления через RuStore SDK.
  static Future<void> _startImmediateUpdate() async {
    try {
      await RustoreUpdateClient.immediate();
    } catch (e) {
      debugPrint('UpdateService: immediate update failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UI Диалоги
  // ---------------------------------------------------------------------------

  /// Мягкое обновление — можно отказаться.
  static void _showSoftUpdateDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.system_update_rounded,
          size: 48,
          color: Colors.blue[600],
        ),
        title: Text(
          loc.translate('update.available_title'),
          textAlign: TextAlign.center,
        ),
        content: Text(
          loc.translate('update.available_description'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              loc.translate('update.later'),
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startDownload();
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(loc.translate('update.download')),
          ),
        ],
      ),
    );
  }

  /// Принудительное обновление — нельзя закрыть.
  static void _showForceUpdateDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(
            Icons.security_update_warning_rounded,
            size: 48,
            color: Colors.orange[700],
          ),
          title: Text(
            loc.translate('update.required_title'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            loc.translate('update.required_description'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: _startImmediateUpdate,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(loc.translate('update.download_now')),
            ),
          ],
        ),
      ),
    );
  }
}
