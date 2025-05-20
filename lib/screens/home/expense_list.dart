import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';
import '../../services/streak_service.dart';

class ExpenseList extends StatefulWidget {
  final GlobalKey<ExpenseListState> expenseListKey;
  final Map<int, Category> categoriesMap;
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
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );

  List<Expense> _expenses = [];
  double _totalExpenses = 0;
  double _totalIncome = 0;
  double _total = 0;
  bool _isLoading = false;
  int _streakCount = 0;

  final _authService = AuthService();
  final _expenseService = ExpenseService();

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _loadExpenses();
  }

  @override
  void didUpdateWidget(covariant ExpenseList old) {
    super.didUpdateWidget(old);
    if (old.selectedCategoryId != widget.selectedCategoryId) {
      _loadExpenses();
    }
  }

  Future<void> _loadStreak() async {
    final count = await StreakService.updateAndGetStreak();
    if (mounted) setState(() => _streakCount = count);
  }

  Future<void> _loadExpenses() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;

      final stats = await _expenseService.getStats(userId);
      final allExpenses = await _expenseService.getExpenses(userId);

      final filtered =
          widget.selectedCategoryId == null
              ? allExpenses
              : allExpenses
                  .where((e) => e.categoryId == widget.selectedCategoryId)
                  .toList();

      if (!mounted) return;
      setState(() {
        _expenses = filtered;
        _totalExpenses = (stats['totalExpenses'] as num).toDouble();
        _totalIncome = (stats['totalIncome'] as num).toDouble();
        _total = (stats['total'] as num).toDouble();
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading expenses: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los gastos')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Permite refrescar la lista desde fuera (por ejemplo, al agregar un gasto)
  Future<void> refreshExpenses() async {
    await _loadExpenses();
    await _loadStreak();
  }

  void _showEditExpenseDialog(Expense expense) {
    final amountCtrl = TextEditingController(
      text: expense.amount.abs().toStringAsFixed(2),
    );
    final descCtrl = TextEditingController(text: expense.description);
    bool isExpense = expense.amount < 0;

    showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // --- Resumen ---
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard('Gastos', _totalExpenses),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSummaryCard('Saldo', _total)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard('Ingresos', _totalIncome),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Lista de transacciones ---
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
                        return Dismissible(
                          key: ValueKey(expense.id),
                          direction: DismissDirection.endToStart,
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
                          child: ListTile(
                            onTap: () => _showEditExpenseDialog(expense),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryGreen,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
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

  Widget _buildSummaryCard(String title, double amount) {
    final color =
        title == 'Gastos'
            ? const Color(0xFFE53935)
            : title == 'Ingresos'
            ? const Color(0xFF43A047)
            : const Color(0xFFFBC02D);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(50), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: color.withAlpha(200),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
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
