import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/bottle_placeholder.dart';
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
      backgroundColor: kBgBase,
      body: StreamBuilder<List<TastingNote>>(
        stream: noteRepo.listNotes(user.uid),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroSection(user: user, notes: notes),
              ),
              SliverToBoxAdapter(
                child: _StatsRow(notes: notes),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(noteCount: notes.length),
              ),
              if (notes.isEmpty)
                const SliverToBoxAdapter(child: _EmptyNotesState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TastingNoteCard(
                        note: notes[i],
                        userId: user.uid,
                      ),
                      childCount: notes.take(10).length,
                    ),
                  ),
                ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final User user;
  final List<TastingNote> notes;

  const _HeroSection({required this.user, required this.notes});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kSurface1, kBgBase],
        ),
      ),
      padding: EdgeInsets.only(
        top: top + 20,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAKEFLOW',
                  style: TextStyle(
                    fontSize: 11,
                    color: kTextSub,
                    letterSpacing: 0.08 * 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.headingLarge(),
                    children: [
                      const TextSpan(text: 'おかえりなさい\n'),
                      TextSpan(
                        text: user.displayName ?? 'ゲスト',
                        style: const TextStyle(color: kAccentMain),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [kAccentSoft, kAccentGlow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: user.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          user.photoURL!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Text('🍶', style: TextStyle(fontSize: 20)),
                      ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => FirebaseAuth.instance.signOut(),
                child: const Icon(Icons.logout, size: 16, color: kTextMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<TastingNote> notes;

  const _StatsRow({required this.notes});

  @override
  Widget build(BuildContext context) {
    final recordCount = notes.length;
    final brandCount = notes
        .map((n) => n.brand)
        .where((b) => b.isNotEmpty)
        .toSet()
        .length;
    final prefCount = notes
        .map((n) => n.prefecture)
        .where((p) => p.isNotEmpty)
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _StatCard(value: recordCount, unit: '本', label: '記録'),
          const SizedBox(width: 10),
          _StatCard(value: brandCount, unit: '銘柄', label: 'コレクション'),
          const SizedBox(width: 10),
          _StatCard(value: prefCount, unit: '箇所', label: '都道府県'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String unit;
  final String label;

  const _StatCard({
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kAccentMain,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Text(unit,
                style: const TextStyle(fontSize: 10, color: kTextSub)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: kTextMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int noteCount;

  const _SectionHeader({required this.noteCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Text('最近の記録', style: AppTextStyles.headingMedium()),
          const Spacer(),
          if (noteCount > 10)
            const Text(
              'すべて見る',
              style: TextStyle(fontSize: 12, color: kAccentMain),
            ),
        ],
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.liquor_outlined, size: 48, color: kTextMuted),
            const SizedBox(height: 12),
            Text('まだ記録がありません',
                style: TextStyle(color: kTextSub, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('中央のボタンからお酒を記録してみましょう',
                style: TextStyle(color: kTextMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TastingNoteCard extends StatefulWidget {
  final TastingNote note;
  final String userId;

  const _TastingNoteCard({required this.note, required this.userId});

  @override
  State<_TastingNoteCard> createState() => _TastingNoteCardState();
}

class _TastingNoteCardState extends State<_TastingNoteCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TastingNoteDetailScreen(
                userId: widget.userId,
                noteId: widget.note.noteId,
              ),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: _hovered
                ? (Matrix4.identity()..translate(0.0, -1.0))
                : Matrix4.identity(),
            decoration: BoxDecoration(
              color: _hovered ? kSurface3 : kSurface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _hovered ? kBorderHover : kBorderDefault),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildThumbnail(),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfo()),
                  const SizedBox(width: 8),
                  const Icon(
                      Icons.chevron_right, size: 16, color: kTextMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return SizedBox(
      width: 64,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.note.imageUrl.isNotEmpty
                ? Image.network(
                    widget.note.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => BottlePlaceholder(
                      brand: widget.note.brand,
                      width: 64,
                      height: 80,
                      borderRadius: 10,
                    ),
                  )
                : BottlePlaceholder(
                    brand: widget.note.brand,
                    width: 64,
                    height: 80,
                    borderRadius: 10,
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x80000000)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    final note = widget.note;
    final date =
        '${note.drankAt.year}/${note.drankAt.month.toString().padLeft(2, '0')}/${note.drankAt.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (note.category.isNotEmpty)
              _CategoryBadge(category: note.category),
            if (note.category.isNotEmpty && note.prefecture.isNotEmpty)
              const SizedBox(width: 4),
            if (note.prefecture.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on,
                      size: 10, color: kTextMuted),
                  Text(
                    note.prefecture,
                    style: const TextStyle(
                        fontSize: 10, color: kTextMuted),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          note.brand.isNotEmpty ? note.brand : '（解析中）',
          style: AppTextStyles.headingSmall(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        if (note.brewery.isNotEmpty)
          Text(
            note.brewery,
            style: const TextStyle(fontSize: 11, color: kTextSub),
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (note.rating != null) ...[
              _StarRow(rating: note.rating!),
              const SizedBox(width: 8),
            ],
            Text(
              date,
              style: const TextStyle(fontSize: 11, color: kTextMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: kAccentSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: kAccentMain,
          letterSpacing: 0.54,
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;

  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i + 1 <= rating;
        final half = !full && i + 0.5 <= rating;
        return Icon(
          full
              ? Icons.star
              : half
                  ? Icons.star_half
                  : Icons.star_border,
          size: 12,
          color: kAccentMain,
        );
      }),
    );
  }
}
