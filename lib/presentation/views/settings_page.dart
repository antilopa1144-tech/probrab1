import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/accent_color_provider.dart';
import '../providers/review_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/region_provider.dart';
import '../../core/constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/tracker_service_web.dart'
    if (dart.library.io) '../../core/services/tracker_service.dart';
part 'settings_page_state.dart';

/// Расширенная страница настроек.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}
