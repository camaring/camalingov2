import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _authService = AuthService();
  final _expenseService = ExpenseService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;

  // Formateador de moneda con separador de miles y coma decimal
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null || !mounted) return;
      final stats = await _expenseService.getStats(userId);
      if (!mounted) return;
      setState(() {
        if (_startDate != null || _endDate != null) {
          final filtered = {
            'totalIncome': 0.0,
            'totalExpenses': 0.0,
            'total': 0.0,
            'monthlyCategoryStats': <dynamic>[],
          };

          for (var cat in stats['monthlyCategoryStats']) {
            final filteredMonthly = <int, num>{};
            (cat['monthly'] as Map).forEach((key, value) {
              final monthDate = DateTime(DateTime.now().year, key);
              if ((_startDate == null || !monthDate.isBefore(_startDate!)) &&
                  (_endDate == null || !monthDate.isAfter(_endDate!))) {
                filteredMonthly[key] = value;
                if (cat['type'] == 'income') {
                  filtered['totalIncome'] = (filtered['totalIncome'] as double) + value;
                  filtered['total'] = (filtered['total'] as double) + value;
                } else if (cat['type'] == 'expense') {
                  filtered['totalExpenses'] = (filtered['totalExpenses'] as double) + value;
                  filtered['total'] = (filtered['total'] as double) - value;
                }
              }
            });

            if (filteredMonthly.isNotEmpty) {
              (filtered['monthlyCategoryStats'] as List).add({
                'type': cat['type'],
                'monthly': filteredMonthly,
              });
            }
          }

          _stats = filtered;
        } else {
          _stats = stats;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estadísticas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_stats == null) {
      return const Scaffold(
        body: Center(child: Text('No hay datos disponibles')),
      );
    }

    final totalIncome = (_stats!['totalIncome'] as num).toDouble();
    final totalExpenses = (_stats!['totalExpenses'] as num).toDouble();
    final total = (_stats!['total'] as num).toDouble();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/stats.png',
                width: 80,
                height: 80,
              ),
            ),
          ),
          Column(
            children: [
              AppBar(
                title: const Text('Estadísticas', style: AppTextStyles.heading2),
                backgroundColor: AppColors.white,
                elevation: 0,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text(_startDate == null
                                  ? 'Desde'
                                  : DateFormat.yMMMd().format(_startDate!)),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _startDate = picked);
                                  _loadStats();
                                }
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpiar'),
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                                _loadStats();
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text(_endDate == null
                                  ? 'Hasta'
                                  : DateFormat.yMMMd().format(_endDate!)),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _endDate = picked);
                                  _loadStats();
                                }
                              },
                            ),
                          ],
                        ),
                        Text('Resumen del Mes', style: AppTextStyles.heading1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryCard('Ingresos', totalIncome, Colors.green),
                            _buildSummaryCard('Gastos', totalExpenses, Colors.red),
                            _buildSummaryCard(
                              'Balance',
                              total,
                              total >= 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Últimos 30 días', style: AppTextStyles.heading2),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Balance Total: ${_currencyFormatter.format(total)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: total >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Ingresos: ${_currencyFormatter.format(totalIncome)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Gastos: ${_currencyFormatter.format(totalExpenses)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // --- Nueva sección: Gráfico de barras ---
                        const SizedBox(height: 20),
                        Text('Ingresos vs Gastos por Mes', style: AppTextStyles.heading2),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 300,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildMonthlyIncomeExpenseChart(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 100,
        child: Column(
          children: [
            Text(
              title,
              style: AppTextStyles.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final data = (_stats!['monthlyCategoryStats'] as List<dynamic>);
    final meses = <int>{};
    for (var cat in data) {
      final monthlyMap = (cat['monthly'] as Map).cast<int, num>();
      for (var key in monthlyMap.keys) {
        final monthDate = DateTime(DateTime.now().year, key);
        if ((_startDate == null || !monthDate.isBefore(_startDate!)) &&
            (_endDate == null || !monthDate.isAfter(_endDate!))) {
          meses.add(key);
        }
      }
    }
    final sortedMeses = meses.toList()..sort();

    return sortedMeses.map((m) {
      double ingreso = 0, gasto = 0;
      for (var cat in data) {
        final tipo = cat['type'] as String;
        final mensualMap = (cat['monthly'] as Map).cast<int, num>();
        final valor = mensualMap[m]?.toDouble() ?? 0;
        if (tipo == 'income') {
          ingreso += valor;
        } else if (tipo == 'expense')
          gasto += valor;
      }
      return BarChartGroupData(
        x: m,
        barRods: [
          BarChartRodData(toY: ingreso, color: Colors.green, width: 8),
          BarChartRodData(toY: gasto, color: Colors.red, width: 8),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  Widget _buildMonthlyIncomeExpenseChart() {
    final barGroups = _buildBarGroups();
    return BarChart(
      BarChartData(
        barGroups: barGroups,
        groupsSpace: 20,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final monthName = DateFormat.MMM(
                  'es_CO',
                ).format(DateTime(0, value.toInt()));
                return Text(monthName, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
      ),
    );
  }
}
