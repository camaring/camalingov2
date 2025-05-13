import '../models/expense.dart' as expense_model;
import '../models/category.dart' as category_model;
// Removed unused import for stats_screen.dart
import '../models/category_monthly_data.dart'; // Corrijo la referencia al archivo
import 'database_helper.dart';

class ExpenseService {
  final _db = DatabaseHelper.instance;
  Map<String, dynamic>? _cachedStats;
  List<expense_model.Expense>? _cachedExpenses;
  String? _cachedUserId;
  DateTime? _lastStatsUpdate;
  DateTime? _lastExpensesUpdate;

  Future<List<expense_model.Expense>> getExpenses(String userId) async {
    // Return cached expenses if available and less than 1 minute old
    if (_cachedExpenses != null &&
        _cachedUserId == userId &&
        _lastExpensesUpdate != null &&
        DateTime.now().difference(_lastExpensesUpdate!) <
            const Duration(minutes: 1)) {
      return _cachedExpenses!;
    }

    final db = await _db.database;
    final expenses = await db.query(
      'expenses',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 50,
    );

    final result =
        expenses.map((e) => expense_model.Expense.fromMap(e)).toList();

    // Cache the results
    _cachedExpenses = result;
    _cachedUserId = userId;
    _lastExpensesUpdate = DateTime.now();

    return result;
  }

  Future<void> addExpense(expense_model.Expense expense) async {
    final db = await _db.database;
    await db.insert('expenses', expense.toMap());
    // Invalidate caches
    _cachedStats = null;
    _cachedExpenses = null;
  }

  Future<void> deleteExpense(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    // Invalidate caches
    _cachedStats = null;
    _cachedExpenses = null;
  }

  Future<void> updateExpense(expense_model.Expense expense) async {
    final db = await _db.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    // Invalidate caches
    _cachedStats = null;
    _cachedExpenses = null;
  }

  Future<List<category_model.Category>> getCategories() async {
    final db = await _db.database;
    final categories = await db.query('categories');
    return categories.map((c) => category_model.Category.fromMap(c)).toList();
  }

  Future<void> addCategory(category_model.Category category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap());
  }

  Future<Map<String, dynamic>> getStats(String userId) async {
    // Return cached stats if available and less than 2 minutes old
    if (_cachedStats != null &&
        _cachedUserId == userId &&
        _lastStatsUpdate != null &&
        DateTime.now().difference(_lastStatsUpdate!) <
            const Duration(minutes: 2)) {
      return _cachedStats!;
    }

    final db = await _db.database;
    final List<Map<String, dynamic>> monthlyStats = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as totalIncome,
        SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as totalExpenses,
        SUM(amount) as total
      FROM expenses
      WHERE userId = ?
      AND date >= date('now', '-30 days')
      ''',
      [userId],
    );

    final Map<String, dynamic> stats =
        monthlyStats.isNotEmpty
            ? monthlyStats.first
            : {'totalIncome': 0.0, 'totalExpenses': 0.0, 'total': 0.0};

    // Cache the results
    _cachedStats = {
      'totalIncome': (stats['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpenses': (stats['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      'total': (stats['total'] as num?)?.toDouble() ?? 0.0,
    };
    _cachedUserId = userId;
    _lastStatsUpdate = DateTime.now();

    return _cachedStats!;
  }

  /// Devuelve totales de gastos e ingresos para el mes actual
  Future<Map<String, double>> getMonthlyExpensesIncomes(String userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as totalExpenses,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as totalIncomes
      FROM expenses
      WHERE userId = ?
        AND date >= date('now', 'start of month')
      ''',
      [userId],
    );
    final row = result.first;
    return {
      'expenses': (row['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      'incomes': (row['totalIncomes'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Devuelve datos para gráfico por categoría y mes (últimos [months] meses)
  Future<List<CategoryMonthlyData>> getCategoryMonthlyTotals(
    String userId, {
    int months = 6,
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.name as category,
        strftime('%m', date) as month,
        SUM(amount) as total
      FROM expenses e
      JOIN categories c ON e.categoryId = c.id
      WHERE e.userId = ?
        AND date >= date('now', '-\$months months')
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
      final monthName = monthNames[monthNum];
      return CategoryMonthlyData(
        categoryName: row['category'] as String,
        monthName: monthName,
        totalAmount: (row['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}
