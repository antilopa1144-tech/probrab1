#!/bin/bash
echo "Генерация кода для Isar..."
flutter pub run build_runner build --delete-conflicting-outputs
echo "Готово!"
