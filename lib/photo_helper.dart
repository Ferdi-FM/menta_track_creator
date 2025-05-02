import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoHelper {
  final ImagePicker _picker = ImagePicker();

  Future<Map<String, dynamic>> takePhotoAndSave() async {
    var status = await Permission.camera.request();
    if (status.isDenied) {
        return {};
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo == null) return {};

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String newPath = path.join(appDir.path, "images");

    await Directory(newPath).create(recursive: true);

    final String fileName = "photo_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final String fullPath = path.join(newPath, fileName);

    final File savedImage = await File(photo.path).copy(fullPath);

    return {
      "photo": photo,
      "imagePath": savedImage.path,
    };
  }
}