/// ExpenseList module: Displays a detailed, filterable list of user expenses.
/// Includes daily streak indicator, summary cards, swipe-to-delete, and edit dialog.
library;
// ────────────────────────────────────────────────────────────────────────────
// Flutter framework imports
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
// ────────────────────────────────────────────────────────────────────────────
// External package imports
// ────────────────────────────────────────────────────────────────────────────
import 'package:intl/intl.dart';
// ────────────────────────────────────────────────────────────────────────────
// Local app imports (constants, models, services)
// ────────────────────────────────────────────────────────────────────────────
import '../../constants.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';
import '../../services/streak_service.dart';

/// Main widget for displaying and managing the expenses list.
class ExpenseList extends StatefulWidget {
  /// Key for external refresh control: parent can call `refreshExpenses()`.
  final GlobalKey<ExpenseListState> expenseListKey;
  /// Map from category ID to its metadata (name, icon).
  final Map<int, Category> categoriesMap;
  /// Currently applied category filter (null means no filter).
  final int? selectedCategoryId;

  const ExpenseList({
    super.key,
    required this.expenseListKey,
    required this.categoriesMap,
    this.selectedCategoryId,
  });

  @override
  State<ExpenseList> createState() => ExpenseListState();
}

class ExpenseListState extends State<ExpenseList> {
  /// Formatter for Colombian peso currency, e.g. $1.234,56.
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );

  /// List of expenses after applying filter.
  List<Expense> _expenses = [];
  /// Total amount of expenses (sum of negative values).
  double _totalExpenses = 0;
  /// Total amount of incomes (sum of positive values).
  double _totalIncome = 0;
  /// Net balance (income + expenses).
  double _total = 0;
  /// True while data is being fetched and UI should show a loader.
  bool _isLoading = false;

  /// Tracks daily activity streak:
  /// - _streakOn: whether user has activity today
  /// - _streakCount: number of consecutive active days
  bool _streakOn = false;
  int _streakCount = 0;

  /// Service instances:
  /// - _authService: to obtain current user ID
  /// - _expenseService: to fetch and update expense data
  final _authService = AuthService();
  final _expenseService = ExpenseService();

  @override
  /// Called once when widget is inserted. Starts loading streak and expenses.
  void initState() {
    super.initState();
    _loadStreak();
    _loadExpenses();
  }

  @override
  /// Called when widget config changes (e.g., selectedCategoryId).
  /// Reloads expenses if the category filter has changed.
  void didUpdateWidget(covariant ExpenseList old) {
    super.didUpdateWidget(old);
    if (old.selectedCategoryId != widget.selectedCategoryId) {
      _loadExpenses();
    }
  }

  /// Records today's activity and updates streakOn and streakCount.
  Future<void> _loadStreak() async {
    // Record activity for today to maintain streak.
    await StreakService.recordActivity();
    // Check if the streak is active today.
    final on = await StreakService.isStreakOn();
    // Get the total count of consecutive active days.
    final count = await StreakService.getStreakCount();
    if (!mounted) return;
    setState(() {
      _streakOn = on;
      _streakCount = count;
    });
  }

  /// Fetches expenses and stats, applies filtering, and updates totals.
  Future<void> _loadExpenses() async {
    // Avoid overlapping requests if a load is already underway.
    if (_isLoading) return;
    // Show loading spinner.
    setState(() => _isLoading = true);
    try {
      // Retrieve current user ID; abort if null.
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;

      // Load overall income and expense statistics.
      final stats = await _expenseService.getStats(userId);
      // Load detailed list of all expenses.
      final allExpenses = await _expenseService.getExpenses(userId);

      // Apply category filter if selectedCategoryId is set.
      final filtered =
          widget.selectedCategoryId == null
              ? allExpenses
              : allExpenses
                  .where((e) => e.categoryId == widget.selectedCategoryId)
                  .toList();

      if (!mounted) return;
      // Update UI state with fetched data.
      setState(() {
        _expenses = filtered;
        _totalExpenses = (stats['totalExpenses'] as num).toDouble();
        _totalIncome = (stats['totalIncome'] as num).toDouble();
        _total = (stats['total'] as num).toDouble();
      });
    } catch (e) {
      // On error, log and notify user.
      if (mounted) {
        debugPrint('Error loading expenses: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los gastos')),
        );
      }
    } finally {
      // Hide loading spinner.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Permite refrescar la lista desde fuera (por ejemplo, al agregar un gasto)
  /// Public method to refresh expenses list and streak, callable by parent.
  Future<void> refreshExpenses() async {
    await _loadExpenses();
    await _loadStreak();
  }

  /// Opens a modal dialog to edit the selected expense.
  void _showEditExpenseDialog(Expense expense) {
    // Initialize text controllers with the current expense values.
    final amountCtrl = TextEditingController(
      text: expense.amount.abs().toStringAsFixed(2),
    );
    final descCtrl = TextEditingController(text: expense.description);
    bool isExpense = expense.amount < 0;

    // Show dialog with fields to update amount and description.
    showDialog<void>(
      context: context,
      builder:
          (ctx) =>
              // Use StatefulBuilder for localized state updates within dialog.
              StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: const Text(
                    'Editar transacción',
                    style: AppTextStyles.heading2,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('Gasto'),
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Ingreso'),
                              icon: Icon(Icons.add_circle_outline),
                            ),
                          ],
                          selected: {isExpense},
                          onSelectionChanged:
                              (sel) => setState(() => isExpense = sel.first),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: amountCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      // On save: validate input, update the expense, and refresh UI.
                      onPressed: () async {
                        final raw = double.tryParse(
                          amountCtrl.text.replaceAll(',', '.'),
                        );
                        if (raw == null) return;
                        final updated = expense.copyWith(
                          amount: isExpense ? -raw : raw,
                          description: descCtrl.text,
                        );
                        await _expenseService.updateExpense(updated);
                        if (!mounted) return;
                        Navigator.pop(context);
                        await _loadExpenses();
                        await _loadStreak();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transacción actualizada'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(color: AppColors.black),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  /// Builds the widget tree: header (streak + summaries) and list of expenses.
  Widget build(BuildContext context) {
    // ────────────────────────────────────────────────────────────────────────────
    // Main layout: safe area wrapping header and content sections
    // ────────────────────────────────────────────────────────────────────────────
    return SafeArea(
      child: Column(
        children: [
          // Header section: daily streak indicator with icon and day count
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // streak header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(10),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primaryGreen.withAlpha(20),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Racha diaria',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            _streakOn ? 'assets/R_prendida.png' : 'assets/R_apagado.png',
                            width: 45,
                            height: 45,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$_streakCount días',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Summary cards: display total expenses, net balance, total incomes
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSummaryCard('Gastos', _totalExpenses)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSummaryCard('Saldo', _total)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSummaryCard('Ingresos', _totalIncome)),
                    ],
                  ),
                ),
              ],
            ),
          ),



          // Content section: show loading spinner, empty state, or the expenses list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _expenses.isEmpty
                    ? Center(
                      child: Text(
                        'No hay transacciones aún. Toca + para añadir una',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        final cat = widget.categoriesMap[expense.categoryId];
                        final emoji = cat?.icon ?? '❓';
                        final catName = cat?.name ?? '';
                        // ────────────────────────────────────────────────────────────────────────────
                        // Dismissible entry: swipe left to delete this expense with confirmation UI
                        // ────────────────────────────────────────────────────────────────────────────
                        return Dismissible(
                          key: ValueKey(expense.id),
                          direction: DismissDirection.endToStart,
                          // Background shown while swiping (red delete area with icon)
                          background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) async {
                            if (expense.id != null) {
                              await _expenseService.deleteExpense(expense.id!);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transacción eliminada'),
                              ),
                            );
                            await _loadExpenses();
                            await _loadStreak();
                          },
                          // Tap the list tile to edit the expense.
                          child: ListTile(
                            onTap: () => _showEditExpenseDialog(expense),
                            leading: SizedBox(
                              width: 48,
                              height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    expense.amount < 0
                                        ? 'assets/gasto.png'
                                        : 'assets/ingreso.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(expense.description),
                            subtitle: Text(
                              '$catName · ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                              style: AppTextStyles.body,
                            ),
                            trailing: Text(
                              _currencyFormatter.format(expense.amount),
                              style: TextStyle(
                                color:
                                    expense.amount < 0
                                        ? Colors.red
                                        : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  /// Renders a summary card displaying a financial metric (title + value).
  Widget _buildSummaryCard(String title, double amount) {
    final color =
        title == 'Gastos'
            ? const Color(0xFFE53935)
            : title == 'Ingresos'
            ? const Color(0xFF43A047)
            : const Color(0xFFFBC02D);

    // Card container for metric, with colored border and light background tint
    return Card(
      elevation: 0,
      // Rounded border with color matching the metric theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(50), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        // Inner container decoration: background fill and matching border radius
        decoration: BoxDecoration(
          color: color.withAlpha(5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Metric title label
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: color.withAlpha(200),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Metric value formatted and scaled to fit available space
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _currencyFormatter.format(amount.abs()),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color:
                      title == 'Saldo'
                          ? color
                          : (amount < 0
                              ? const Color(0xFFE53935)
                              : const Color(0xFF43A047)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
