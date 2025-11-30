# Настройка Firebase для Прораб AI

## Что уже сделано

✅ Добавлены зависимости Firebase в `pubspec.yaml`
✅ Интегрирован Firebase Crashlytics в ErrorHandler
✅ Настроена инициализация Firebase в main.dart
✅ Создан placeholder для firebase_options.dart

## Что нужно сделать для полной настройки

### 1. Установите Firebase CLI и FlutterFire CLI

```bash
# Установите Firebase CLI (если не установлен)
npm install -g firebase-tools

# Установите FlutterFire CLI
dart pub global activate flutterfire_cli
```

### 2. Войдите в Firebase

```bash
firebase login
```

### 3. Создайте Firebase проект

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект или выберите существующий
3. Включите следующие сервисы:
   - **Firebase Crashlytics** - мониторинг ошибок
   - **Firebase Analytics** - аналитика использования

### 4. Настройте проект с помощью FlutterFire

```bash
# В корневой директории проекта выполните:
flutterfire configure
```

Эта команда:
- Автоматически создаст приложения для Android и iOS в вашем Firebase проекте
- Сгенерирует правильный файл `lib/firebase_options.dart` с реальными ключами
- Обновит конфигурацию для обеих платформ

### 5. Добавьте google-services.json для Android

После выполнения `flutterfire configure`:

1. Файл `android/app/google-services.json` должен быть создан автоматически
2. Убедитесь, что в `android/build.gradle` есть:

```gradle
buildscript {
    dependencies {
        // Уже должно быть добавлено
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

3. В `android/app/build.gradle` в конце файла должно быть:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 6. Настройте GoogleService-Info.plist для iOS

1. Файл `ios/Runner/GoogleService-Info.plist` создается автоматически
2. Откройте проект в Xcode и убедитесь, что файл добавлен в проект

### 7. Проверьте работу

```bash
# Запустите приложение
flutter run

# Проверьте логи - должно появиться сообщение об успешной инициализации Firebase
```

### 8. Протестируйте Crashlytics

Добавьте тестовый краш для проверки:

```dart
// В любом месте приложения для теста
ElevatedButton(
  onPressed: () {
    throw Exception('Test crash for Crashlytics');
  },
  child: Text('Test Crash'),
)
```

После краша:
1. Перезапустите приложение
2. Подождите несколько минут
3. Проверьте Firebase Console → Crashlytics

## Как работает система мониторинга ошибок

### Автоматический мониторинг

Все ошибки автоматически отправляются в Firebase Crashlytics через:

1. **FlutterError.onError** - перехватывает Flutter framework ошибки
2. **ErrorHandler.logError()** - для ручного логирования ошибок
3. **ErrorHandler.logFatalError()** - для критических ошибок

### Пример использования в коде

```dart
try {
  // Ваш код
  final result = await riskyOperation();
} catch (e, stack) {
  // Автоматическая отправка в Firebase
  ErrorHandler.logError(e, stack, 'riskyOperation');

  // Показать пользователю понятное сообщение
  final message = ErrorHandler.getUserFriendlyMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

### Analytics события

Firebase Analytics автоматически отслеживает:
- `error_occurred` - при любой ошибке
- `fatal_error_occurred` - при критических ошибках

Параметры события:
- `error_category` - категория ошибки (network, database, и т.д.)
- `error_type` - тип ошибки
- `context` - контекст, где произошла ошибка

## Дополнительные настройки (опционально)

### Отключение Crashlytics в debug режиме

В `main.dart` добавьте:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Отключаем сбор данных в debug режиме
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  // ... остальной код
}
```

### Добавление пользовательских ключей

```dart
// Установить ID пользователя для отслеживания
FirebaseCrashlytics.instance.setUserIdentifier('user_12345');

// Добавить custom keys для дополнительного контекста
FirebaseCrashlytics.instance.setCustomKey('current_screen', 'calculator');
FirebaseCrashlytics.instance.setCustomKey('project_id', projectId);
```

## Полезные ссылки

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Crashlytics Docs](https://firebase.google.com/docs/crashlytics)
- [Firebase Analytics Docs](https://firebase.google.com/docs/analytics)

## Важные замечания

⚠️ **Безопасность**: Файлы `google-services.json` и `GoogleService-Info.plist` содержат API ключи. Убедитесь, что они добавлены в `.gitignore` если проект публичный.

⚠️ **Тестирование**: В debug режиме крэш-репорты могут не появляться сразу. Для надежного тестирования используйте release или profile сборку.

⚠️ **Первая активация**: После первого запуска Crashlytics может потребоваться до 24 часов для активации. Но обычно данные появляются в течение нескольких минут.
