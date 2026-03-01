import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // database_helper.dart-ൽ ഇത് മാറ്റുക
  Future _createDB(Database db, int version) async {
    // database_helper.dart-ൽ മാറ്റം വരുത്തുക 👇
    await db.execute('''
  CREATE TABLE transactions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    subgroup TEXT,
    description TEXT,
    amount REAL,
    type TEXT,
    date TEXT  -- ഈ പുതിയ വരി ചേർക്കുക
  )
''');
    // സബ്ഗ്രൂപ്പ് ടേബിൾ
    await db.execute('''
    CREATE TABLE subgroups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT
    )
  ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await instance.database;
    return await db.query('transactions');
  }

  // സബ്ഗ്രൂപ്പ് ഇൻസേർട്ട് ചെയ്യാൻ
  Future<int> insertSubgroup(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('subgroups', row);
  }

  // എല്ലാ സബ്ഗ്രൂപ്പുകളും എടുക്കാൻ
  Future<List<Map<String, dynamic>>> queryAllSubgroups() async {
    final db = await instance.database;
    return await db.query('subgroups');
  }

  // database_helper.dart-നുള്ളിൽ ഇത് ചേർക്കുക
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions', // നിന്റെ ടേബിളിന്റെ പേര്
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
