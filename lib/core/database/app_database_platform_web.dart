import 'package:drift/drift.dart';
import 'package:drift/web.dart';

Future<QueryExecutor> openAppDatabase() async {
  return WebDatabase('catat_uang');
}
