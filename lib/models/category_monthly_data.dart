/// Model representing the total transaction amount for a specific category and month.
///
/// [categoryName]: the name of the expense category.
/// [monthName]: the name of the month (e.g., 'January', 'Febrero').
/// [totalAmount]: the aggregated sum of transactions for that category in this month.
class CategoryMonthlyData {
  /// Name of the expense category for this data entry.
  final String categoryName;

  /// Name of the month for which this data applies (e.g., 'January', 'Febrero').
  final String monthName;

  /// Total aggregated amount of transactions for this category in the month.
  final double totalAmount;

  /// Constructs a [CategoryMonthlyData] instance with the specified values.
  CategoryMonthlyData({
    required this.categoryName,
    required this.monthName,
    required this.totalAmount,
  });

  /// Creates a [CategoryMonthlyData] from a map of key/value pairs.
  ///
  /// Expects:
  /// - 'categoryName': String
  /// - 'monthName': String
  /// - 'totalAmount': num (converted to double)
  factory CategoryMonthlyData.fromMap(Map<String, dynamic> map) {
    // Map 'categoryName' key to the categoryName field.
    // Map 'monthName' key to the monthName field.
    // Map 'totalAmount' key and convert to double.
    return CategoryMonthlyData(
      categoryName: map['categoryName'] as String,
      monthName: map['monthName'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
    );
  }
}