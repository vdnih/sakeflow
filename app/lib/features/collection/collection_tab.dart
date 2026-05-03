import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/bottle_placeholder.dart';
import 'models/sake.dart';
import 'repositories/sake_repository.dart';
import '../tasting_note/models/tasting_note.dart';
import '../tasting_note/repositories/tasting_note_repository.dart';

class CollectionTab extends StatefulWidget {
  const CollectionTab({super.key});

  @override
  State<CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends State<CollectionTab> {
  String _selectedCategory = 'すべて';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final sakeRepo = SakeRepository();
    final noteRepo = TastingNoteRepository();

    return Scaffold(
      backgroundColor: kBgBase,
      body: StreamBuilder<List<TastingNote>>(
        stream: noteRepo.listNotes(user.uid),
        builder: (context, notesSnap) {
          final notes = notesSnap.data ?? [];
          final categories = [
            'すべて',
            ...{
              ...notes
                  .map((n) => n.category)
                  .where((c) => c.isNotEmpty)
            }
          ];

          return StreamBuilder<List<Sake>>(
            stream: sakeRepo.listSakes(user.uid),
            builder: (context, sakesSnap) {
              if (!sakesSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allSakes = sakesSnap.data!;
              final filtered = _selectedCategory == 'すべて'
                  ? allSakes
                  : () {
                      final brands = notes
                          .where((n) => n.category == _selectedCategory)
                          .map((n) => n.brand)
                          .toSet();
                      return allSakes
                          .where((s) => brands.contains(s.brand))
                          .toList();
                    }();

              return _buildContent(
                  context, categories, filtered, allSakes.isEmpty);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<String> categories,
    List<Sake> sakes,
    bool allEmpty,
  ) {
    final top = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: kSurface1,
          expandedHeight: top + 88,
          collapsedHeight: 60,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.only(left: 20, bottom: 16),
            expandedTitleScale: 1.0,
            title: Text('コレクション', style: AppTextStyles.headingLarge()),
          ),
        ),
        SliverToBoxAdapter(
          child: _FilterChipsRow(
            categories: categories,
            selected: _selectedCategory,
            onChanged: (c) => setState(() => _selectedCategory = c),
          ),
        ),
        if (allEmpty)
          SliverFillRemaining(child: _EmptyCollectionState())
        else if (sakes.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'このカテゴリの記録はありません',
                style: const TextStyle(color: kTextSub, fontSize: 14),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _SakeCard(sake: sakes[i]),
                childCount: sakes.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChipsRow({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? kAccentMain : kSurface2,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? kAccentMain : kBorderDefault,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : kTextSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCollectionState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.liquor_outlined, size: 72, color: kTextMuted),
          const SizedBox(height: 16),
          Text('コレクション', style: AppTextStyles.headingMedium()),
          const SizedBox(height: 8),
          const Text(
            'まだコレクションがありません',
            style: TextStyle(color: kTextSub, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'お酒を記録するとここに表示されます',
            style: TextStyle(color: kTextMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SakeCard extends StatefulWidget {
  final Sake sake;

  const _SakeCard({required this.sake});

  @override
  State<_SakeCard> createState() => _SakeCardState();
}

class _SakeCardState extends State<_SakeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sake = widget.sake;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _hovered
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _hovered ? kBorderHover : kBorderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageArea(sake),
            _buildInfoArea(sake),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(Sake sake) {
    return SizedBox(
      height: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          sake.imageUrl.isNotEmpty
              ? Image.network(sake.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      BottlePlaceholder(
                        brand: sake.brand,
                        width: double.infinity,
                        height: 110,
                        borderRadius: 0,
                      ))
              : BottlePlaceholder(
                  brand: sake.brand,
                  width: double.infinity,
                  height: 110,
                  borderRadius: 0,
                ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: kAccentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '×${sake.tastingCount}回',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kAccentMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoArea(Sake sake) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sake.brand,
              style: AppTextStyles.headingSmall(),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (sake.prefecture.isNotEmpty) sake.prefecture,
                if (sake.brewery.isNotEmpty) sake.brewery,
              ].join(' · '),
              style: const TextStyle(fontSize: 10, color: kTextSub),
              overflow: TextOverflow.ellipsis,
            ),
            if (sake.avgRating != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final full = i + 1 <= sake.avgRating!;
                  return Icon(
                    full ? Icons.star : Icons.star_border,
                    size: 11,
                    color: kAccentMain,
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
