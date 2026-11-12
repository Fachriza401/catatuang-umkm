import 'dart:io' as io if (dart.library.html) 'package:catat_uang/core/platform/io_stub.dart';

import 'package:flutter/foundation.dart';
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
    if (kIsWeb) {
      return null;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    return picked?.path;
  }

  Future<String> persist(String sourcePath) async {
    if (kIsWeb) {
      return sourcePath;
    }

    final directory = await getApplicationSupportDirectory();
    final folder = io.Directory(p.join(directory.path, 'attachments'));
    await folder.create(recursive: true);

    final extension = p.extension(sourcePath);
    final fileName = '${_uuid.v4()}${extension.isEmpty ? '.jpg' : extension}';
    final destination = p.join(folder.path, fileName);
    final copied = await io.File(sourcePath).copy(destination);
    return copied.path;
  }
}
