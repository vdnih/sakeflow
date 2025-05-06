import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiLabelScreen extends StatefulWidget {
  const AiLabelScreen({super.key});

  @override
  State<AiLabelScreen> createState() => _AiLabelScreenState();
}

class _AiLabelScreenState extends State<AiLabelScreen> {
  Uint8List? _imageBytes;
  String? _jobId;
  bool _uploading = false;
  bool _analyzing = false;
  String? _result;
  String? _errorMessage;

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
      _result = null;
      _jobId = null;
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

  Future<void> _uploadAndCreateJob() async {
    if (_imageBytes == null) return;
    setState(() {
      _uploading = true;
      _errorMessage = null;
      _result = null;
    });
    try {
      final jobId = const Uuid().v4();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーが認証されていません');
      final userId = user.uid;
      final storagePath = 'user_uploads/$userId/$jobId.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
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
      setState(() {
        _jobId = jobId;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  Future<void> _watchJobResult() async {
    if (_jobId == null) return;
    setState(() {
      _analyzing = true;
      _errorMessage = null;
      _result = null;
    });
    try {
      final docRef = FirebaseFirestore.instance
          .collection('ai_label_jobs')
          .doc(_jobId);
      docRef.snapshots().listen((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          final status = data['status'] as String?;
          if (status == 'success') {
            setState(() {
              _analyzing = false;
              _result =
                  data['result'] != null ? data['result'].toString() : '認識結果なし';
            });
          } else if (status == 'failed') {
            setState(() {
              _analyzing = false;
              _errorMessage = data['error']?.toString() ?? 'AI認識に失敗しました';
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _analyzing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIラベル認識'),
        backgroundColor: Colors.deepPurple,
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
                  onPressed: _uploading || _analyzing ? null : _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('カメラで撮影'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed:
                      (_imageBytes != null && !_uploading && !_analyzing)
                          ? () async {
                            await _uploadAndCreateJob();
                            await _watchJobResult();
                          }
                          : null,
                  icon: const Icon(Icons.cloud_upload),
                  label:
                      _uploading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('アップロード＆認識開始'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_result != null)
              Card(
                color: Colors.green[50],
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _result!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
