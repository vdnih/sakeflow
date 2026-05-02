/// 47都道府県の正規化ユーティリティ。
/// AI 解析が返す表記揺れ（「東京」「東京都」「Tokyo」など）を
/// JIS X 0401 の都道府県コード（jp01..jp47）に変換する。
/// jp コードは countries_world_map パッケージの SMapJapanColors と整合。
class PrefectureNormalizer {
  /// JIS コード順の正式名称（jp01 = 北海道, jp47 = 沖縄県）
  static const List<String> officialNames = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
    '岐阜県', '静岡県', '愛知県', '三重県',
    '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県',
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県',
    '沖縄県',
  ];

  /// 英語名（小文字）→ JIS コード（1始まり）
  static const Map<String, int> _englishToCode = {
    'hokkaido': 1, 'aomori': 2, 'iwate': 3, 'miyagi': 4, 'akita': 5,
    'yamagata': 6, 'fukushima': 7, 'ibaraki': 8, 'tochigi': 9, 'gunma': 10,
    'saitama': 11, 'chiba': 12, 'tokyo': 13, 'kanagawa': 14, 'niigata': 15,
    'toyama': 16, 'ishikawa': 17, 'fukui': 18, 'yamanashi': 19, 'nagano': 20,
    'gifu': 21, 'shizuoka': 22, 'aichi': 23, 'mie': 24, 'shiga': 25,
    'kyoto': 26, 'osaka': 27, 'hyogo': 28, 'nara': 29, 'wakayama': 30,
    'tottori': 31, 'shimane': 32, 'okayama': 33, 'hiroshima': 34, 'yamaguchi': 35,
    'tokushima': 36, 'kagawa': 37, 'ehime': 38, 'kochi': 39, 'fukuoka': 40,
    'saga': 41, 'nagasaki': 42, 'kumamoto': 43, 'oita': 44, 'miyazaki': 45,
    'kagoshima': 46, 'okinawa': 47,
  };

  /// 任意の表記を SimpleMap の colors/callback キー（JP-01..JP-47）に正規化する。
  /// マッチしない場合は null。
  static String? toJpCode(String raw) {
    final code = _toJisCode(raw);
    if (code == null) return null;
    return 'JP-${code.toString().padLeft(2, '0')}';
  }

  /// 任意の表記を正式名称（例: 「東京都」）に正規化する。
  static String? toOfficialName(String raw) {
    final code = _toJisCode(raw);
    if (code == null) return null;
    return officialNames[code - 1];
  }

  static int? _toJisCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1) 完全一致（正式名称）
    final exactIdx = officialNames.indexOf(trimmed);
    if (exactIdx >= 0) return exactIdx + 1;

    // 2) 都府県サフィックス無しの和名（「東京」「大阪」「北海道」等）
    for (var i = 0; i < officialNames.length; i++) {
      final name = officialNames[i];
      // 北海道はサフィックスなし
      final stem = name.replaceAll(RegExp(r'[都道府県]$'), '');
      if (trimmed == stem || trimmed == name) return i + 1;
    }

    // 3) 英語表記
    final lower = trimmed.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
    final enCode = _englishToCode[lower];
    if (enCode != null) return enCode;

    return null;
  }
}
