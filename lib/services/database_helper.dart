import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper for SQLite operations using sqflite.
///
/// Manages the singleton database instance, schema creation, and migrations.

class DatabaseHelper {
  /// Singleton instance of [DatabaseHelper] to ensure a single DB connection.
  static final DatabaseHelper instance = DatabaseHelper._init();
  /// Holds the SQLite database instance once opened.
  static Database? _database;

  /// Private constructor for singleton initialization.
  DatabaseHelper._init();

  /// Provides the database instance, initializing if not already open.
  Future<Database> get database async {
    // Return existing database instance if already initialized.
    if (_database != null) return _database!;
    // Initialize the database file at the default path.
    _database = await _initDB('expenses.db');
    return _database!;
  }

  /// Initializes the database at [filePath], setting up creation and upgrade callbacks.
  Future<Database> _initDB(String filePath) async {
    // Determine the default directory for database files.
    final dbPath = await getDatabasesPath();
    // Construct the full filesystem path to the database.
    final path = join(dbPath, filePath);

    // Open (or create) the database with version and callbacks.
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Callback invoked on database creation.
  ///
  /// Defines tables for users, categories, expenses, inserts default data, and adds indexes.
  Future<void> _createDB(Database db, int version) async {
    // Create 'users' table for authentication data.
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Create 'categories' table with name and icon fields.
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // Create 'expenses' table with foreign keys to users and categories.
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

    // Insert default category entries for initial app usage.
    await db.insert('categories', {'name': 'Food', 'icon': '🍕'});
    await db.insert('categories', {'name': 'Transport', 'icon': '🚗'});
    await db.insert('categories', {'name': 'Shopping', 'icon': '🛍️'});
    await db.insert('categories', {'name': 'Bills', 'icon': '💰'});

    // Add indexes on 'expenses' columns to speed up queries.
    await db.execute('CREATE INDEX idx_expenses_userId ON expenses(userId)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute(
      'CREATE INDEX idx_expenses_categoryId ON expenses(categoryId)',
    );
  }

  /// Callback invoked on database version upgrade.
  ///
  /// Applies schema changes such as adding indexes for version >= 2.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Only run upgrade logic when upgrading from version older than 2.
    if (oldVersion < 2) {
      // Ensure index exists on 'expenses' for column userId.
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_userId ON expenses(userId)',
      );
      // Ensure index exists on 'expenses' for column date.
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)',
      );
      // Ensure index exists on 'expenses' for column categoryId.
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_categoryId ON expenses(categoryId)',
      );
    }
  }
}
