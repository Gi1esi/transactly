import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


Future<void> deleteDatabaseFile() async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'my_database.db'); // replace with your DB name

  print('Deleting database at $path');
  await deleteDatabase(path);
  print('Database deleted successfully.');
}

void main() async {
  await deleteDatabaseFile();
}
