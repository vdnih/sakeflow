import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/features/map/utils/prefecture_normalizer.dart';

void main() {
  group('PrefectureNormalizer.toJpCode', () {
    test('正式名称（都）', () {
      expect(PrefectureNormalizer.toJpCode('東京都'), 'JP-13');
    });

    test('正式名称（道）', () {
      expect(PrefectureNormalizer.toJpCode('北海道'), 'JP-01');
    });

    test('正式名称（府）', () {
      expect(PrefectureNormalizer.toJpCode('京都府'), 'JP-26');
      expect(PrefectureNormalizer.toJpCode('大阪府'), 'JP-27');
    });

    test('正式名称（県）', () {
      expect(PrefectureNormalizer.toJpCode('新潟県'), 'JP-15');
      expect(PrefectureNormalizer.toJpCode('沖縄県'), 'JP-47');
    });

    test('略称（サフィックスなし）', () {
      expect(PrefectureNormalizer.toJpCode('東京'), 'JP-13');
      expect(PrefectureNormalizer.toJpCode('大阪'), 'JP-27');
      expect(PrefectureNormalizer.toJpCode('京都'), 'JP-26');
      expect(PrefectureNormalizer.toJpCode('北海道'), 'JP-01');
    });

    test('英語表記（小文字）', () {
      expect(PrefectureNormalizer.toJpCode('tokyo'), 'JP-13');
      expect(PrefectureNormalizer.toJpCode('osaka'), 'JP-27');
      expect(PrefectureNormalizer.toJpCode('hokkaido'), 'JP-01');
      expect(PrefectureNormalizer.toJpCode('okinawa'), 'JP-47');
    });

    test('英語表記（大文字混在）', () {
      expect(PrefectureNormalizer.toJpCode('Tokyo'), 'JP-13');
      expect(PrefectureNormalizer.toJpCode('OSAKA'), 'JP-27');
    });

    test('英語表記（スペース区切り）', () {
      expect(PrefectureNormalizer.toJpCode('kanagawa'), 'JP-14');
    });

    test('不明な文字列 → null', () {
      expect(PrefectureNormalizer.toJpCode('unknown'), isNull);
      expect(PrefectureNormalizer.toJpCode('東京県'), isNull);
    });

    test('空文字 → null', () {
      expect(PrefectureNormalizer.toJpCode(''), isNull);
    });

    test('前後スペース付き', () {
      expect(PrefectureNormalizer.toJpCode(' 東京都 '), 'JP-13');
    });

    test('全47都道府県が JP コードに変換できる', () {
      for (var i = 0; i < PrefectureNormalizer.officialNames.length; i++) {
        final name = PrefectureNormalizer.officialNames[i];
        final expectedCode = 'JP-${(i + 1).toString().padLeft(2, '0')}';
        expect(
          PrefectureNormalizer.toJpCode(name),
          expectedCode,
          reason: '$name が $expectedCode に変換されること',
        );
      }
    });
  });

  group('PrefectureNormalizer.toOfficialName', () {
    test('略称から正式名称に変換', () {
      expect(PrefectureNormalizer.toOfficialName('東京'), '東京都');
      expect(PrefectureNormalizer.toOfficialName('大阪'), '大阪府');
      expect(PrefectureNormalizer.toOfficialName('京都'), '京都府');
      expect(PrefectureNormalizer.toOfficialName('青森'), '青森県');
    });

    test('英語から正式名称に変換', () {
      expect(PrefectureNormalizer.toOfficialName('tokyo'), '東京都');
      expect(PrefectureNormalizer.toOfficialName('hokkaido'), '北海道');
    });

    test('既に正式名称なら同じ値を返す', () {
      expect(PrefectureNormalizer.toOfficialName('東京都'), '東京都');
      expect(PrefectureNormalizer.toOfficialName('北海道'), '北海道');
    });

    test('不明な文字列 → null', () {
      expect(PrefectureNormalizer.toOfficialName('unknown'), isNull);
    });

    test('空文字 → null', () {
      expect(PrefectureNormalizer.toOfficialName(''), isNull);
    });
  });
}
