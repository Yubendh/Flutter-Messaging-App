import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<String> uploadProfilePicture(File file) async {
    final ref = _storage.ref().child('profile_pictures/$_uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadChatImage(String groupId, File file) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('chat_images/$groupId/$name');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadChatFile(String groupId, File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot) : '';
    final safeExt = ext.isEmpty ? '' : ext;
    final name = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final ref = _storage.ref().child('chat_files/$groupId/$name');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadDirectMessageImage(String conversationId, File file) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('direct_message_images/$conversationId/$name');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadDirectMessageFile(String conversationId, File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot) : '';
    final safeExt = ext.isEmpty ? '' : ext;
    final name = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final ref = _storage.ref().child('direct_message_files/$conversationId/$name');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<({String url, String storagePath})> uploadResourceFile(
    String groupId,
    File file,
    String originalFileName, {
    void Function(double progress)? onProgress,
  }) async {
    final safeName = originalFileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path = 'resource_files/$groupId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref().child(path);
    final task = ref.putFile(file);
    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
    }
    await task;
    final url = await ref.getDownloadURL();
    return (url: url, storagePath: path);
  }

  Future<void> deleteResourceFile(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
  }
}
