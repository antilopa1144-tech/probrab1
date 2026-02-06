// ignore_for_file: avoid_print, unintended_html_in_doc_comment

/// Скрипт генерации changelog для пользователей.
///
/// Парсит git коммиты с conventional commits и генерирует
/// человекочитаемый changelog на русском языке.
///
/// Использование: dart run scripts/generate_changelog.dart
///
/// Опции:
///   --since <tag>    Начать с указанного тега (по умолчанию последний тег)
///   --output <path>  Путь для сохранения (по умолчанию CHANGELOG.md)
///   --unreleased     Включить нерелизнутые изменения
///   --json           Вывод в JSON формате
library;

import 'dart:io';

void main(List<String> args) async {
  final sinceIndex = args.indexOf('--since');
  final sinceTag = sinceIndex != -1 && args.length > sinceIndex + 1 ? args[sinceIndex + 1] : null;

  final outputIndex = args.indexOf('--output');
  final outputPath = outputIndex != -1 && args.length > outputIndex + 1
      ? args[outputIndex + 1]
      : 'CHANGELOG.md';

  final includeUnreleased = args.contains('--unreleased');
  final jsonOutput = args.contains('--json');

  if (!jsonOutput) {
    print('📝 Генерация changelog...\n');
  }

  // 1. Получаем теги
  final tagsResult = Process.runSync('git', ['tag', '--sort=-version:refname']);
  final tags = (tagsResult.stdout as String)
      .split('\n')
      .where((t) => t.trim().isNotEmpty)
      .where((t) => t.startsWith('v'))
      .toList();

  if (!jsonOutput) {
    print('Найдено тегов: ${tags.length}');
  }

  // 2. Определяем диапазон
  String? fromRef = sinceTag;
  if (fromRef == null && tags.isNotEmpty) {
    fromRef = tags.first;
  }

  // 3. Получаем коммиты
  final commits = <Commit>[];

  // Если тегов нет — берём все коммиты как "Unreleased"
  if (tags.isEmpty) {
    final allCommits = _getCommits('HEAD');
    for (final commit in allCommits) {
      commit.version = 'Unreleased';
      commit.versionDate = DateTime.now().toIso8601String().split('T').first;
    }
    commits.addAll(allCommits);
  } else {
    if (includeUnreleased) {
      // Коммиты после последнего тега
      final unreleasedCommits = _getCommits('${tags.first}..HEAD');
      for (final commit in unreleasedCommits) {
        commit.version = 'Unreleased';
      }
      commits.addAll(unreleasedCommits);
    }

    // Коммиты между тегами
    for (var i = 0; i < tags.length; i++) {
      final currentTag = tags[i];
      final previousTag = i + 1 < tags.length ? tags[i + 1] : null;

      final range = previousTag != null ? '$previousTag..$currentTag' : currentTag;
      final tagCommits = _getCommits(range);

      // Получаем дату тега
      final dateResult = Process.runSync('git', ['log', '-1', '--format=%ci', currentTag]);
      final tagDate = (dateResult.stdout as String).trim().split(' ').first;

      for (final commit in tagCommits) {
        commit.version = currentTag;
        commit.versionDate = tagDate;
      }
      commits.addAll(tagCommits);

      // Если указан --since, останавливаемся
      if (sinceTag != null && currentTag == sinceTag) break;
    }
  }

  if (!jsonOutput) {
    print('Коммитов для анализа: ${commits.length}');
  }

  // 4. Группируем по версиям и типам
  final grouped = <String, VersionChanges>{};
  for (final commit in commits) {
    final version = commit.version ?? 'Unknown';
    grouped.putIfAbsent(
        version,
        () => VersionChanges(
              version: version,
              date: commit.versionDate ?? '',
            ));
    grouped[version]!.addCommit(commit);
  }

  // 5. Генерируем вывод
  if (jsonOutput) {
    _printJson(grouped);
  } else {
    final changelog = _generateMarkdown(grouped);
    File(outputPath).writeAsStringSync(changelog);
    print('\n✅ Changelog сохранён в: $outputPath');
    print('   Версий: ${grouped.length}');
    print('   Коммитов: ${commits.length}');
  }
}

