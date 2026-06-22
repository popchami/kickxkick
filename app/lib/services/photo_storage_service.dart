import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/photo.dart';

class PhotoStorageService {
  Future<String> savePhoto({
    required File sourceFile,
    required int shoeId,
    required PhotoType photoType,
  }) async {
    final directory = await _shoePhotoDirectory(shoeId);
    final extension = path.extension(sourceFile.path);
    final fileName = '${photoType.databaseValue}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destinationPath = path.join(directory.path, fileName);

    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  Future<void> deletePhotoFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> getShoePhotoDirectory(int shoeId) async {
    return _shoePhotoDirectory(shoeId);
  }

  Future<Directory> _shoePhotoDirectory(int shoeId) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      path.join(
        appDirectory.path,
        'solemuseum',
        'photos',
        shoeId.toString(),
      ),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }
}
