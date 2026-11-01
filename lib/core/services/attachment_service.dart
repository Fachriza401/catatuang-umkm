import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AttachmentService {
  AttachmentService({ImagePicker? picker, Uuid? uuid})
    : _picker = picker ?? ImagePicker(),
      _uuid = uuid ?? const Uuid();

  final ImagePicker _picker;
  final Uuid _uuid;

  Future<String?> pickImagePath() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    return picked?.path;
  }

  Future<String> persist(String sourcePath) async {
    final directory = await getApplicationSupportDirectory();
    final folder = Directory(p.join(directory.path, 'attachments'));
    await folder.create(recursive: true);

    final extension = p.extension(sourcePath);
    final fileName = '${_uuid.v4()}${extension.isEmpty ? '.jpg' : extension}';
    final destination = p.join(folder.path, fileName);
    final copied = await File(sourcePath).copy(destination);
    return copied.path;
  }
}
