import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/calculation.dart';
import '../../domain/entities/object_type.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../components/mat_card.dart';
import '../providers/calculation_provider.dart';
import '../providers/favorites_provider.dart';
import '../views/history_page.dart';
import '../utils/calculator_navigation_helper.dart';
import '../utils/calculation_display.dart';
import '../views/workflow/workflow_planner_screen.dart';
import '../views/reminders/reminders_screen.dart';
import '../views/settings_page.dart';
import '../../core/animations/page_transitions.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/localization/app_localizations.dart';
import '../data/work_catalog.dart';
import 'category_selector_screen.dart';
part 'home_main_state.dart';

/// Обновлённый главный экран: категории объектов + поиск + история.
class HomeMainScreen extends ConsumerStatefulWidget {
  const HomeMainScreen({super.key});

  @override
  ConsumerState<HomeMainScreen> createState() => _HomeMainScreenState();
}
