import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/features/record/services/ai_label_service.dart';

void main() {
  group('AiLabelService.create(useMock: true)', () {
    late AiLabelService service;

    setUp(() {
      service = AiLabelService.create(useMock: true);
    });

    test('固定データを返す', () async {
      final result = await service.analyzeLabel(Uint8List(0));

      expect(result.brand, '獺祭');
      expect(result.brewery, '旭酒造');
      expect(result.prefecture, '山口県');
      expect(result.tags, isNotEmpty);
    });

    test('tags に純米大吟醸が含まれる', () async {
      final result = await service.analyzeLabel(Uint8List(0));
      expect(result.tags, contains('純米大吟醸'));
    });

    test('異なる画像バイトでも同じ結果を返す（モック動作）', () async {
      final result1 = await service.analyzeLabel(Uint8List(10));
      final result2 = await service.analyzeLabel(Uint8List(100));

      expect(result1.brand, result2.brand);
      expect(result1.brewery, result2.brewery);
    });
  });

  group('AiLabelService.create デフォルト（本番）', () {
    test('useMock: false でも同じ interface を持つ', () {
      // Firebase 未初期化のため analyzeLabel は呼ばない
      // インスタンス生成だけ検証
      final service = AiLabelService.create(useMock: false);
      expect(service, isA<AiLabelService>());
    });
  });
}
