/// User model representing an authenticated user.
/// 
/// Contains the user's unique identifier, mutable name, and email.
class User {
  /// Unique identifier for the user.
  final String id;
  /// User's display name (mutable).
  String name;
  /// User's email address (mutable).
  String email;

  /// Creates a new [User] with the given [id], [name], and [email].
  User({required this.id, required this.name, required this.email});

  /// Returns the user's display name.
  String get displayName => name;

  /// Converts this [User] instance into a map for persistence or transmission.
  Map<String, dynamic> toMap() {
    // Map keys correspond to User fields for serialization.
    return {'id': id, 'name': name, 'email': email};
  }

  /// Creates a [User] instance from a map, typically retrieved from storage.
  static User fromMap(Map<String, dynamic> map) {
    // Extracts 'id', 'name', and 'email' from the provided map.
    return User(id: map['id'], name: map['name'], email: map['email']);
  }
}
