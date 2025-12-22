import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
part 'putty_calculator_screen_state.dart';

// --- Модели данных ---

enum CalculationMode { room, walls }
enum FinishTarget { wallpaper, painting } // Обои или Покраска
enum FinishMaterialType { dryBag, readyBucket } // Сухая смесь или Готовая паста

class Wall {
  String id;
  double length;
  double height;

  Wall({required this.id, this.length = 3.0, this.height = 2.7});
}

class Opening {
  String id;
  double width;
  double height;
  int count;

  Opening({required this.id, this.width = 0.9, this.height = 2.1, this.count = 1});
}

class PuttyResult {
  final double netArea;

  // Стартовая (Базовая) шпатлевка
  final double startWeight;
  final int startBags;

  // Финишная шпатлевка
  final double finishWeight; // или литры
  final int finishPacks;
  final String finishPackNameKey; // unit.bags или unit.buckets

  // Грунтовка
  final double primerVolume;
  final int primerCanisters;

  // Расходники
  final int sandingSheets; // Шлифлисты/Сетки

  PuttyResult({
    required this.netArea,
    required this.startWeight,
    required this.startBags,
    required this.finishWeight,
    required this.finishPacks,
    required this.finishPackNameKey,
    required this.primerVolume,
    required this.primerCanisters,
    required this.sandingSheets,
  });
}

// --- Основной Виджет ---

class PuttyCalculatorScreen extends StatefulWidget {
  const PuttyCalculatorScreen({super.key});

  @override
  PuttyCalculatorScreenState createState() => PuttyCalculatorScreenState();
}
