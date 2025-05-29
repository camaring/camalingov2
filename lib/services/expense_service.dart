import '../models/expense.dart' as expense_model;
import '../models/category.dart' as category_model;
import '../models/category_monthly_data.dart';
import 'database_helper.dart';

/// Service for CRUD operations on expenses and aggregated statistics.
///
/// Utilizes SQLite via [DatabaseHelper] and implements simple in-memory caching.
class ExpenseService {
  /// Singleton instance of the SQLite database helper.
  final _db = DatabaseHelper.instance;
  /// Cached results of the most recent statistics query.
  Map<String, dynamic>? _cachedStats;
  /// Cached list of the most recent expenses fetched.
  List<expense_model.Expense>? _cachedExpenses;
  /// User ID associated with the current cache entries.
  String? _cachedUserId;
  /// Timestamp of when statistics were last fetched and cached.
  DateTime? _lastStatsUpdate;
  /// Timestamp of when expenses were last fetched and cached.
  DateTime? _lastExpensesUpdate;

  /// Retrieves the latest expenses for [userId], ordered by date descending.
  ///
  /// Uses in-memory cache if data was fetched less than 1 minute ago.
  Future<List<expense_model.Expense>> getExpenses(String userId) async {
    // Use cached expenses if still fresh.
    if (_cachedExpenses != null &&
        _cachedUserId == userId &&
        _lastExpensesUpdate != null &&
        DateTime.now().difference(_lastExpensesUpdate!) <
            const Duration(minutes: 1)) {
      return _cachedExpenses!;
    }
    // Open database and query recent expenses.
    final db = await _db.database;
    final expensesMaps = await db.query(
      'expenses',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 50,
    );
    final expenses =
        expensesMaps.map((e) => expense_model.Expense.fromMap(e)).toList();
    _cachedExpenses = expenses;
    _cachedUserId = userId;
    _lastExpensesUpdate = DateTime.now();
    return expenses;
  }

  /// Inserts a new expense into the database and clears relevant caches.
  Future<void> addExpense(expense_model.Expense expense) async {
    final db = await _db.database;
    await db.insert('expenses', expense.toMap());
    _cachedStats = null;
    _cachedExpenses = null;
  }

  /// Deletes the expense with [id] and clears relevant caches.
  Future<void> deleteExpense(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    _cachedStats = null;
    _cachedExpenses = null;
  }

  /// Updates an existing expense and clears relevant caches.
  Future<void> updateExpense(expense_model.Expense expense) async {
    final db = await _db.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    _cachedStats = null;
    _cachedExpenses = null;
  }

  /// Returns all category definitions from the database.
  Future<List<category_model.Category>> getCategories() async {
    // Query categories table.
    final db = await _db.database;
    final catsMaps = await db.query('categories');
    return catsMaps.map((c) => category_model.Category.fromMap(c)).toList();
  }

  /// Inserts a new category into the database.
  Future<void> addCategory(category_model.Category category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap());
  }

  /// Retrieves total income, expenses, and per-category monthly stats for [userId].
  ///
  /// Aggregates data for the last 30 days and the last 6 months, including category icons.
  Future<Map<String, dynamic>> getStats(String userId) async {
    // Usar caché si está disponible
    if (_cachedStats != null &&
        _cachedUserId == userId &&
        _lastStatsUpdate != null &&
        DateTime.now().difference(_lastStatsUpdate!) <
            const Duration(minutes: 2)) {
      // Cache hit: return previously computed statistics.
      return _cachedStats!;
    }

    final db = await _db.database;

    // 1. Compute totals for the last 30 days.
    final totalsQuery = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END)     AS totalIncome,
        SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) AS totalExpenses,
        SUM(amount)                                        AS total
      FROM expenses
      WHERE userId = ? AND date >= date('now', '-30 days')
    ''',
      [userId],
    );
    final totalsRow = totalsQuery.first;
    final totalIncome = (totalsRow['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses =
        (totalsRow['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final total = (totalsRow['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Fetch per-category sums for each month over the last 6 months.
    final rawStats = await db.rawQuery(
      '''
      SELECT
        c.name       AS category,
        c.icon       AS icon,
        strftime('%m', e.date)          AS month,
        CASE WHEN SUM(e.amount) >= 0 THEN 'income' ELSE 'expense' END AS type,
        SUM(e.amount)                  AS total
      FROM expenses e
      JOIN categories c ON e.categoryId = c.id
      WHERE e.userId = ? AND e.date >= date('now', '-6 months')
      GROUP BY c.id, month
      ORDER BY month ASC
    ''',
      [userId],
    );

    // 3. Transform raw query results into grouped structures for UI.
    final tempValues = <String, Map<int, double>>{};
    final tempTypes = <String, String>{};
    final tempIcons = <String, String>{};

    for (var row in rawStats) {
      final catName = row['category'] as String;
      final rawIcon = (row['icon'] as String?) ?? '';
      final month = int.parse(row['month'] as String);
      final type = row['type'] as String;
      final amt = (row['total'] as num?)?.toDouble() ?? 0.0;

      tempValues.putIfAbsent(catName, () => {})[month] = amt.abs();
      tempTypes[catName] = type;
      tempIcons[catName] = rawIcon.isNotEmpty ? rawIcon : '❓';
    }

    final monthlyCategoryStats =
        tempValues.entries.map((e) {
          return {
            'category': e.key,
            'icon': tempIcons[e.key]!,
            'type': tempTypes[e.key]!,
            'monthly': e.value, // Map<int, double>
          };
        }).toList();

    // 4. Store computed results in cache and return.
    _cachedStats = {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'total': total,
      'monthlyCategoryStats': monthlyCategoryStats,
    };
    _cachedUserId = userId;
    _lastStatsUpdate = DateTime.now();
    return _cachedStats!;
  }

  /// Returns total incomes and expenses for [userId] in the current month.
  Future<Map<String, double>> getMonthlyExpensesIncomes(String userId) async {
    final db = await _db.database;
    // Aggregate expenses and incomes since the start of the month.
    final res = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) AS totalExpenses,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END)      AS totalIncomes
      FROM expenses
      WHERE userId = ? AND date >= date('now', 'start of month')
    ''',
      [userId],
    );
    final row = res.first;
    return {
      'expenses': (row['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      'incomes': (row['totalIncomes'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Returns total amounts per category for each of the last [months] months.
  Future<List<CategoryMonthlyData>> getCategoryMonthlyTotals(
    String userId, {
    int months = 6,
  }) async {
    final db = await _db.database;
    // Query sum of amounts grouped by category and month.
    final rows = await db.rawQuery(
      '''
      SELECT
        c.name AS category,
        strftime('%m', date) AS month,
        SUM(amount)         AS total
      FROM expenses e
      JOIN categories c ON e.categoryId = c.id
      WHERE e.userId = ?
        AND date >= date('now', '-$months months')
      GROUP BY category, month
      ORDER BY month ASC
    ''',
      [userId],
    );

    const monthNames = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return rows.map((row) {
      final monthNum = int.parse(row['month'] as String);
      return CategoryMonthlyData(
        categoryName: row['category'] as String,
        monthName: monthNames[monthNum],
        totalAmount: (row['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}
