import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../views/calculator/screed_unified_calculator_screen.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/favorites_provider.dart';
import '../utils/calculator_navigation_helper.dart';
import '../views/calculator/calculator_catalog_screen.dart';
import '../views/favorites/favorite_calculators_screen.dart';
part 'new_home_screen_state.dart';

/// Современный главный экран: поиск (режим), быстрый доступ, часто считают, категории.
class NewHomeScreen extends ConsumerStatefulWidget {
  final void Function(int index)? onTabRequested;

  const NewHomeScreen({super.key, this.onTabRequested});

  @override
  ConsumerState<NewHomeScreen> createState() => _NewHomeScreenState();
}
