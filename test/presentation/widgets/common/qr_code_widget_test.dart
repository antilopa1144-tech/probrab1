import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/qr_code_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QrCodeWidget Tests', () {
    const testData = 'https://example.com/test';

    testWidgets('должен отображать QR код с базовыми параметрами',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(data: testData),
          ),
        ),
      );

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('должен использовать правильный размер по умолчанию',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(data: testData),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImageView.size, 200.0);
    });

    testWidgets('должен использовать кастомный размер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(
              data: testData,
              size: 300,
            ),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImageView.size, 300.0);
    });

    testWidgets('должен использовать правильные цвета по умолчанию',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(data: testData),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImageView.backgroundColor, Colors.white);
      expect(qrImageView.eyeStyle.color, Colors.black);
    });

    testWidgets('должен использовать кастомные цвета', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(
              data: testData,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.red,
            ),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImageView.backgroundColor, Colors.blue);
      expect(qrImageView.eyeStyle.color, Colors.red);
      expect(qrImageView.dataModuleStyle.color, Colors.red);
    });

    testWidgets('должен отображать контейнер по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(data: testData),
          ),
        ),
      );

      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Проверяем что есть контейнер с декорацией
      final containerWithDecoration = tester.widgetList<Container>(containers)
          .where((c) => c.decoration != null);
      expect(containerWithDecoration.isNotEmpty, true);
    });

    testWidgets('должен использовать правильный уровень коррекции ошибок',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(
              data: testData,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImageView.errorCorrectionLevel, QrErrorCorrectLevel.H);
    });

    group('QrCodeWidget.plain конструктор', () {
      testWidgets('должен создавать QR код без контейнера', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              body: QrCodeWidget.plain(data: testData),
            ),
          ),
        );

        expect(find.byType(QrImageView), findsOneWidget);

        // Проверяем что нет декорированного контейнера
        final containers = tester.widgetList<Container>(find.byType(Container));
        final decoratedContainers = containers.where((c) => c.decoration != null);

        // Plain widget не должен иметь декорированный контейнер вокруг QR кода
        expect(decoratedContainers.isEmpty, true);
      });

      testWidgets('должен использовать размер 200 по умолчанию',
          (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              body: QrCodeWidget.plain(data: testData),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.size, 200.0);
      });
    });

    group('QrCodeWidget.small конструктор', () {
      testWidgets('должен создавать маленький QR код', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              body: QrCodeWidget.small(data: testData),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.size, 100.0);
      });

      testWidgets('должен использовать уровень коррекции L', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              body: QrCodeWidget.small(data: testData),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.errorCorrectionLevel, QrErrorCorrectLevel.L);
      });

      testWidgets('должен иметь маленькое встроенное изображение',
          (tester) async {
        setTestViewportSize(tester);
        const logo = AssetImage('assets/icons/app_icon.png');

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeWidget.small(
                data: testData,
                embeddedImage: logo,
              ),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.embeddedImageStyle?.size, const Size(20, 20));
      });
    });

    group('QrCodeWidget.large конструктор', () {
      testWidgets('должен создавать большой QR код', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeWidget.large(data: testData),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.size, 300.0);
      });

      testWidgets('должен использовать уровень коррекции H', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeWidget.large(data: testData),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.errorCorrectionLevel, QrErrorCorrectLevel.H);
      });

      testWidgets('должен иметь большое встроенное изображение',
          (tester) async {
        setTestViewportSize(tester);
        const logo = AssetImage('assets/icons/app_icon.png');

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeWidget.large(
                data: testData,
                embeddedImage: logo,
              ),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.embeddedImageStyle?.size, const Size(60, 60));
      });

      testWidgets('должен иметь контейнер с тенью', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeWidget.large(data: testData),
            ),
          ),
        );

        final containers = tester.widgetList<Container>(find.byType(Container));
        final decoratedContainer = containers.firstWhere(
          (c) => c.decoration is BoxDecoration,
        );

        final decoration = decoratedContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.isNotEmpty, true);
      });
    });

    testWidgets('должен отображать встроенное изображение', (tester) async {
      setTestViewportSize(tester);
      const logo = AssetImage('assets/icons/app_icon.png');

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(
              data: testData,
              embeddedImage: logo,
              embeddedImageSize: Size(40, 40),
            ),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImageView.embeddedImage, logo);
      expect(qrImageView.embeddedImageStyle?.size, const Size(40, 40));
    });

    testWidgets('должен использовать кастомные отступы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(
              data: testData,
              padding: EdgeInsets.all(32),
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final paddedContainer = containers.firstWhere(
        (c) => c.padding != null,
      );

      expect(paddedContainer.padding, const EdgeInsets.all(32));
    });

    testWidgets('должен использовать кастомное скругление углов',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: QrCodeWidget(
              data: testData,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final decoratedContainer = containers.firstWhere(
        (c) => c.decoration is BoxDecoration,
      );

      final decoration = decoratedContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('должен использовать кастомную тень', (tester) async {
      setTestViewportSize(tester);
      final customShadow = [
        BoxShadow(
          color: Colors.red.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(5, 5),
        ),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: QrCodeWidget(
              data: testData,
              boxShadow: customShadow,
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final decoratedContainer = containers.firstWhere(
        (c) => c.decoration is BoxDecoration,
      );

      final decoration = decoratedContainer.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
      expect(decoration.boxShadow![0].blurRadius, 20);
    });

    testWidgets('должен правильно обрабатывать пустые данные', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(data: ''),
          ),
        ),
      );

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('должен правильно обрабатывать длинные данные', (tester) async {
      setTestViewportSize(tester);
      const longData = 'https://example.com/very/long/url/with/many/'
          'segments/and/parameters?param1=value1&param2=value2'
          '&param3=value3&param4=value4&param5=value5';

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(data: longData),
          ),
        ),
      );

      // QrImageView doesn't expose data property, so we just verify it renders
      expect(find.byType(QrImageView), findsOneWidget);
    });

    group('QrCodeStyles расширение', () {
      testWidgets('forProject должен создавать большой QR код', (tester) async {
        setTestViewportSize(tester);
        const logo = AssetImage('assets/icons/app_icon.png');

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeStyles.forProject(
                data: testData,
                logo: logo,
              ),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.size, 300.0);
        expect(qrImageView.embeddedImage, logo);
      });

      testWidgets('forCalculator должен создавать средний QR код',
          (tester) async {
        setTestViewportSize(tester);
        const logo = AssetImage('assets/icons/app_icon.png');

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeStyles.forCalculator(
                data: testData,
                logo: logo,
              ),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.size, 250.0);
        expect(qrImageView.embeddedImage, logo);
        expect(qrImageView.embeddedImageStyle?.size, const Size(50, 50));
      });

      testWidgets('preview должен создавать маленький QR код', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeStyles.preview(data: testData),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.size, 100.0);
      });
    });

    testWidgets('должен правильно работать с различными уровнями коррекции',
        (tester) async {
      setTestViewportSize(tester);
      for (final level in [
        QrErrorCorrectLevel.L,
        QrErrorCorrectLevel.M,
        QrErrorCorrectLevel.Q,
        QrErrorCorrectLevel.H,
      ]) {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeWidget(
                data: testData,
                errorCorrectionLevel: level,
              ),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.errorCorrectionLevel, level);
      }
    });

    testWidgets('должен корректно отображаться в разных размерах',
        (tester) async {
      setTestViewportSize(tester);
      for (final size in [50.0, 100.0, 200.0, 300.0, 500.0]) {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: QrCodeWidget(
                data: testData,
                size: size,
              ),
            ),
          ),
        );

        final qrImageView =
            tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImageView.size, size);
      }
    });

    testWidgets('должен вычислять размер встроенного изображения по умолчанию',
        (tester) async {
      setTestViewportSize(tester);
      const logo = AssetImage('assets/icons/app_icon.png');

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(
              data: testData,
              size: 200,
              embeddedImage: logo,
            ),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));

      // Default embedded image size should be 20% of QR code size
      expect(
        qrImageView.embeddedImageStyle?.size,
        const Size(40, 40), // 200 * 0.2 = 40
      );
    });

    testWidgets('должен работать без встроенного изображения', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: QrCodeWidget(data: testData),
          ),
        ),
      );

      final qrImageView = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImageView.embeddedImage, isNull);
      expect(qrImageView.embeddedImageStyle, isNull);
    });
  });
}
