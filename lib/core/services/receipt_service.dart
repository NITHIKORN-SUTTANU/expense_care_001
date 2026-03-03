import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Handles picking, compressing, uploading, and deleting receipt images
/// stored at `receipts/{uid}/{expenseId}.jpg` in Firebase Storage.
class ReceiptService {
  ReceiptService._();
  static final instance = ReceiptService._();

  final _picker = ImagePicker();

  /// Opens [source] (camera or gallery) and returns the chosen [File],
  /// or null if the user cancelled.
  Future<File?> pick(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return xfile == null ? null : File(xfile.path);
  }

  /// Compresses [file] and uploads it to Firebase Storage under
  /// `receipts/[uid]/[expenseId].jpg`.  Returns the public download URL.
  Future<String> upload(String uid, String expenseId, File file) async {
    final bytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 70,
      format: CompressFormat.jpeg,
    );
    if (bytes == null) throw Exception('Image compression failed');

    final ref =
        FirebaseStorage.instance.ref('receipts/$uid/$expenseId.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Removes the receipt from Firebase Storage.
  /// Ignores errors if the file does not exist.
  Future<void> delete(String uid, String expenseId) async {
    try {
      await FirebaseStorage.instance
          .ref('receipts/$uid/$expenseId.jpg')
          .delete();
    } catch (_) {
      // Not found or already deleted — harmless.
    }
  }
}
