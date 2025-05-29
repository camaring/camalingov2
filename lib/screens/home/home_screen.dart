/// Home screen module.
///
/// Provides the main navigation scaffold, transaction list with filtering,
/// and dialogs for adding categories and transactions.
// Flutter framework imports.
import 'package:flutter/material.dart';
// Package for masked currency input controllers.
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
// Third-party package imports.
import '../../constants.dart';
// Local app imports: constants, models, services, screens.
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../services/tips_service.dart';
import '../stats/stats_screen.dart';
import '../settings/settings_screen.dart';
import 'expense_list.dart';

/// Main screen of the application, providing navigation between Home, Stats, and Settings.
///
/// Displays an expense list with filtering, access to statistics, and settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State for [HomeScreen], managing selected tab, category filters, and dynamic screens.
class _HomeScreenState extends State<HomeScreen> {
  /// Currently selected bottom navigation index (0=Home,1=Stats,2=Settings).
  int _selectedIndex = 0;
  /// Key to access and refresh the expense list state from dialogs.
  final _expenseListKey = GlobalKey<ExpenseListState>();

  /// Mapping of category IDs to [Category] objects for dropdown and filtering.
  Map<int, Category> _categoriesMap = {};
  /// List of widget screens corresponding to each bottom navigation tab.
  late List<Widget> _screens = [];
  /// Currently selected category ID for filtering expenses, or null for all.
  int? _selectedCategoryId;

  @override
  void initState() {
    // initState: Called once when this state is inserted into the widget tree.
    super.initState();
    // Kick off asynchronous load of categories and screen widgets.
    _loadCategoriesAndScreens();
  }

  /// Loads categories from the database and initializes the tab screens list.
  Future<void> _loadCategoriesAndScreens() async {
    // Fetch categories from database service for filter options.
    final cats = await ExpenseService().getCategories();
    // Build a lookup map from category IDs to Category objects.
    _categoriesMap = {for (var c in cats) c.id!: c};
    // Create widget list for Home, Stats, and Settings tabs using current data.
    _screens = [
      _buildHomeWithFilter(),
      const StatsScreen(),
      const SettingsScreen(),
    ];
    // Trigger UI refresh to display the newly built screens.
    setState(() {});
  }

  /// Builds the Home tab view, including category filter dropdown and expense list.
  Widget _buildHomeWithFilter() {
    // Column: Vertical layout for filter controls and expense list.
    return Column(
      children: [
        // Padding: Add horizontal and vertical spacing around filter row.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          // Row: Horizontal layout for spacer and filter dropdown.
          child: Row(
            children: [
              // Spacer: Pushes the filter container to the right.
              const Spacer(),
              // Container: Holds the dropdown with grey background and rounded corners.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                // BoxDecoration: Defines background color and border radius.
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Hide default dropdown underline for a cleaner look.
                child: DropdownButtonHideUnderline(
                  child: 
                      // DropdownButton: Shows selectable category values, with custom icon and style.
                      DropdownButton<int?>(
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
                    // Items: First option is 'all categories', followed by each category entry.
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
                    // onChanged: Update selected category and rebuild the Home tab widget.
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
        // Expanded widget showing the list of expenses filtered by category.
        // ExpenseList: Displays filtered expenses; refreshed via the key.
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

  /// Shows a dialog to add a new expense category, then reloads the screens.
  Future<void> _handleAddCategory(BuildContext ctx) async {
    // Display dialog to input new category name and icon.
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

  /// Displays a dialog for adding a new expense or income entry.
  void _showAddExpenseDialog() {
    // showDialog: Present modal to input new transaction data.
    showDialog<void>(
      context: context,
      builder: (ctx) {
        // Controller to format monetary input with locale separators.
        final amountCtrl = MoneyMaskedTextController(
          decimalSeparator: ',',
          thousandSeparator: '.',
          precision: 2,
        );
        // Controller for the transaction description text field.
        final descCtrl = TextEditingController();
        // Default selected category for new transaction.
        Category? selectedCat = _categoriesMap.values.first;
        // Initialize date picker value with current date.
        DateTime date = DateTime.now();
        // Toggle between expense (true) and income (false).
        bool isExpense = true;

        // StatefulBuilder: Allows local rebuilds inside the dialog on state changes.
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
                    // Toggle button between Expense and Income modes.
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
                    // Input field for transaction amount.
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
                    // Input field for transaction description.
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    // Dropdown to select transaction category, with option to add new.
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
                    // Field to pick the transaction date via date picker.
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
                  // Cancel button to dismiss the dialog without saving.
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  // Save button to validate inputs and persist the new transaction.
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

  /// Builds the main scaffold with AppBar, body stack, bottom navigation, and FAB.
  @override
  Widget build(BuildContext context) {
    // Root scaffold containing app structure.
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        // Top AppBar with logo, title, and tip action.
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
        // AppBar actions: Button to show a random saving tip dialog.
        actions: [
          // Button to show a random saving tip in a dialog.
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
      // Body stack with background image and current tab content.
      body: Stack(
        children: [
          // Semi-transparent background image for Home tab.
          Positioned(
            top: 350,
            left: 0,
            right: 0,
            height: 360,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/fondo_home.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Display a loader until the screen widgets are initialized.
          _screens.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _screens[_selectedIndex],
        ],
      ),
      // Bottom navigation bar for switching between tabs.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          // Home tab item.
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // Stats tab item.
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          // Settings tab item.
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // Floating action button for adding a new expense on Home tab.
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
