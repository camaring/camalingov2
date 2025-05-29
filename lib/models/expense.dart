/// Expense model representing a financial transaction entry.
/// 
/// Contains identifiers, category, amount, description, and date.
class Expense {
  /// Optional unique identifier for the expense (assigned by database).
  final int? id;
  /// Identifier of the user who created this expense.
  final String userId;
  /// Identifier of the category this expense belongs to.
  final int categoryId;
  /// Amount of the transaction: positive for income, negative for expense.
  final double amount;
  /// Textual description or note for the transaction.
  final String description;
  /// Date and time when the transaction occurred.
  final DateTime date;

  /// Creates a new [Expense] instance with the given properties.
  Expense({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.date,
  });

  /// Serializes this [Expense] into a map for database storage.
  Map<String, dynamic> toMap() {
    // Map each field to a key for database insertion.
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  /// Deserializes a map into an [Expense] instance.
  factory Expense.fromMap(Map<String, dynamic> map) {
    // Extract and convert map values to construct an Expense.
    return Expense(
      id: map['id'],
      userId: map['userId'].toString(),
      categoryId: map['categoryId'] as int,
      amount: map['amount'] as double,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  /// Returns a copy of this [Expense] with optional new values.
  Expense copyWith({double? amount, String? description}) {
    // Clone existing Expense, replacing only provided fields.
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
