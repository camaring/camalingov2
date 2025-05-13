import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = FlutterSecureStorage();

  Future<String?> getCurrentUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<User?> getCurrentUser() async {
    final id = await _storage.read(key: 'user_id');
    final name = await _storage.read(key: 'user_name');
    final email = await _storage.read(key: 'user_email');

    if (id != null && name != null && email != null) {
      return User(id: id, name: name, email: email);
    }
    return null;
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
  }) async {
    await _storage.write(key: 'user_name', value: name);
    await _storage.write(key: 'user_email', value: email);
    // Simulación de un retraso para guardar los datos
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> login(String email, String password) async {
    // TODO: Implement actual authentication
    await _storage.write(key: 'user_id', value: '1');
    await _storage.write(key: 'user_email', value: email);
    final name = email.split('@')[0];
    await _storage.write(key: 'user_name', value: name);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    // TODO: Implement actual signup
    await _storage.write(key: 'user_id', value: '1');
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_name', value: name);
  }

  Future<void> resetPassword(String email) async {
    // TODO: Implement password reset
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
  }) async {
    final user = await getCurrentUser();
    if (user != null) {
      user.name = displayName; // Actualizo el nombre
      user.email = email; // Actualizo el correo
      // Simulación de guardar cambios en la base de datos o API
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // Implementación simulada para enviar un correo de restablecimiento de contraseña
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> deleteAccount() async {
    // Implementación simulada para eliminar la cuenta
    await Future.delayed(const Duration(seconds: 1));
  }
}

class User {
  final String id;
  String name;
  String email;

  User({required this.id, required this.name, required this.email});
}
