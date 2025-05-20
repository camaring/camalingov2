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

  Map<int, Category> _categoriesMap = {};
  late List<Widget> _screens = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndScreens();
  }

  Future<void> _loadCategoriesAndScreens() async {
    final cats = await ExpenseService().getCategories();
    _categoriesMap = {for (var c in cats) c.id!: c};
    _screens = [
      _buildHomeWithFilter(),
      const StatsScreen(),
      const SettingsScreen(),
    ];
    setState(() {});
  }

  Widget _buildHomeWithFilter() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedCategoryId,
                    hint: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, color: Colors.green),
                        SizedBox(width: 6),
                        Text('Filtro', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    dropdownColor: Colors.grey,
                    style: const TextStyle(color: Colors.black),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas las categorías'),
                      ),
                      ..._categoriesMap.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text('${e.value.icon} ${e.value.name}'),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedCategoryId = v;
                        _screens[0] = _buildHomeWithFilter();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ExpenseList(
            key: _expenseListKey,
            expenseListKey: _expenseListKey,
            categoriesMap: _categoriesMap,
            selectedCategoryId: _selectedCategoryId,
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddCategory(BuildContext ctx) async {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    await showDialog<void>(
      context: ctx,
      builder:
          (_) => AlertDialog(
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
                  await ExpenseService().addCategory(
                    Category(name: nameCtrl.text, icon: iconCtrl.text),
                  );
                  Navigator.pop(ctx);
                  await _loadCategoriesAndScreens();
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
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final amountCtrl = MoneyMaskedTextController(
          decimalSeparator: ',',
          thousandSeparator: '.',
          precision: 2,
        );
        final descCtrl = TextEditingController();
        Category? selectedCat = _categoriesMap.values.first;
        DateTime date = DateTime.now();
        bool isExpense = true;

        return StatefulBuilder(
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
                          prefixText: '\$ ',
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Category>(
                        value: selectedCat,
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
                            _categoriesMap.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.value,
                                    child: Text(
                                      '${e.value.icon} ${e.value.name}',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (c) => setState(() => selectedCat = c),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final pick = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (pick != null) setState(() => date = pick);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${date.day}/${date.month}/${date.year}'),
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
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final uid = await AuthService().getCurrentUserId();
                      if (uid == null) return;
                      if (amountCtrl.text.isEmpty || selectedCat == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa todos los campos'),
                          ),
                        );
                        return;
                      }
                      final raw = amountCtrl.numberValue;
                      await ExpenseService().addExpense(
                        Expense(
                          id: null,
                          userId: uid,
                          categoryId: selectedCat!.id!,
                          amount: isExpense ? -raw : raw,
                          description: descCtrl.text,
                          date: date,
                        ),
                      );
                      Navigator.pop(ctx);
                      _expenseListKey.currentState?.refreshExpenses();
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.savings_outlined, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              'Savemeleon',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
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
                      title: Row(
                        children: [
                          Image.asset('assets/tips.png', width: 60, height: 60),
                          const SizedBox(width: 10),
                          const Text(
                            '💡 Tip de Ahorro',
                            style: AppTextStyles.heading3,
                          ),
                        ],
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
      body:
          _screens.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
