class User {
  final String id;
  String name; // Cambio a variable mutable
  String email; // Cambio a variable mutable

  User({required this.id, required this.name, required this.email});

  String get displayName => name;

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email};
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(id: map['id'], name: map['name'], email: map['email']);
  }
}
