import 'package:image_picker/image_picker.dart';
import '../constants/image_config.dart';

/// Handles picking receipt images from camera or gallery.
/// Images are stored as Base64 directly on the Firestore expense document
/// (no Firebase Storage required).
class ReceiptService {
  ReceiptService._();
  static final instance = ReceiptService._();

  final _picker = ImagePicker();

  /// Opens [source] (camera or gallery) and returns an [XFile],
  /// or null if the user cancelled. Compresses based on ImageConfig settings.
  Future<XFile?> pick(ImageSource source) async {
    return _picker.pickImage(
      source: source,
      maxWidth: ImageConfig.maxWidth.toDouble(),
      maxHeight: ImageConfig.maxHeight.toDouble(),
      imageQuality: ImageConfig.quality,
    );
  }
}
