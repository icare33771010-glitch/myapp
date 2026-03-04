import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 2; // വേർഷൻ 2 ആക്കി നിലനിർത്തുക
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // ഇവിടെ version: _databaseVersion എന്ന് മാറ്റണം
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // പഴയ ഡാറ്റാബേസ് ഉണ്ടെങ്കിൽ പുതിയ കോളം ആഡ് ചെയ്യാൻ ഇത് സഹായിക്കും
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // ആവശ്യമായ മാറ്റങ്ങൾ ഇവിടെ വരുത്താം അല്ലെങ്കിൽ സിംപിൾ ആയി ടേബിൾ ഡ്രോപ്പ് ചെയ്യാം
    }
  }

  Future _createDB(Database db, int version) async {
    // ട്രാൻസാക്ഷൻ ടേബിൾ
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        group_name TEXT,
        subgroup_name TEXT, 
        description TEXT,
        amount REAL,
        type TEXT,
        date TEXT 
      )
    ''');

    // സബ്ഗ്രൂപ്പ് ടേബിൾ
    await db.execute('''
      CREATE TABLE subgroups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_group TEXT,
        type TEXT 
      )
    ''');

    // ഗ്രൂപ്പ് ടേബിൾ
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
  }

  // --- ഇൻസേർട്ട് ഫംഗ്ഷനുകൾ ---

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<int> insertGroup(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('groups', row);
  }

  Future<int> insertSubgroup(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('subgroups', row);
  }

  // --- ക്വറി ഫംഗ്ഷനുകൾ ---

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> queryAllGroups() async {
    final db = await instance.database;
    return await db.query('groups');
  }

  Future<List<Map<String, dynamic>>> queryAllSubgroups() async {
    final db = await instance.database;
    return await db.query('subgroups');
  }

  // സബ്ഗ്രൂപ്പ് വെച്ച് ഫിൽട്ടർ ചെയ്യാൻ (പേര് കൃത്യമാക്കി)
  Future<List<Map<String, dynamic>>> queryBySubgroup(String name) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'subgroup_name = ?', // ഇവിടെ പേര് ശ്രദ്ധിക്കുക
      whereArgs: [name],
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlySummary(
    int month,
    int year,
  ) async {
    final db = await database; // നിങ്ങളുടെ database instance

    // മാസം 01, 02 എന്നിങ്ങനെ ഫോർമാറ്റ് ചെയ്യാൻ
    String monthStr = month.toString().padLeft(2, '0');
    String datePattern = "$year-$monthStr-%";

    return await db.rawQuery(
      '''
    SELECT category, SUM(amount) as total 
    FROM transactions 
    WHERE date LIKE ? 
    GROUP BY category
  ''',
      [datePattern],
    );
  }

  Future<List<Map<String, dynamic>>> queryRowsByGroup(String name) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'group_name = ?',
      whereArgs: [name],
      orderBy: 'date ASC',
    );
  }

  // --- ഡിലീറ്റ് ഫംഗ്ഷനുകൾ ---

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('transactions');
    await db.delete('subgroups');
    await db.delete('groups');
  }

  // 1. Oru prathyeka maasathe total income-um expense-um edukkan
  Future<List<Map<String, dynamic>>> getMonthlySummaryByGroup(
    int month,
    int year,
  ) async {
    final db = await database;
    String monthStr = month.toString().padLeft(2, '0');
    String datePattern = "$year-$monthStr-%";

    // ഇവിടെ category-ക്ക് പകരം group_name എന്ന് നൽകി
    return await db.rawQuery(
      '''
    SELECT group_name, SUM(amount) as total 
    FROM transactions 
    WHERE date LIKE ? 
    GROUP BY group_name
  ''',
      [datePattern],
    );
  }

  // 2. Aa maasathe mathram ella transactions-um edukkan
  Future<List<Map<String, dynamic>>> queryRowsByMonth(String monthYear) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: ['$monthYear%'],
      orderBy: 'date DESC',
    );
  }
}
