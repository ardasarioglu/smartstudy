import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class PickerService {
  final ImagePicker _picker = ImagePicker();
  var logger = Logger();

  Future<List<XFile>> pickMultiImageFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      return images;
    } catch (e, stackTrace) {
      logger.e("PickerService pickMultiImageFromGallery", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      return image;
    } catch (e, stackTrace) {
      logger.e("PickerService pickImageFromCamera", error: e, stackTrace: stackTrace);
      return null;
    }
  }


}