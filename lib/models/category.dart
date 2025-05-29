/// Category model representing an expense category.
///
/// Contains an optional [id], a [name], and an [icon] emoji.
class Category {
  /// Unique identifier for the category (null if not persisted yet).
  final int? id;

  /// Display name of the category.
  final String name;

  /// Emoji icon representing the category.
  final String icon;

  /// Creates a new [Category] with the given [id], [name], and [icon].
  Category({this.id, required this.name, required this.icon});

  /// Default mapping of category names to emoji icons.
  static const Map<String, String> _defaultEmojis = {
    'Alimentación': '🍔',
    'Transporte': '🚌',
    'Salario': '💰',
    'Entretenimiento': '🎮',
    'Salud': '💊',
    'Hogar': '🏠',
    'Educación': '📚',
    'Otros': '📦',
  };

  /// Serializes this [Category] into a map for SQLite storage.
  Map<String, dynamic> toMap() {
    // Map each field to its corresponding database column.
    return {
      'id': id,
      'name': name,
      'icon': icon, // guardamos el emoji
    };
  }

  /// Deserializes a map from the database into a [Category].
  ///
  /// If the stored [icon] is empty, uses the default emoji for [name].
  static Category fromMap(Map<String, dynamic> map) {
    // Extract name and icon values from the map.
    final name = map['name'] as String;
    final dbIcon = map['icon'] as String? ?? '';

    return Category(
      id: map['id'] as int?,
      name: name,
      // Use stored icon if present; otherwise fall back to default emoji.
      icon:
          dbIcon.isNotEmpty
              ? dbIcon
              : _defaultEmojis[name] ?? '❓', // fallback genérico
    );
  }
}
