import '../../tasting_note/models/tasting_note.dart';
import '../models/prefecture_stats.dart';
import '../utils/prefecture_normalizer.dart';

class PrefectureAggregator {
  static PrefectureStats aggregate(List<TastingNote> notes) {
    final drank = <String>{};
    final drankLocal = <String>{};
    for (final note in notes) {
      final code = PrefectureNormalizer.toJpCode(note.prefecture);
      if (code == null) continue;
      drank.add(code);
      if (note.drankLocally) drankLocal.add(code);
    }
    return PrefectureStats(drank: drank, drankLocal: drankLocal);
  }
}
