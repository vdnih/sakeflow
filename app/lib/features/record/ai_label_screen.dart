import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../tasting_note/repositories/tasting_note_repository.dart';
import '../tasting_note/screens/tasting_note_detail_screen.dart';

enum _CaptureStage { idle, captured, uploading, done }

class AiLabelScreen extends StatefulWidget {
  const AiLabelScreen({super.key});

  @override
  State<AiLabelScreen> createState() => _AiLabelScreenState();
}

class _AiLabelScreenState extends State<AiLabelScreen> {
  _CaptureStage _stage = _CaptureStage.idle;
  Uint8List? _imageBytes;
  String? _errorMessage;
  String? _pendingNoteId;

  final _noteRepo = TastingNoteRepository();

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
      _imageBytes = null;
      _stage = _CaptureStage.idle;
    });
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.camera);
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

  Future<void> _saveAndAnalyze() async {
    if (_imageBytes == null) return;
    setState(() {
      _stage = _CaptureStage.uploading;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーが認証されていません');
      final userId = user.uid;
      final jobId = const Uuid().v4();

      final storagePath = 'user_uploads/$userId/$jobId.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putData(_imageBytes!);
      final imageUrl = await storageRef.getDownloadURL();

      final now = Timestamp.now();
      await FirebaseFirestore.instance
          .collection('ai_label_jobs')
          .doc(jobId)
          .set({
        'job_id': jobId,
        'user_id': userId,
        'status': 'running',
        'image_url': imageUrl,
        'storage_path': storagePath,
        'created_at': now,
        'updated_at': now,
      });

      final noteId = await _noteRepo.createNote(
        userId: userId,
        imageUrl: imageUrl,
        jobId: jobId,
        drankAt: now.toDate(),
      );

      if (!mounted) return;
      setState(() {
        _stage = _CaptureStage.done;
        _pendingNoteId = noteId;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = _CaptureStage.idle;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _openNote() {
    if (_pendingNoteId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TastingNoteDetailScreen(
          userId: user.uid,
          noteId: _pendingNoteId!,
        ),
      ),
    );
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
      _CaptureStage.uploading => _buildUploadingView(),
      _CaptureStage.done => _buildDoneView(),
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

  Widget _buildUploadingView() {
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

  Widget _buildDoneView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: kAccentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: kAccentMain, size: 32),
          ),
          const SizedBox(height: 20),
          Text('アップロード完了！', style: AppTextStyles.headingSmall()),
          const SizedBox(height: 8),
          const Text(
            'AIがバックグラウンドで解析中です',
            style: TextStyle(fontSize: 12, color: kTextSub),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _openNote,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: kAccentMain,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'ノートを開く',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
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
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
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
                    child: const Icon(Icons.refresh,
                        color: kTextSub, size: 22),
                  ),
                )
              else
                const SizedBox(width: 44),
              _buildShutterButton(),
              if (_stage == _CaptureStage.captured)
                GestureDetector(
                  onTap: _saveAndAnalyze,
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
          color: _stage == _CaptureStage.captured
              ? kAccentMain
              : Colors.white,
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

    canvas.drawLine(
        Offset(size.width / 3, 0), Offset(size.width / 3, size.height), gridPaint);
    canvas.drawLine(
        Offset(2 * size.width / 3, 0),
        Offset(2 * size.width / 3, size.height),
        gridPaint);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);

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
      canvas.drawLine(
          Offset(cx, cy), Offset(cx + len * dx, cy), bracketPaint);
      canvas.drawLine(
          Offset(cx, cy), Offset(cx, cy + len * dy), bracketPaint);
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
