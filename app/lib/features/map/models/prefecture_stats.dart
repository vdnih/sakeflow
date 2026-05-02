/// マップ画面用の都道府県集計結果。
/// 値は SMapJapanColors のキー（jp01..jp47）。
class PrefectureStats {
  /// 飲んだ県（drank_locally 問わず）
  final Set<String> drank;

  /// 現地で飲んだ県（drank_locally == true）
  final Set<String> drankLocal;

  const PrefectureStats({
    required this.drank,
    required this.drankLocal,
  });

  static const PrefectureStats empty = PrefectureStats(
    drank: {},
    drankLocal: {},
  );

  int get drankCount => drank.length;
  int get drankLocalCount => drankLocal.length;
}
