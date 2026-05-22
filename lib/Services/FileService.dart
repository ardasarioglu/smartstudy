import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class FileService{
  static Future<String> saveImageToLocalStorage(XFile tempPhoto) async {
    final directory = await getApplicationDocumentsDirectory();
    String uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    String savedPath = "${directory.path}/$uniqueFileName";
    await File(tempPhoto.path).copy(savedPath);
    return savedPath;
  }

  static Future<void> deleteImageFromLocalStorage(String imagePath) async {
    final logger = Logger();
    try {
      final file = File(imagePath);
      if(await file.exists()){
        await file.delete();
      }
    } catch (e, stackTrace) {
      logger.e("deleteImageFromLocalStorage hatası: $e", error: e, stackTrace: stackTrace);
    }
  }

}