import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'pesquisas.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pesquisas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        termo TEXT
      )
    ''');
  }

  Future<void> salvarPesquisa(String termo) async {
    final db = await database;
    await db.insert('pesquisas', {'termo': termo});
  }

  Future<List<String>> getPesquisas() async {
    final db = await database;
    final List<Map<String, dynamic>> pesquisas = await db.query('pesquisas');
    return pesquisas.map((p) => p['termo'] as String).toList();
  }

  Future<void> limparPesquisas() async {
    final db = await database;
    await db.delete('pesquisas');
  }
}
