import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Sube la foto de perfil a avatars/{uid}/avatar.jpg (ver
  /// firebase/storage.rules: solo el dueño puede escribir ahí, máx 5MB,
  /// solo jpg/png/webp) y devuelve la URL pública de descarga.
  Future<String> uploadAvatar({required String uid, required File file}) async {
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final ref = _storage.ref('avatars/$uid/avatar.$ext');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
