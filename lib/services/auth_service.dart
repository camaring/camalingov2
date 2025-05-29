import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service handling user authentication and secure profile storage.
///
/// Uses FlutterSecureStorage to persist user credentials and profile info.
class AuthService {
  /// Secure storage instance for persisting user authentication data.
  final _storage = FlutterSecureStorage();

  /// Retrieves the current authenticated user's ID from secure storage.
  Future<String?> getCurrentUserId() async {
    return await _storage.read(key: 'user_id');
  }

  /// Retrieves the current authenticated user's profile if stored.
  Future<User?> getCurrentUser() async {
    final id = await _storage.read(key: 'user_id');
    final name = await _storage.read(key: 'user_name');
    final email = await _storage.read(key: 'user_email');

    if (id != null && name != null && email != null) {
      return User(id: id, name: name, email: email);
    }
    return null;
  }

  /// Updates the stored user profile information (name and email).
  Future<void> updateUserProfile({
    required String name,
    required String email,
  }) async {
    await _storage.write(key: 'user_name', value: name);
    await _storage.write(key: 'user_email', value: email);
    // Simulate delay for persistence operation.
    // Simulación de un retraso para guardar los datos
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Simulates user login by storing credentials in secure storage.
  Future<void> login(String email, String password) async {
    // TODO: Replace with real authentication API call.
    // TODO: Implement actual authentication
    await _storage.write(key: 'user_id', value: '1');
    await _storage.write(key: 'user_email', value: email);
    final name = email.split('@')[0];
    await _storage.write(key: 'user_name', value: name);
  }

  /// Simulates user signup by storing new credentials in secure storage.
  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    // TODO: Replace with real signup API integration.
    // TODO: Implement actual signup
    await _storage.write(key: 'user_id', value: '1');
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_name', value: name);
  }

  /// Placeholder for password reset functionality.
  Future<void> resetPassword(String email) async {
    // TODO: Implement password reset logic using backend service.
    // TODO: Implement password reset
  }

  /// Clears all stored user data, effectively logging out.
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  /// Updates the in-memory user object and simulates persistence.
  Future<void> updateProfile({
    required String displayName,
    required String email,
  }) async {
    final user = await getCurrentUser();
    if (user != null) {
      // Update user name and email in-memory.
      user.name = displayName; // Actualizo el nombre
      user.email = email; // Actualizo el correo
      // Simulación de guardar cambios en la base de datos o API
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Simulates sending a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    // Simulate network delay for email sending.
    // Implementación simulada para enviar un correo de restablecimiento de contraseña
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Simulates deletion of the user account.
  Future<void> deleteAccount() async {
    // Simulate network delay for account removal.
    // Implementación simulada para eliminar la cuenta
    await Future.delayed(const Duration(seconds: 1));
  }
}

/// Simple user model representing authenticated user details.
class User {
  /// Unique identifier for the user.
  final String id;
  /// User's display name.
  String name;
  /// User's email address.
  String email;

  User({required this.id, required this.name, required this.email});
}
