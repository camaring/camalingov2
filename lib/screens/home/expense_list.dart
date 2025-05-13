import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';
import '../../services/streak_service.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key, required this.expenseListKey});

  final GlobalKey<ExpenseListState> expenseListKey;

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

  Future<void> _loadStreak() async {
    final count = await StreakService.updateAndGetStreak();
    if (mounted) setState(() => _streakCount = count);
  }

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;
      final stats = await _expenseService.getStats(userId);
      final expenses = await _expenseService.getExpenses(userId);
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refreshExpenses() async {
    await _loadExpenses();
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
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Gasto'),
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                            ButtonSegment<bool>(
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
                        if (!mounted) {
                          return; // Verificación de mounted antes de usar context
                        }
                        Navigator.pop(context);
                        await refreshExpenses();
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
          // Resumen superior
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

          // Lista de transacciones
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _expenses.isEmpty
                    ? Center(
                      child: Text(
                        'No expenses yet.\nToca + para añadir una',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
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
                            await refreshExpenses();
                          },
                          child: ListTile(
                            onTap: () => _showEditExpenseDialog(expense),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryGreen,
                              child: const Text('💰'),
                            ),
                            title: Text(expense.description),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(expense.date),
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
    final Color color;
    if (title == 'Gastos') {
      color = const Color(0xFFE53935);
    } else if (title == 'Ingresos') {
      color = const Color(0xFF43A047);
    } else {
      color = const Color(0xFFFBC02D);
    }

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
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
