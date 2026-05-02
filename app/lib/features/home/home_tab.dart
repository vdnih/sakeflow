import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tasting_note/models/tasting_note.dart';
import '../tasting_note/repositories/tasting_note_repository.dart';
import '../tasting_note/screens/tasting_note_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final noteRepo = TastingNoteRepository();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sakeflow Logs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? const Icon(Icons.person, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ようこそ、${user.displayName ?? 'ゲスト'}さん',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.deepPurple),
                      tooltip: 'ログアウト',
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '最近の記録',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<TastingNote>>(
              stream: noteRepo.listNotes(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('エラー: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final notes = snapshot.data!;
                if (notes.isEmpty) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.liquor_outlined,
                                size: 48, color: Colors.deepPurple),
                            SizedBox(height: 12),
                            Text(
                              'まだ記録がありません',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '右下のボタンからお酒を記録してみましょう',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: notes
                      .take(10)
                      .map((note) => _TastingNoteCard(
                            note: note,
                            userId: user.uid,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TastingNoteCard extends StatelessWidget {
  final TastingNote note;
  final String userId;

  const _TastingNoteCard({required this.note, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TastingNoteDetailScreen(
                userId: userId,
                noteId: note.noteId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: note.imageUrl.isNotEmpty
                    ? Image.network(
                        note.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (note.status == TastingNoteStatus.processing)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '解析中',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.orange),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            note.brand.isNotEmpty ? note.brand : '（解析中）',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (note.brewery.isNotEmpty)
                      Text(
                        note.brewery,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${note.drankAt.year}/${note.drankAt.month.toString().padLeft(2, '0')}/${note.drankAt.day.toString().padLeft(2, '0')}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        if (note.rating != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(
                            note.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.amber),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.liquor_outlined, color: Colors.grey),
    );
  }
}
