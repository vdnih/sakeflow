import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/features/tasting_note/models/tasting_note.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  TastingNote baseNote() {
    final now = DateTime(2024, 6, 15, 12, 0, 0);
    return TastingNote(
      noteId: 'note-001',
      userId: 'user-001',
      sakeId: 'sake-001',
      imageUrl: 'https://example.com/image.jpg',
      drankAt: now,
      brand: '獺祭',
      brewery: '旭酒造',
      prefecture: '山口県',
      category: 'sake',
      tags: ['純米大吟醸', '磨き二割三分'],
      rating: 4.5,
      note: 'とても美味しかった',
      drankLocally: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('TastingNote.fromFirestore / toMap ラウンドトリップ', () {
    test('全フィールドが正しく変換される', () async {
      final original = baseNote();
      final col = fakeFirestore.collection('notes');
      await col.doc(original.noteId).set(original.toMap());

      final doc = await col.doc(original.noteId).get();
      final restored = TastingNote.fromFirestore(doc);

      expect(restored.noteId, original.noteId);
      expect(restored.userId, original.userId);
      expect(restored.sakeId, original.sakeId);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.brand, original.brand);
      expect(restored.brewery, original.brewery);
      expect(restored.prefecture, original.prefecture);
      expect(restored.category, original.category);
      expect(restored.tags, original.tags);
      expect(restored.rating, original.rating);
      expect(restored.note, original.note);
      expect(restored.drankLocally, original.drankLocally);
      expect(restored.drankAt.millisecondsSinceEpoch,
          original.drankAt.millisecondsSinceEpoch);
    });

    test('オプション値が null でも正しく変換される', () async {
      final now = DateTime(2024, 6, 15);
      final note = TastingNote(
        noteId: 'note-002',
        userId: 'user-001',
        imageUrl: '',
        drankAt: now,
        brand: 'テスト銘柄',
        brewery: 'テスト蔵',
        prefecture: '新潟県',
        category: 'sake',
        tags: [],
        createdAt: now,
        updatedAt: now,
      );

      final col = fakeFirestore.collection('notes');
      await col.doc(note.noteId).set(note.toMap());
      final doc = await col.doc(note.noteId).get();
      final restored = TastingNote.fromFirestore(doc);

      expect(restored.rating, isNull);
      expect(restored.note, isNull);
      expect(restored.sakeId, isNull);
      expect(restored.drankLocally, false);
      expect(restored.tags, isEmpty);
    });

    test('toMap に null フィールドは含まれない', () {
      final now = DateTime(2024, 6, 15);
      final note = TastingNote(
        noteId: 'note-003',
        userId: 'user-001',
        imageUrl: '',
        drankAt: now,
        brand: '銘柄',
        brewery: '蔵元',
        prefecture: '東京都',
        category: 'sake',
        tags: [],
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toMap();
      expect(map.containsKey('rating'), false);
      expect(map.containsKey('note'), false);
      expect(map.containsKey('sake_id'), false);
    });
  });

  group('TastingNote.copyWith', () {
    test('指定したフィールドだけが変更される', () {
      final original = baseNote();
      final copied = original.copyWith(brand: '新政', rating: 5.0);

      expect(copied.brand, '新政');
      expect(copied.rating, 5.0);
      expect(copied.noteId, original.noteId);
      expect(copied.userId, original.userId);
      expect(copied.brewery, original.brewery);
      expect(copied.prefecture, original.prefecture);
      expect(copied.tags, original.tags);
      expect(copied.note, original.note);
      expect(copied.drankLocally, original.drankLocally);
    });

    test('未指定フィールドは元の値を保持する', () {
      final original = baseNote();
      final copied = original.copyWith();

      expect(copied.noteId, original.noteId);
      expect(copied.brand, original.brand);
      expect(copied.rating, original.rating);
      expect(copied.tags, original.tags);
    });

    test('drankLocally を変更できる', () {
      final original = baseNote();
      expect(original.drankLocally, true);

      final copied = original.copyWith(drankLocally: false);
      expect(copied.drankLocally, false);
    });

    test('tags を変更できる', () {
      final original = baseNote();
      final newTags = ['吟醸', '山田錦'];
      final copied = original.copyWith(tags: newTags);
      expect(copied.tags, newTags);
    });
  });
}
