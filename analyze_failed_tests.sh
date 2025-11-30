#!/bin/bash
# Скрипт для анализа упавших тестов

echo "=== Анализ упавших тестов калькуляторов ==="
echo ""

FAILED_TESTS=()
PASSED_TESTS=()

# Запуск всех тестов калькуляторов
for test_file in test/domain/usecases/calculate_*_test.dart; do
  test_name=$(basename "$test_file" .dart)

  echo -n "Тестирование $test_name... "

  # Запуск теста и подсчет результатов
  result=$(flutter test "$test_file" 2>&1)

  if echo "$result" | grep -q "All tests passed"; then
    passed=$(echo "$result" | grep -oP '\+\K[0-9]+' | tail -1)
    echo "✅ $passed тестов прошли"
    PASSED_TESTS+=("$test_name:$passed")
  else
    passed=$(echo "$result" | grep -oP '\+\K[0-9]+' | tail -1)
    failed=$(echo "$result" | grep -oP '\-\K[0-9]+' | tail -1)
    echo "❌ $passed прошло, $failed упало"
    FAILED_TESTS+=("$test_name:$passed:$failed")
  fi
done

echo ""
echo "=== Итоговая статистика ==="
echo "Прошли полностью: ${#PASSED_TESTS[@]}"
echo "Есть падения: ${#FAILED_TESTS[@]}"
echo ""

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
  echo "=== Упавшие тесты (для исправления) ==="
  for item in "${FAILED_TESTS[@]}"; do
    IFS=':' read -r name passed failed <<< "$item"
    echo "  • $name ($passed✅ $failed❌)"
  done
fi