List<Commit> _getCommits(String range) {
  final result = Process.runSync(
    'git',
    ['log', range, '--format=%H|%s|%an|%ci'],
  );

  final lines = (result.stdout as String).split('\n').where((l) => l.trim().isNotEmpty);
  final commits = <Commit>[];

  for (final line in lines) {
    final parts = line.split('|');
    if (parts.length >= 4) {
      commits.add(Commit(
        hash: parts[0],
        message: parts[1],
        author: parts[2],
        date: parts[3].split(' ').first,
      ));
    }
  }

  return commits;
}

String _generateMarkdown(Map<String, VersionChanges> grouped) {
  final buffer = StringBuffer();

  buffer.writeln('# История изменений');
  buffer.writeln();
  buffer.writeln('Все заметные изменения в проекте документируются в этом файле.');
  buffer.writeln();
  buffer.writeln(
      'Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),');
  buffer.writeln(
      'и проект придерживается [Семантического версионирования](https://semver.org/lang/ru/).');
  buffer.writeln();

  for (final entry in grouped.entries) {
    final changes = entry.value;
    final versionHeader =
        changes.date.isNotEmpty ? '${changes.version} (${changes.date})' : changes.version;

    buffer.writeln('## [$versionHeader]');
    buffer.writeln();

    if (changes.features.isNotEmpty) {
      buffer.writeln('### ✨ Новое');
      buffer.writeln();
      for (final commit in changes.features) {
        buffer.writeln('- ${commit.description}');
      }
      buffer.writeln();
    }

    if (changes.fixes.isNotEmpty) {
      buffer.writeln('### 🐛 Исправления');
      buffer.writeln();
      for (final commit in changes.fixes) {
        buffer.writeln('- ${commit.description}');
      }
      buffer.writeln();
    }

    if (changes.improvements.isNotEmpty) {
      buffer.writeln('### ⚡ Улучшения');
      buffer.writeln();
      for (final commit in changes.improvements) {
        buffer.writeln('- ${commit.description}');
      }
      buffer.writeln();
    }

    if (changes.docs.isNotEmpty) {
      buffer.writeln('### 📚 Документация');
      buffer.writeln();
      for (final commit in changes.docs) {
        buffer.writeln('- ${commit.description}');
      }
      buffer.writeln();
    }

    if (changes.tests.isNotEmpty) {
      buffer.writeln('### 🧪 Тесты');
      buffer.writeln();
      for (final commit in changes.tests) {
        buffer.writeln('- ${commit.description}');
      }
      buffer.writeln();
    }

    if (changes.chores.isNotEmpty) {
      buffer.writeln('### 🔧 Техническое');
      buffer.writeln();
      for (final commit in changes.chores) {
        buffer.writeln('- ${commit.description}');
      }
      buffer.writeln();
    }

    if (changes.breaking.isNotEmpty) {
      buffer.writeln('### ⚠️ BREAKING CHANGES');
      buffer.writeln();
      for (final commit in changes.breaking) {
        buffer.writeln('- ${commit.description}');
      }
      buffer.writeln();
    }

    if (changes.other.isNotEmpty) {
      buffer.writeln('### 📦 Другое');
      buffer.writeln();
      for (final commit in changes.other) {
        buffer.writeln('- ${commit.message}');
      }
      buffer.writeln();
    }
  }

  return buffer.toString();
}

void _printJson(Map<String, VersionChanges> grouped) {
  final versions = grouped.values.map((v) {
    return {
      'version': v.version,
      'date': v.date,
      'features': v.features.map((c) => c.description).toList(),
      'fixes': v.fixes.map((c) => c.description).toList(),
      'improvements': v.improvements.map((c) => c.description).toList(),
      'docs': v.docs.map((c) => c.description).toList(),
      'tests': v.tests.map((c) => c.description).toList(),
      'chores': v.chores.map((c) => c.description).toList(),
      'breaking': v.breaking.map((c) => c.description).toList(),
      'other': v.other.map((c) => c.message).toList(),
    };
  }).toList();

  // Простой JSON вывод
  print('[');
  for (var i = 0; i < versions.length; i++) {
    final v = versions[i];
    print('  {');
    print('    "version": "${v['version']}",');
    print('    "date": "${v['date']}",');
    print('    "features": ${_listToJson(v['features'] as List)},');
    print('    "fixes": ${_listToJson(v['fixes'] as List)},');
    print('    "improvements": ${_listToJson(v['improvements'] as List)},');
    print('    "breaking": ${_listToJson(v['breaking'] as List)}');
    print('  }${i < versions.length - 1 ? ',' : ''}');
  }
  print(']');
}

