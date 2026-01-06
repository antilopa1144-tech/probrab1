# iOS Code Signing Guide

> Инструкция по настройке подписи кода для iOS сборок

---

## Требования

- **macOS** с установленным Xcode
- **Apple Developer Account** (платная подписка $99/год)
- **Flutter SDK** 3.24.0+
- **CocoaPods** установлен

---

## Шаг 1: Настройка Apple Developer Account

### 1.1 Создание App ID

1. Зайти на [Apple Developer Portal](https://developer.apple.com/)
2. Перейти в **Certificates, Identifiers & Profiles**
3. Выбрать **Identifiers** → **App IDs**
4. Нажать **+** для создания нового App ID
5. Выбрать **App** и нажать **Continue**
6. Заполнить:
   - **Description**: Probrab AI
   - **Bundle ID**: `ru.probrab.app` (Explicit)
   - **Capabilities**: Выбрать необходимые (Push Notifications, In-App Purchase и т.д.)
7. Нажать **Continue** → **Register**

### 1.2 Создание Certificates

#### Development Certificate

1. На Mac откройте **Keychain Access**
2. **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Заполнить email и имя, выбрать **Save to disk**
4. В Developer Portal: **Certificates** → **+**
5. Выбрать **iOS App Development**
6. Загрузить созданный `.certSigningRequest` файл
7. Скачать `.cer` файл и открыть его (установится в Keychain)

#### Distribution Certificate

1. Повторить процесс, но выбрать **iOS Distribution** вместо Development
2. Установить сертификат в Keychain

### 1.3 Создание Provisioning Profiles

#### Development Profile

1. В Developer Portal: **Profiles** → **+**
2. Выбрать **iOS App Development**
3. Выбрать App ID: `ru.probrab.app`
4. Выбрать Development Certificate
5. Выбрать устройства для тестирования
6. Назвать профиль: `Probrab AI Development`
7. Скачать и открыть `.mobileprovision` файл

#### Distribution Profile (App Store)

1. **Profiles** → **+**
2. Выбрать **App Store**
3. Выбрать App ID: `ru.probrab.app`
4. Выбрать Distribution Certificate
5. Назвать профиль: `Probrab AI App Store`
6. Скачать профиль

---

## Шаг 2: Настройка Xcode Project

### 2.1 Открыть проект в Xcode

```bash
cd ios
open Runner.xcworkspace
```

### 2.2 Настроить Signing & Capabilities

1. Выбрать **Runner** в Project Navigator
2. Выбрать таргет **Runner**
3. Перейти на вкладку **Signing & Capabilities**

#### Для Debug конфигурации:

- **Automatically manage signing**: ✅ (можно включить)
- **Team**: Выбрать вашу команду
- **Bundle Identifier**: `ru.probrab.app`

#### Для Release конфигурации:

- **Automatically manage signing**: ✅ (рекомендуется)
- **Team**: Выбрать вашу команду
- **Bundle Identifier**: `ru.probrab.app`

### 2.3 Настроить Build Settings

1. Выбрать **Runner** → **Build Settings**
2. Найти **Code Signing Identity**:
   - **Debug**: `iOS Developer`
   - **Release**: `iOS Distribution`
3. Найти **Provisioning Profile**:
   - **Debug**: `Probrab AI Development`
   - **Release**: `Probrab AI App Store`

---

## Шаг 3: Настройка в Flutter Project

### 3.1 Обновить ios/Runner/Info.plist

Убедитесь, что Bundle ID совпадает:

```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

### 3.2 Создать ios/exportOptions.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

**Примечание**: Замените `YOUR_TEAM_ID` на ваш реальный Team ID

---

## Шаг 4: Сборка и подпись

### 4.1 Сборка для тестирования (Development)

```bash
# Сборка для устройства
flutter build ios --debug --no-codesign

# Или с автоматической подписью
flutter build ios --debug
```

### 4.2 Сборка для App Store (Release)

```bash
# Чистая сборка
flutter clean
flutter pub get

# Сборка release версии
flutter build ios --release

# Создать IPA архив
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive

# Экспортировать IPA для App Store
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/Runner \
  -exportOptionsPlist exportOptions.plist
```

### 4.3 Альтернатива: Использовать Xcode

1. Открыть `ios/Runner.xcworkspace` в Xcode
2. **Product** → **Archive**
3. После завершения откроется **Organizer**
4. Выбрать архив → **Distribute App**
5. Выбрать **App Store Connect**
6. Следовать инструкциям мастера

---

## Шаг 5: Загрузка в App Store Connect

### 5.1 Через Xcode

1. В Organizer после распределения выбрать **Upload**
2. Войти в Apple ID
3. Дождаться завершения загрузки

### 5.2 Через Transporter

1. Скачать [Transporter](https://apps.apple.com/us/app/transporter/id1450874784)
2. Открыть Transporter
3. Перетащить `.ipa` файл
4. Нажать **Deliver**

### 5.3 Через Fastlane (Автоматизация)

Установить Fastlane:

```bash
sudo gem install fastlane
cd ios
fastlane init
```

Создать `ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new release build to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight
  end

  desc "Push a new release build to the App Store"
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_app_store
  end
end
```

Запустить:

```bash
fastlane beta  # Для TestFlight
fastlane release  # Для App Store
```

---

## Шаг 6: Настройка CI/CD для iOS

### GitHub Actions для iOS

Создать `.github/workflows/ios_release.yml`:

```yaml
name: iOS Release

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:

jobs:
  build-ios:
    name: Build iOS Release
    runs-on: macos-latest
    timeout-minutes: 60

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Build iOS
        run: flutter build ios --release --no-codesign

      - name: Setup certificates
        env:
          CERTIFICATE_BASE64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
          P12_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Создать временный keychain
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain

          # Импортировать сертификат
          echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
          security import certificate.p12 -k build.keychain -P "$P12_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain

      - name: Build and sign with Xcode
        run: |
          cd ios
          xcodebuild -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -archivePath build/Runner.xcarchive \
            archive

          xcodebuild -exportArchive \
            -archivePath build/Runner.xcarchive \
            -exportPath build/Runner \
            -exportOptionsPlist exportOptions.plist

      - name: Upload to TestFlight
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          xcrun altool --upload-app \
            --type ios \
            --file build/Runner/Runner.ipa \
            --apiKey $APP_STORE_CONNECT_API_KEY

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ios-release-ipa
          path: ios/build/Runner/Runner.ipa
          retention-days: 30
```

---

## Troubleshooting

### Проблема: "No valid code signing certificate"

**Решение:**
1. Проверьте, что сертификат установлен в Keychain
2. Проверьте срок действия сертификата
3. Убедитесь, что Bundle ID совпадает

### Проблема: "Provisioning profile doesn't include signing certificate"

**Решение:**
1. Пересоздайте Provisioning Profile
2. Убедитесь, что выбран правильный сертификат
3. Скачайте и установите новый профиль

### Проблема: "Unable to install ... Please check your project settings"

**Решение:**
1. Очистите build: `flutter clean`
2. Удалите `ios/Pods` и `ios/Podfile.lock`
3. Запустите: `cd ios && pod install`

### Проблема: "The bundle identifier ... is already in use"

**Решение:**
1. Измените Bundle ID в Xcode
2. Обновите App ID в Developer Portal
3. Пересоздайте Provisioning Profiles

---

## Полезные ссылки

- [Apple Developer Portal](https://developer.apple.com/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Help](https://developer.apple.com/documentation/xcode)
- [Fastlane Documentation](https://docs.fastlane.tools/)

---

## Checklist

- [ ] Apple Developer Account активирован
- [ ] App ID создан
- [ ] Development Certificate создан и установлен
- [ ] Distribution Certificate создан и установлен
- [ ] Development Provisioning Profile создан
- [ ] Distribution Provisioning Profile создан
- [ ] Xcode project настроен (Signing & Capabilities)
- [ ] Bundle ID корректный во всех местах
- [ ] exportOptions.plist создан
- [ ] Тестовая сборка успешна
- [ ] Release сборка успешна
- [ ] IPA создан и подписан
- [ ] Загрузка в App Store Connect работает
- [ ] CI/CD настроен (опционально)

---

**Последнее обновление**: 2026-01-06
