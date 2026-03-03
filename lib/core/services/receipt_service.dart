import 'package:image_picker/image_picker.dart';

/// Handles picking receipt images from camera or gallery.
/// Images are stored as Base64 directly on the Firestore expense document
/// (no Firebase Storage required).
class ReceiptService {
  ReceiptService._();
  static final instance = ReceiptService._();

  final _picker = ImagePicker();

  /// Opens [source] (camera or gallery) and returns an [XFile],
  /// or null if the user cancelled. Compresses to ~70% quality at pick time.
  Future<XFile?> pick(ImageSource source) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
  }
}