String _listToJson(List items) {
  if (items.isEmpty) return '[]';
  final escaped = items.map((i) => '"${i.toString().replaceAll('"', r'\"')}"');
  return '[${escaped.join(', ')}]';
}

/// Типы conventional commits
enum CommitType {
  feat,
  fix,
  perf,
  refactor,
  docs,
  test,
  chore,
  style,
  ci,
  build,
  breaking,
  other,
}

class Commit {
  final String hash;
  final String message;
  final String author;
  final String date;

  String? version;
  String? versionDate;

  late final CommitType type;
  late final String scope;
  late final String description;
  late final bool isBreaking;

  Commit({
    required this.hash,
    required this.message,
    required this.author,
    required this.date,
  }) {
    _parseMessage();
  }

  void _parseMessage() {
    // Парсим conventional commit: type(scope): description
    // или type!: description (breaking)
    final pattern = RegExp(r'^(\w+)(\([\w-]+\))?(!)?:\s*(.+)$');
    final match = pattern.firstMatch(message);

    if (match != null) {
      final typeStr = match.group(1)!.toLowerCase();
      scope = match.group(2)?.replaceAll(RegExp(r'[()]'), '') ?? '';
      isBreaking = match.group(3) == '!';
      description = _translateDescription(match.group(4)!);

      type = _parseType(typeStr);
    } else {
      // Не conventional commit
      type = CommitType.other;
      scope = '';
      isBreaking = false;
      description = message;
    }
  }

  CommitType _parseType(String typeStr) {
    switch (typeStr) {
      case 'feat':
        return CommitType.feat;
      case 'fix':
        return CommitType.fix;
      case 'perf':
        return CommitType.perf;
      case 'refactor':
        return CommitType.refactor;
      case 'docs':
        return CommitType.docs;
      case 'test':
        return CommitType.test;
      case 'chore':
        return CommitType.chore;
      case 'style':
        return CommitType.style;
      case 'ci':
        return CommitType.ci;
      case 'build':
        return CommitType.build;
      default:
        return CommitType.other;
    }
  }

  String _translateDescription(String desc) {
    // Простые замены английских слов на русские
    return desc
        .replaceAll('Add ', 'Добавлен ')
        .replaceAll('add ', 'добавлен ')
        .replaceAll('Fix ', 'Исправлен ')
        .replaceAll('fix ', 'исправлен ')
        .replaceAll('Update ', 'Обновлён ')
        .replaceAll('update ', 'обновлён ')
        .replaceAll('Remove ', 'Удалён ')
        .replaceAll('remove ', 'удалён ')
        .replaceAll('Improve ', 'Улучшен ')
        .replaceAll('improve ', 'улучшен ')
        .replaceAll('Refactor ', 'Рефакторинг ')
        .replaceAll('refactor ', 'рефакторинг ')
        .replaceAll('calculator', 'калькулятор')
        .replaceAll('Calculator', 'Калькулятор');
  }
}

class VersionChanges {
  final String version;
  final String date;

  final features = <Commit>[];
  final fixes = <Commit>[];
  final improvements = <Commit>[];
  final docs = <Commit>[];
  final tests = <Commit>[];
  final chores = <Commit>[];
  final breaking = <Commit>[];
  final other = <Commit>[];

  VersionChanges({required this.version, required this.date});

  void addCommit(Commit commit) {
    if (commit.isBreaking) {
      breaking.add(commit);
      return;
    }

    switch (commit.type) {
      case CommitType.feat:
        features.add(commit);
      case CommitType.fix:
        fixes.add(commit);
      case CommitType.perf:
      case CommitType.refactor:
        improvements.add(commit);
      case CommitType.docs:
        docs.add(commit);
      case CommitType.test:
        tests.add(commit);
      case CommitType.chore:
      case CommitType.style:
      case CommitType.ci:
      case CommitType.build:
        chores.add(commit);
      case CommitType.breaking:
        breaking.add(commit);
      case CommitType.other:
        other.add(commit);
    }
  }
}
