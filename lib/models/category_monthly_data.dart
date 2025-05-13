class CategoryMonthlyData {
  final String categoryName;
  final String monthName; // Agrego el parámetro monthName
  final double totalAmount;

  CategoryMonthlyData({
    required this.categoryName,
    required this.monthName, // Incluyo el parámetro en el constructor
    required this.totalAmount,
  });

  factory CategoryMonthlyData.fromMap(Map<String, dynamic> map) {
    return CategoryMonthlyData(
      categoryName: map['categoryName'] as String,
      monthName:
          map['monthName']
              as String, // Aseguro que monthName sea parte del mapeo
      totalAmount: (map['totalAmount'] as num).toDouble(),
    );
  }
}
