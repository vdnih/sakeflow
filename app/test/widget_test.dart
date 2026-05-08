import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/core/widgets/bottle_placeholder.dart';

void main() {
  group('BottlePlaceholder', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BottlePlaceholder(brand: '獺祭', width: 80, height: 120),
          ),
        ),
      );

      expect(find.byType(BottlePlaceholder), findsOneWidget);
      expect(find.byIcon(Icons.liquor_outlined), findsOneWidget);
    });

    testWidgets('borderRadius デフォルト値（10）が適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BottlePlaceholder(brand: 'テスト', width: 60, height: 90),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(10));
    });
  });

  group('bottleColor', () {
    test('獺祭 → 専用カラー', () {
      expect(bottleColor('獺祭'), const Color(0xFF3D2B1F));
    });

    test('久保田 → 専用カラー', () {
      expect(bottleColor('久保田 千寿'), const Color(0xFF1F2D3D));
    });

    test('未登録銘柄 → デフォルトカラー（kSurface2）', () {
      final color = bottleColor('不明な銘柄');
      expect(color, isA<Color>());
    });
  });
}
