import 'package:flutter/material.dart';
import '../models/tasting_note.dart';
import '../repositories/tasting_note_repository.dart';
import '../../collection/repositories/sake_repository.dart';

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

class _TastingNoteDetailScreenState extends State<TastingNoteDetailScreen> {
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

  bool _formInitialized = false;

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

      // tasting_note を更新
      batch.add(_noteRepo.updateEditableFields(
        userId: widget.userId,
        noteId: widget.noteId,
        brand: _brandCtrl.text.trim(),
        brewery: _breweryCtrl.text.trim(),
        prefecture: _prefectureCtrl.text.trim(),
        tags: _tags,
        rating: _rating > 0 ? _rating : null,
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
        drankLocally: _drankLocally,
      ));

      // sake も同期（銘柄名が変わっていれば sake 側も更新）
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テイスティングノート'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<TastingNote>(
        stream: _noteRepo.watchNote(widget.userId, widget.noteId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final note = snapshot.data!;
          _populateForm(note);

          if (note.status == TastingNoteStatus.processing) {
            return _buildProcessingView(note);
          }
          if (note.status == TastingNoteStatus.failed) {
            return _buildFailedView();
          }
          return _buildReadyView(note);
        },
      ),
    );
  }

  Widget _buildProcessingView(TastingNote note) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (note.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(note.imageUrl, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'AIが解析中です...',
            style: TextStyle(fontSize: 16, color: Colors.deepPurple),
          ),
          const SizedBox(height: 8),
          Text(
            '解析完了後に評価やメモを入力できます',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ホームに戻る（後から編集できます）'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 12),
          Text('AI解析に失敗しました', style: TextStyle(color: Colors.red)),
          SizedBox(height: 8),
          Text('手動で銘柄情報を入力してください',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildReadyView(TastingNote note) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  note.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '${note.drankAt.year}/${note.drankAt.month.toString().padLeft(2, '0')}/${note.drankAt.day.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('銘柄情報'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                labelText: '銘柄名',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '銘柄名を入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breweryCtrl,
              decoration: const InputDecoration(
                labelText: '蔵元',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prefectureCtrl,
              decoration: const InputDecoration(
                labelText: '都道府県',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            _buildDrankLocallyCheckbox(),
            const SizedBox(height: 16),
            _buildSectionLabel('タグ'),
            const SizedBox(height: 8),
            _buildTagsEditor(),
            const SizedBox(height: 16),
            _buildSectionLabel('評価'),
            const SizedBox(height: 8),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            _buildSectionLabel('メモ（任意）'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                hintText: '感想・テイスティングメモ',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 1000,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(note),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('保存する', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
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
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.deepPurple[50],
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      hintText: 'タグを追加（例: 純米大吟醸）',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      final trimmed = v.trim();
                      if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
                        setState(() => _tags.add(trimmed));
                        tagCtrl.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.deepPurple),
                  onPressed: () {
                    final trimmed = tagCtrl.text.trim();
                    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
                      setState(() => _tags.add(trimmed));
                      tagCtrl.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrankLocallyCheckbox() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CheckboxListTile(
        value: _drankLocally,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.deepPurple,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: const Text('現地で飲んだ'),
        subtitle: const Text(
          '産地の都道府県で飲んだ場合にチェック',
          style: TextStyle(fontSize: 11),
        ),
        onChanged: (value) async {
          if (value == true) {
            await _confirmDrankLocally();
          } else {
            setState(() => _drankLocally = false);
          }
        },
      ),
    );
  }

  Future<void> _confirmDrankLocally() async {
    final pref = _prefectureCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    if (pref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に都道府県を入力してください')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('現地で飲んだ記録'),
        content: Text(
          '${brand.isNotEmpty ? brand : 'このお酒'}は$prefのお酒です。\n$prefでこのお酒を飲んだ記録をしますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('はい'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _drankLocally = true);
    }
  }

  Widget _buildRatingSelector() {
    return Row(
      children: List.generate(5, (i) {
        final starValue = (i + 1).toDouble();
        final halfValue = i + 0.5;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _rating = halfValue),
              child: Icon(
                _rating >= starValue
                    ? Icons.star
                    : _rating >= halfValue
                        ? Icons.star_half
                        : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            ),
          ],
        );
      }),
    );
  }
}
