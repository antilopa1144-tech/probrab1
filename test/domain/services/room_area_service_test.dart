import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/services/room_area_service.dart';

void main() {
  late RoomAreaService service;

  setUp(() {
    service = RoomAreaService();
  });

  group('RoomAreaService', () {
    group('calculateRoom', () {
      test('стандартная комната 5×4×2.5м', () {
        final result = service.calculateRoom(
          length: 5,
          width: 4,
          height: 2.5,
        );

        expect(result.floorArea, 20.0);
        expect(result.ceilingArea, 20.0);
        expect(result.perimeter, 18.0);
        expect(result.totalWallArea, 45.0);
        expect(result.walls.length, 4);
      });

      test('стены имеют правильные размеры', () {
        final result = service.calculateRoom(
          length: 5,
          width: 4,
          height: 2.5,
        );

        // Стена A: 5 × 2.5 = 12.5
        expect(result.walls[0].name, 'A');
        expect(result.walls[0].width, 5);
        expect(result.walls[0].height, 2.5);
        expect(result.walls[0].grossArea, 12.5);

        // Стена B: 4 × 2.5 = 10
        expect(result.walls[1].name, 'B');
        expect(result.walls[1].width, 4);
        expect(result.walls[1].grossArea, 10.0);

        // Стена C = стена A
        expect(result.walls[2].grossArea, 12.5);

        // Стена D = стена B
        expect(result.walls[3].grossArea, 10.0);
      });

      test('квадратная комната 3×3×2.7м', () {
        final result = service.calculateRoom(
          length: 3,
          width: 3,
          height: 2.7,
        );

        expect(result.floorArea, 9.0);
        expect(result.ceilingArea, 9.0);
        expect(result.perimeter, 12.0);
        expect(result.totalWallArea, 32.4);
      });

      test('маленькая комната 1.5×1.2×2.5м', () {
        final result = service.calculateRoom(
          length: 1.5,
          width: 1.2,
          height: 2.5,
        );

        expect(result.floorArea, 1.8);
        expect(result.perimeter, 5.4);
        // Стены: 2*(1.5*2.5) + 2*(1.2*2.5) = 7.5 + 6 = 13.5
        expect(result.totalWallArea, 13.5);
      });

      test('большая комната 10×8×3м', () {
        final result = service.calculateRoom(
          length: 10,
          width: 8,
          height: 3,
        );

        expect(result.floorArea, 80.0);
        expect(result.perimeter, 36.0);
        // Стены: 2*(10*3) + 2*(8*3) = 60 + 48 = 108
        expect(result.totalWallArea, 108.0);
      });
    });

    group('calculateWall', () {
      test('стена без проёмов', () {
        final result = service.calculateWall(
          wallWidth: 5,
          wallHeight: 2.5,
        );

        expect(result.grossArea, 12.5);
        expect(result.netArea, 12.5);
        expect(result.openingsArea, 0.0);
      });

      test('стена с дверью 0.9×2.1', () {
        final result = service.calculateWall(
          wallWidth: 5,
          wallHeight: 2.5,
          openings: [const Opening(width: 0.9, height: 2.1)],
        );

        expect(result.grossArea, 12.5);
        expect(result.openingsArea, 1.89);
        expect(result.netArea, 10.61);
      });

      test('стена с окном 1.5×1.4', () {
        final result = service.calculateWall(
          wallWidth: 4,
          wallHeight: 2.5,
          openings: [const Opening(width: 1.5, height: 1.4)],
        );

        expect(result.grossArea, 10.0);
        expect(result.openingsArea, 2.1);
        expect(result.netArea, 7.9);
      });

      test('стена с дверью и окном', () {
        final result = service.calculateWall(
          wallWidth: 6,
          wallHeight: 2.5,
          openings: [
            const Opening(width: 0.9, height: 2.1), // дверь
            const Opening(width: 1.5, height: 1.4), // окно
          ],
        );

        expect(result.grossArea, 15.0);
        // Проёмы: 1.89 + 2.1 = 3.99
        expect(result.openingsArea, 3.99);
        // Нетто: 15 - 3.99 = 11.01
        expect(result.netArea, 11.01);
      });

      test('проёмы больше стены — netArea = 0', () {
        final result = service.calculateWall(
          wallWidth: 1,
          wallHeight: 1,
          openings: [const Opening(width: 2, height: 2)],
        );

        expect(result.grossArea, 1.0);
        expect(result.openingsArea, 4.0);
        expect(result.netArea, 0.0); // clamp to 0
      });

      test('двойная дверь', () {
        final result = service.calculateWall(
          wallWidth: 5,
          wallHeight: 2.5,
          openings: [const Opening(width: 1.6, height: 2.1)],
        );

        expect(result.grossArea, 12.5);
        expect(result.openingsArea, 3.36);
        expect(result.netArea, 9.14);
      });
    });

    group('calculateWalls', () {
      test('пустой список стен', () {
        final result = service.calculateWalls([]);

        expect(result.totalGrossArea, 0.0);
        expect(result.totalNetArea, 0.0);
        expect(result.totalOpeningsArea, 0.0);
        expect(result.walls, isEmpty);
      });

      test('одна стена без проёмов', () {
        final result = service.calculateWalls([
          const WallInput(width: 5, height: 2.5),
        ]);

        expect(result.totalGrossArea, 12.5);
        expect(result.totalNetArea, 12.5);
        expect(result.totalOpeningsArea, 0.0);
        expect(result.walls.length, 1);
      });

      test('три стены с разными проёмами', () {
        final result = service.calculateWalls([
          const WallInput(width: 5, height: 2.5), // 12.5 м²
          WallInput(
            width: 4,
            height: 2.5,
            openings: [const Opening(width: 0.9, height: 2.1)], // дверь
          ), // 10 - 1.89 = 8.11
          WallInput(
            width: 3,
            height: 2.5,
            openings: [const Opening(width: 1.5, height: 1.4)], // окно
          ), // 7.5 - 2.1 = 5.4
        ]);

        expect(result.walls.length, 3);
        expect(result.totalGrossArea, 30.0);
        expect(result.totalOpeningsArea, 3.99);
        expect(result.totalNetArea, 26.01);
      });

      test('много стен', () {
        final result = service.calculateWalls([
          const WallInput(width: 5, height: 2.5),
          const WallInput(width: 4, height: 2.5),
          const WallInput(width: 5, height: 2.5),
          const WallInput(width: 4, height: 2.5),
        ]);

        // Как 4 стены комнаты 5×4×2.5
        expect(result.totalGrossArea, 45.0);
        expect(result.totalNetArea, 45.0);
      });
    });

    group('Opening', () {
      test('area рассчитывается корректно', () {
        const opening = Opening(width: 1.5, height: 1.4);
        expect(opening.area, closeTo(2.1, 0.001));
      });
    });
  });
}
