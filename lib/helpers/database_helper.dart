import 'package:sqflite/sqflite.dart';

/// A helper class that manages opening, creating, and providing
/// a singleton instance of the SQLite database for the Camalingo app.
class DatabaseHelper {
  /// Singleton instance to ensure only one connection to the database exists.
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Private named constructor to prevent external instantiation.
  DatabaseHelper._init();

  /// Cached reference to the open database. Initialized on first use.
  static Database? _database;

  /// Returns the database instance, opening and initializing it if needed.
  Future<Database> get database async {
    // If the database has already been opened, return it.
    if (_database != null) return _database!;
    // Otherwise, initialize the database.
    _database = await _initDB('camalingo.db');
    return _database!;
  }

  /// Opens or creates the database at the specified file path.
  ///
  /// [filePath] is the relative filename of the database.
  Future<Database> _initDB(String filePath) async {
    // Get the default database directory on the device.
    final dbPath = await getDatabasesPath();
    // Construct the full path to the database file.
    final path = '$dbPath/$filePath';

    // Open the database, set version, and define onCreate callback.
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Creates the database schema when opening a new database file.
  ///
  /// [db] is the database instance, [version] is the database version.
  Future _createDB(Database db, int version) async {
    // Example table for expenses. Adjust columns per your data model.
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        amount REAL,
        description TEXT,
        date TEXT
      )
    ''');
  }
}