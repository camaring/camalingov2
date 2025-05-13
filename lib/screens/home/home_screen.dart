import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import '../../constants.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../services/tips_service.dart';
import '../stats/stats_screen.dart';
import '../settings/settings_screen.dart';
import 'expense_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _expenseListKey = GlobalKey<ExpenseListState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ExpenseList(key: _expenseListKey, expenseListKey: _expenseListKey),
      const StatsScreen(),
      const SettingsScreen(),
    ];
  }

  Future<void> _handleAddCategory(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    final service = ExpenseService();

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Agregar Categoría'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icono (emoji)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  final cat = Category(
                    id: 0,
                    name: nameCtrl.text,
                    icon: iconCtrl.text,
                  );
                  await service.addCategory(cat);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: const Text(
                  'Agregar',
                  style: TextStyle(color: AppColors.black),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddExpenseDialog() {
    final authService = AuthService();
    final expenseService = ExpenseService();
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    Future<void> showExpenseDialog() async {
      final userId = await authService.getCurrentUserId();
      if (userId == null) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Por favor inicia sesión para agregar transacciones'),
          ),
        );
        return;
      }

      final categories = await expenseService.getCategories();
      if (!mounted) return;

      final amountController = MoneyMaskedTextController(
        decimalSeparator: ',',
        thousandSeparator: '.',
        precision: 2,
      );
      final descriptionController = TextEditingController();
      Category? selectedCategory =
          categories.isNotEmpty ? categories.first : null;
      DateTime selectedDate = DateTime.now();
      bool isExpense = true;

      await showDialog<void>(
        context: context,
        builder:
            (ctx) => StatefulBuilder(
              builder:
                  (ctx, setState) => AlertDialog(
                    title: const Text(
                      'Agregar Transacción',
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
                            controller: amountController,
                            decoration: const InputDecoration(
                              labelText: 'Monto',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (selectedCategory != null)
                            DropdownButtonFormField<Category>(
                              value: selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await _handleAddCategory(context);
                                    _showAddExpenseDialog();
                                  },
                                ),
                              ),
                              items:
                                  categories
                                      .map(
                                        (cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat.name),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (cat) =>
                                      setState(() => selectedCategory = cat),
                            ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha',
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => navigator.pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (amountController.text.isEmpty ||
                              selectedCategory == null) {
                            scaffold.showSnackBar(
                              const SnackBar(
                                content: Text('Completa todos los campos'),
                              ),
                            );
                            return;
                          }
                          try {
                            final rawAmount = amountController.numberValue;
                            final expense = Expense(
                              id: null, // Permitir que la base de datos genere automáticamente el ID
                              userId: userId,
                              categoryId: selectedCategory?.id ?? 0,
                              amount:
                                  isExpense
                                      ? -rawAmount
                                      : rawAmount, // Gasto negativo, ingreso positivo
                              description: descriptionController.text,
                              date: selectedDate,
                            );
                            await expenseService.addExpense(expense);
                            if (!mounted) return;
                            navigator.pop();
                            _expenseListKey.currentState?.refreshExpenses();
                          } catch (e) {
                            scaffold.showSnackBar(
                              SnackBar(content: Text('Error al guardar: $e')),
                            );
                          }
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

    showExpenseDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.savings_outlined, color: AppColors.primaryGreen),
            const SizedBox(width: 10),
            Text(
              'Savemeleon',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Color(0xFFFFDA07)),
            tooltip: 'Ver tip',
            onPressed: () {
              final tip = TipsService.getRandomTip();
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.amber, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        '💡 Tip de Ahorro',
                        style: AppTextStyles.heading3,
                      ),
                      content: Text(tip, style: AppTextStyles.body),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: _showAddExpenseDialog,
                backgroundColor: AppColors.primaryGreen,
                child: const Icon(Icons.add, color: AppColors.black),
              )
              : null,
    );
  }
}
