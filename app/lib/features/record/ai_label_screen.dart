import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../tasting_note/repositories/tasting_note_repository.dart';
import '../tasting_note/screens/tasting_note_detail_screen.dart';
import '../collection/repositories/sake_repository.dart';

enum _CaptureStage { idle, captured, analyzing }

// AI 解析結果スキーマ
final _sakeLabelSchema = Schema.object(
  properties: {
    'brand': Schema.string(description: '日本酒の銘柄名（例：獺祭、新政）'),
    'brewery': Schema.string(description: '蔵元の名前（例：旭酒造、新政酒造）'),
    'prefecture': Schema.string(
        description: '蔵元の所在都道府県。正式名称（例：京都府、新潟県）'),
    'tags': Schema.array(
      items: Schema.string(),
      description: '特定名称・酒米・精米歩合・製法・フレーバー等のスペック',
    ),
  },
);

const _labelPrompt =
    '添付された日本酒のラベル画像から、銘柄(brand)・蔵元(brewery)・'
    '蔵元の所在都道府県(prefecture)を読み取ってください。'
    '都道府県は「青森県」「京都府」「東京都」「大阪府」のような正式名称で返してください。'
    'それ以外のスペック（特定名称、酒米、精米歩合、製法、フレーバーなど）はすべて tags 配列に抽出してください。'
    '値が読み取れない場合は空文字または空配列にしてください。';

class AiLabelScreen extends StatefulWidget {
  const AiLabelScreen({super.key});

  @override
  State<AiLabelScreen> createState() => _AiLabelScreenState();
}

class _AiLabelScreenState extends State<AiLabelScreen> {
  _CaptureStage _stage = _CaptureStage.idle;
  Uint8List? _imageBytes;
  String? _errorMessage;

  final _noteRepo = TastingNoteRepository();
  final _sakeRepo = SakeRepository();

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
      _imageBytes = null;
      _stage = _CaptureStage.idle;
    });
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _stage = _CaptureStage.captured;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _analyzeAndSave() async {
    if (_imageBytes == null) return;
    setState(() {
      _stage = _CaptureStage.analyzing;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーが認証されていません');
      final userId = user.uid;
      final imageId = const Uuid().v4();
      final storagePath = 'user_uploads/$userId/$imageId.jpg';

      // firebase_ai による解析 と Storage アップロードを並列実行
      final model = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-3.1-flash-lite',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _sakeLabelSchema,
        ),
      );

      final results = await Future.wait([
        // AI 解析
        model.generateContent([
          Content.multi([
            TextPart(_labelPrompt),
            InlineDataPart('image/jpeg', _imageBytes!),
          ]),
        ]),
        // Storage アップロード
        FirebaseStorage.instance
            .ref()
            .child(storagePath)
            .putData(_imageBytes!)
            .then((_) => FirebaseStorage.instance
                .ref()
                .child(storagePath)
                .getDownloadURL()),
      ]);

      final aiResponse = results[0] as GenerateContentResponse;
      final imageUrl = results[1] as String;

      // AI 結果をパース
      final raw = jsonDecode(aiResponse.text ?? '{}') as Map<String, dynamic>;
      final brand = raw['brand'] as String? ?? '';
      final brewery = raw['brewery'] as String? ?? '';
      final prefecture = raw['prefecture'] as String? ?? '';
      final tags = List<String>.from(raw['tags'] as List? ?? []);

      final drankAt = DateTime.now();

      // sakes upsert + tasting_note 作成
      final sakeId = await _sakeRepo.upsertSake(
        userId: userId,
        brand: brand,
        brewery: brewery,
        prefecture: prefecture,
        category: 'sake',
        imageUrl: imageUrl,
        drankAt: drankAt,
      );

      final noteId = await _noteRepo.createNote(
        userId: userId,
        imageUrl: imageUrl,
        brand: brand,
        brewery: brewery,
        prefecture: prefecture,
        tags: tags,
        sakeId: sakeId,
        drankAt: drankAt,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TastingNoteDetailScreen(
            userId: userId,
            noteId: noteId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = _CaptureStage.captured;
          _errorMessage = 'エラーが発生しました。もう一度お試しください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBody(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildBackButton(),
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

  Widget _buildBody() {
    return switch (_stage) {
      _CaptureStage.idle => _buildIdleView(),
      _CaptureStage.captured => _buildCapturedView(),
      _CaptureStage.analyzing => _buildAnalyzingView(),
    };
  }

  Widget _buildIdleView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF1A1A20)],
              ),
            ),
            child: CustomPaint(
              painter: _ViewfinderPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        _buildCameraControls(),
      ],
    );
  }

  Widget _buildCapturedView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: kAccentGlow,
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildCameraControls(),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: kAccentMain,
              backgroundColor: kAccentSoft,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text('AIが解析中…', style: AppTextStyles.headingSmall()),
          const SizedBox(height: 8),
          const Text(
            'ラベルを認識しています',
            style: TextStyle(fontSize: 12, color: kTextSub),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      color: const Color(0xFF0C0C12),
      padding: EdgeInsets.only(
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
        left: 48,
        right: 48,
      ),
      child: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style:
                    const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_stage == _CaptureStage.captured)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kSurface2,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBorderDefault),
                    ),
                    child:
                        const Icon(Icons.refresh, color: kTextSub, size: 22),
                  ),
                )
              else
                const SizedBox(width: 44),
              _buildShutterButton(),
              if (_stage == _CaptureStage.captured)
                GestureDetector(
                  onTap: _analyzeAndSave,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kAccentSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: kAccentMain),
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: kAccentMain, size: 22),
                  ),
                )
              else
                const SizedBox(width: 44),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _stage == _CaptureStage.idle ? _pickImage : null,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: _stage == _CaptureStage.captured ? kAccentMain : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 4,
          ),
        ),
        child: _stage == _CaptureStage.captured
            ? const Icon(Icons.check, color: Colors.black, size: 30)
            : const Icon(Icons.camera_alt, color: Colors.black, size: 30),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height), gridPaint);
    canvas.drawLine(Offset(2 * size.width / 3, 0),
        Offset(2 * size.width / 3, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), gridPaint);

    const frameW = 180.0;
    const frameH = 260.0;
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2;

    final framePaint = Paint()
      ..color = kAccentSoft
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(left, top, frameW, frameH), framePaint);

    final bracketPaint = Paint()
      ..color = kAccentMain
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const len = 24.0;

    for (final (cx, cy, dx, dy) in [
      (left, top, 1.0, 1.0),
      (left + frameW, top, -1.0, 1.0),
      (left, top + frameH, 1.0, -1.0),
      (left + frameW, top + frameH, -1.0, -1.0),
    ]) {
      canvas.drawLine(Offset(cx, cy), Offset(cx + len * dx, cy), bracketPaint);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy + len * dy), bracketPaint);
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: 'ラベルをフレームに合わせてください',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: frameW - 20);
    iconPainter.paint(
      canvas,
      Offset(centerX - iconPainter.width / 2, centerY + 20),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
