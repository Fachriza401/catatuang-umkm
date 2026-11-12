class File {
  File(this.path);

  final String path;

  Future<bool> exists() async => false;

  Future<File> copy(String destination) async => File(destination);
}

class Directory {
  Directory(this.path);

  final String path;

  Future<Directory> create({bool recursive = false}) async => this;
}

class FileSystemException implements Exception {
  FileSystemException(this.message, this.path);

  final String message;
  final String path;

  @override
  String toString() => 'FileSystemException: $message ($path)';
}
