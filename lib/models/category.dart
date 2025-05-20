class Category {
  final int? id;
  final String name;
  final String icon; // aquí guardamos el emoji

  Category({this.id, required this.name, required this.icon});

  /// Mapa de emojis por defecto según el nombre de categoría
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

  /// Convierte el modelo a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon, // guardamos el emoji
    };
  }

  /// Crea un Category a partir de Map;
  /// si no hay icon (o está vacío), usa el por defecto
  static Category fromMap(Map<String, dynamic> map) {
    final name = map['name'] as String;
    final dbIcon = map['icon'] as String? ?? '';

    return Category(
      id: map['id'] as int?,
      name: name,
      icon:
          dbIcon.isNotEmpty
              ? dbIcon
              : _defaultEmojis[name] ?? '❓', // fallback genérico
    );
  }
}
