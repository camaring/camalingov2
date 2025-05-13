class Expense {
  final int? id;
  final String userId;
  final int categoryId;
  final double amount;
  final String description;
  final DateTime date;

  Expense({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['userId'].toString(),
      categoryId: map['categoryId'] as int,
      amount: map['amount'] as double,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Expense copyWith({double? amount, String? description}) {
    return Expense(
      id: id,
      userId: userId,
      categoryId: categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date,
    );
  }
}
