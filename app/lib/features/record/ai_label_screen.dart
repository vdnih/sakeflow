import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tasting_note/repositories/tasting_note_repository.dart';
import '../tasting_note/screens/tasting_note_detail_screen.dart';

class AiLabelScreen extends StatefulWidget {
  const AiLabelScreen({super.key});

  @override
  State<AiLabelScreen> createState() => _AiLabelScreenState();
}

class _AiLabelScreenState extends State<AiLabelScreen> {
  Uint8List? _imageBytes;
  bool _uploading = false;
  String? _errorMessage;

  final _noteRepo = TastingNoteRepository();

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
      _imageBytes = null;
    });
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _saveAndAnalyze() async {
    if (_imageBytes == null) return;
    setState(() {
      _uploading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーが認証されていません');
      final userId = user.uid;
      final jobId = const Uuid().v4();

      // 1. Storageへアップロード
      final storagePath = 'user_uploads/$userId/$jobId.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putData(_imageBytes!);
      final imageUrl = await storageRef.getDownloadURL();

      // 2. ai_label_job を作成（Storage トリガーが AI 解析を開始）
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

      // 3. tasting_note を "processing" 状態で作成
      final noteId = await _noteRepo.createNote(
        userId: userId,
        imageUrl: imageUrl,
        jobId: jobId,
        drankAt: now.toDate(),
      );

      if (!mounted) return;
      // 4. 詳細画面へ遷移（バックグラウンドで解析が進む）
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
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIラベル認識'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageBytes == null
                ? const Text('カメラでラベルを撮影してください')
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_imageBytes!, height: 240),
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('カメラで撮影'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: (_imageBytes != null && !_uploading)
                      ? _saveAndAnalyze
                      : null,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('保存して解析開始'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SelectableText(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
