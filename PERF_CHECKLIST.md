# Проверка плавности (profile/release) + сценарии

## Плавность (Windows)

### Profile (рекомендуется для диагностики)
- Запуск: `flutter run -d windows --profile --dart-define=PERF_FRAME_TIMINGS=true`
- Ожидаемо в консоли: строки вида `[PERF] ... avg=..ms p90=..ms p99=..ms jank>16ms=..`
- DevTools (по желанию): `flutter pub global run devtools` → открыть по ссылке из консоли `flutter run`

### Release (рекомендуется для «как у пользователя»)
- Сборка: `flutter build windows --release`
- Запуск: `build/windows/x64/runner/Release/probrab_ai.exe`

## Быстрые ручные сценарии (5–7)

1) Найти калькулятор через поиск → открыть.
2) Открыть из категории.
3) Попробовать посчитать «без ввода» → ошибок быть не должно до нажатия `Рассчитать`.
4) Частично заполнить → ошибки только для тронутых полей или после `Рассчитать`.
5) Добавить в избранное → открыть из избранного.
6) Вернуться на главную через нижнюю навигацию.

## Автотест сценариев (widget test)
- Запуск: `flutter test test/integration/user_scenarios_test.dart -r compact`

