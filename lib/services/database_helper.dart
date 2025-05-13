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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        categoryId INTEGER NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Insert default categories
    await db.insert('categories', {'name': 'Food', 'icon': '🍕'});
    await db.insert('categories', {'name': 'Transport', 'icon': '🚗'});
    await db.insert('categories', {'name': 'Shopping', 'icon': '🛍️'});
    await db.insert('categories', {'name': 'Bills', 'icon': '💰'});

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_expenses_userId ON expenses(userId)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_categoryId ON expenses(categoryId)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add indexes in upgrade
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_userId ON expenses(userId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_categoryId ON expenses(categoryId)');
    }
  }
}
