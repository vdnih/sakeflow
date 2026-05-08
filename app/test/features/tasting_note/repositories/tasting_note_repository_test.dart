import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/features/tasting_note/repositories/tasting_note_repository.dart';

void main() {
  const userId = 'user-001';
  late FakeFirebaseFirestore fakeFirestore;
  late TastingNoteRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = TastingNoteRepository(db: fakeFirestore);
  });

  group('TastingNoteRepository.createNote', () {
    test('ノートが Firestore に作成される', () async {
      final noteId = await repo.createNote(
        userId: userId,
        imageUrl: 'https://example.com/image.jpg',
        brand: '獺祭',
        brewery: '旭酒造',
        prefecture: '山口県',
        tags: ['純米大吟醸'],
        sakeId: 'sake-001',
        drankAt: DateTime(2024, 6, 15),
      );

      expect(noteId, isNotEmpty);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('tasting_notes')
          .doc(noteId)
          .get();
      expect(doc.exists, true);
      expect(doc.data()!['brand'], '獺祭');
      expect(doc.data()!['brewery'], '旭酒造');
      expect(doc.data()!['prefecture'], '山口県');
    });

    test('各呼び出しで一意の noteId が生成される', () async {
      final id1 = await repo.createNote(
        userId: userId,
        imageUrl: '',
        brand: '銘柄A',
        brewery: '蔵元A',
        prefecture: '新潟県',
        tags: [],
        sakeId: 'sake-A',
        drankAt: DateTime.now(),
      );
      final id2 = await repo.createNote(
        userId: userId,
        imageUrl: '',
        brand: '銘柄B',
        brewery: '蔵元B',
        prefecture: '秋田県',
        tags: [],
        sakeId: 'sake-B',
        drankAt: DateTime.now(),
      );
      expect(id1, isNot(id2));
    });
  });

  group('TastingNoteRepository.watchNote', () {
    test('作成したノートをストリームで取得できる', () async {
      final noteId = await repo.createNote(
        userId: userId,
        imageUrl: '',
        brand: '新政',
        brewery: '新政酒造',
        prefecture: '秋田県',
        tags: ['自然派'],
        sakeId: 'sake-002',
        drankAt: DateTime(2024, 5, 1),
      );

      final stream = repo.watchNote(userId, noteId);
      final note = await stream.first;

      expect(note.noteId, noteId);
      expect(note.brand, '新政');
      expect(note.prefecture, '秋田県');
    });
  });

  group('TastingNoteRepository.updateEditableFields', () {
    test('フィールドが正しく更新される', () async {
      final noteId = await repo.createNote(
        userId: userId,
        imageUrl: '',
        brand: '旧銘柄',
        brewery: '旧蔵元',
        prefecture: '東京都',
        tags: [],
        sakeId: 'sake-003',
        drankAt: DateTime.now(),
      );

      await repo.updateEditableFields(
        userId: userId,
        noteId: noteId,
        brand: '新銘柄',
        brewery: '新蔵元',
        prefecture: '神奈川県',
        tags: ['純米'],
        rating: 4.0,
        note: '美味しかった',
        drankLocally: true,
      );

      final stream = repo.watchNote(userId, noteId);
      final updated = await stream.first;

      expect(updated.brand, '新銘柄');
      expect(updated.brewery, '新蔵元');
      expect(updated.prefecture, '神奈川県');
      expect(updated.tags, ['純米']);
      expect(updated.rating, 4.0);
      expect(updated.note, '美味しかった');
      expect(updated.drankLocally, true);
    });
  });

  group('TastingNoteRepository.listNotes', () {
    test('drank_at 降順でノートが返される', () async {
      await repo.createNote(
        userId: userId,
        imageUrl: '',
        brand: '古い銘柄',
        brewery: '蔵元',
        prefecture: '東京都',
        tags: [],
        sakeId: 'sake-old',
        drankAt: DateTime(2024, 1, 1),
      );
      await repo.createNote(
        userId: userId,
        imageUrl: '',
        brand: '新しい銘柄',
        brewery: '蔵元',
        prefecture: '大阪府',
        tags: [],
        sakeId: 'sake-new',
        drankAt: DateTime(2024, 12, 31),
      );

      final notes = await repo.listNotes(userId).first;

      expect(notes.length, 2);
      expect(notes.first.brand, '新しい銘柄');
      expect(notes.last.brand, '古い銘柄');
    });

    test('ノートが 0 件でも空リストを返す', () async {
      final notes = await repo.listNotes('empty-user').first;
      expect(notes, isEmpty);
    });
  });
}
