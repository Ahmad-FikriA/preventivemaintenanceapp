import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService{
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadInstanceImage({
    required String instanceId,
    required String fieldKey,
    required File file,
  }) async {
    final ext = p.extension(file.path);
    final name = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = _storage.ref('instances/$instanceId/$fieldKey/$name');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}