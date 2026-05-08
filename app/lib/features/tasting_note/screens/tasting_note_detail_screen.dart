import 'package:flutter/material.dart';
import '../models/tasting_note.dart';
import '../repositories/tasting_note_repository.dart';
import '../../collection/repositories/sake_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/bottle_placeholder.dart';

class TastingNoteDetailScreen extends StatefulWidget {
  final String userId;
  final String noteId;

  const TastingNoteDetailScreen({
    super.key,
    required this.userId,
    required this.noteId,
  });

  @override
  State<TastingNoteDetailScreen> createState() =>
      _TastingNoteDetailScreenState();
}

class _TastingNoteDetailScreenState
    extends State<TastingNoteDetailScreen> {
  final _noteRepo = TastingNoteRepository();
  final _sakeRepo = SakeRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _brandCtrl;
  late TextEditingController _breweryCtrl;
  late TextEditingController _prefectureCtrl;
  late TextEditingController _noteCtrl;
  List<String> _tags = [];
  double _rating = 0;
  bool _drankLocally = false;
  bool _saving = false;
  bool _saved = false;
  bool _formInitialized = false;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController();
    _breweryCtrl = TextEditingController();
    _prefectureCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _breweryCtrl.dispose();
    _prefectureCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _populateForm(TastingNote note) {
    if (!_formInitialized && note.brand.isNotEmpty) {
      _brandCtrl.text = note.brand;
      _breweryCtrl.text = note.brewery;
      _prefectureCtrl.text = note.prefecture;
      _tags = List.from(note.tags);
      _rating = note.rating ?? 0;
      _noteCtrl.text = note.note ?? '';
      _drankLocally = note.drankLocally;
      _formInitialized = true;
    }
  }

  Future<void> _save(TastingNote current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final batch = <Future>[];
      batch.add(_noteRepo.updateEditableFields(
        userId: widget.userId,
        noteId: widget.noteId,
        brand: _brandCtrl.text.trim(),
        brewery: _breweryCtrl.text.trim(),
        prefecture: _prefectureCtrl.text.trim(),
        tags: _tags,
        rating: _rating > 0 ? _rating : null,
        note: _noteCtrl.text.trim().isNotEmpty
            ? _noteCtrl.text.trim()
            : null,
        drankLocally: _drankLocally,
      ));

      if (current.sakeId != null &&
          (current.brand != _brandCtrl.text.trim() ||
              current.brewery != _breweryCtrl.text.trim() ||
              current.prefecture != _prefectureCtrl.text.trim())) {
        batch.add(_sakeRepo.updateSake(
          userId: widget.userId,
          sakeId: current.sakeId!,
          brand: _brandCtrl.text.trim(),
          brewery: _breweryCtrl.text.trim(),
          prefecture: _prefectureCtrl.text.trim(),
        ));
      }

      await Future.wait(batch);

      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBase,
      body: StreamBuilder<TastingNote>(
        stream: _noteRepo.watchNote(widget.userId, widget.noteId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('エラー: ${snapshot.error}',
                    style: const TextStyle(color: kTextSub)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final note = snapshot.data!;
          _populateForm(note);
          return _buildReadyView(note);
        },
      ),
    );
  }

  Widget _buildReadyView(TastingNote note) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(note),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.tags.isNotEmpty) _buildTagsDisplay(note),
                      if (note.tags.isNotEmpty)
                        const SizedBox(height: 20),
                      _buildSectionCard(
                        title: '銘柄情報',
                        child: Column(
                          children: [
                            _buildTextField(_brandCtrl, '銘柄名',
                                required: true),
                            const SizedBox(height: 10),
                            _buildTextField(_breweryCtrl, '蔵元'),
                            const SizedBox(height: 10),
                            _buildTextField(
                              _prefectureCtrl,
                              '都道府県',
                              prefix: const Icon(Icons.location_on,
                                  size: 16, color: kTextMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: 'タグ',
                        child: _buildTagsEditor(),
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: '評価',
                        child: _buildRatingSelector(),
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: 'メモ（任意）',
                        child: _buildNoteField(),
                      ),
                      const SizedBox(height: 12),
                      _buildDrankLocallyToggle(),
                      const SizedBox(height: 24),
                      _buildSaveButton(note),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _buildBackButton(),
        ),
      ],
    );
  }

  Widget _buildHero(TastingNote note) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          note.imageUrl.isNotEmpty
              ? Image.network(
                  note.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: bottleColor(note.brand),
                    child: const Center(
                      child: Icon(Icons.liquor_outlined,
                          size: 64, color: kTextMuted),
                    ),
                  ),
                )
              : Container(
                  color: bottleColor(note.brand),
                  child: const Center(
                    child: Icon(Icons.liquor_outlined,
                        size: 64, color: kTextMuted),
                  ),
                ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6000000)],
                stops: [0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.category.isNotEmpty || note.prefecture.isNotEmpty)
                  Text(
                    [
                      if (note.category.isNotEmpty) note.category,
                      if (note.prefecture.isNotEmpty) note.prefecture,
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 10,
                      color: kAccentMain,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  note.brand.isNotEmpty ? note.brand : '解析中...',
                  style: AppTextStyles.headingLarge(color: Colors.white),
                ),
                if (note.brewery.isNotEmpty)
                  Text(
                    note.brewery,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x99FFFFFF)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: kBorderDefault),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildTagsDisplay(TastingNote note) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: note.tags
          .map((tag) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kAccentSoft,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: kAccentGlow),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: kAccentMain,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSectionCard(
      {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  color: kTextMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.66)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    Widget? prefix,
  }) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: kTextPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$labelを入力してください' : null
          : null,
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteCtrl,
      style: const TextStyle(
          color: kTextPrimary, fontSize: 13, height: 1.7),
      maxLines: 4,
      maxLength: 1000,
      decoration: const InputDecoration(
        hintText: '感想・テイスティングメモ',
        counterStyle: TextStyle(color: kTextMuted, fontSize: 10),
      ),
    );
  }

  Widget _buildTagsEditor() {
    final tagCtrl = TextEditingController();
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          deleteIcon:
                              const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() => _tags.remove(tag));
                          },
                        ))
                    .toList(),
              ),
            if (_tags.isNotEmpty) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagCtrl,
                    style: const TextStyle(
                        color: kTextPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'タグを追加（例: 純米大吟醸）',
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      final t = v.trim();
                      if (t.isNotEmpty && !_tags.contains(t)) {
                        setState(() => _tags.add(t));
                        tagCtrl.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final t = tagCtrl.text.trim();
                    if (t.isNotEmpty && !_tags.contains(t)) {
                      setState(() => _tags.add(t));
                      tagCtrl.clear();
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: kAccentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        color: kAccentMain, size: 18),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      children: List.generate(5, (i) {
        final value = (i + 1).toDouble();
        final selected = _rating >= value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: GestureDetector(
              onTap: () => setState(() => _rating = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? kAccentMain : kSurface3,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    selected ? Icons.star : Icons.star_border,
                    size: 16,
                    color: selected ? Colors.black : kTextMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDrankLocallyToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('現地で飲んだ',
                    style: AppTextStyles.headingSmall()),
                const SizedBox(height: 2),
                const Text(
                  '産地の都道府県で飲んだ場合にオン',
                  style: TextStyle(fontSize: 11, color: kTextSub),
                ),
              ],
            ),
          ),
          Switch(
            value: _drankLocally,
            activeColor: Colors.white,
            activeTrackColor: kAccentMain,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: kSurface3,
            onChanged: (v) async {
              if (v) {
                await _confirmDrankLocally();
              } else {
                setState(() => _drankLocally = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDrankLocally() async {
    final pref = _prefectureCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    if (pref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('先に都道府県を入力してください'),
            backgroundColor: kSurface2),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface2,
        title: Text('現地で飲んだ記録',
            style: AppTextStyles.headingSmall()),
        content: Text(
          '${brand.isNotEmpty ? brand : 'このお酒'}は$prefのお酒です。\n$prefでこのお酒を飲んだ記録をしますか？',
          style: const TextStyle(color: kTextSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('いいえ',
                style: TextStyle(color: kTextSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('はい',
                style: TextStyle(color: kAccentMain)),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => _drankLocally = true);
  }

  Widget _buildSaveButton(TastingNote note) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _saved ? kAccentSoft : kAccentMain,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: (_saving || _saved) ? null : () => _save(note),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black),
                    )
                  : Text(
                      _saved ? '✓ 保存しました' : '保存する',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _saved ? kAccentMain : Colors.black,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
