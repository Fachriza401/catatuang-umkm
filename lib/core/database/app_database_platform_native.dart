import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<QueryExecutor> openAppDatabase() async {
  final directory = await getApplicationSupportDirectory();
  final file = io.File(p.join(directory.path, 'catat_uang.sqlite'));
  return NativeDatabase.createInBackground(file);
}
