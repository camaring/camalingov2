import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _showVerificationButton = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Reload user to get the latest verification status
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      // Check email verification
      if (user != null && !user.emailVerified) {
        // Sign out to prevent unverified access
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Debes verificar tu correo antes de iniciar sesión. '
              'Revisa tu bandeja y confirma tu dirección de email.'
            ),
          ),
        );
        setState(() {
          _loading = false;
          _showVerificationButton = true;
        });
        return;
      }

//intneto login local

// 2) Bloque específico para tu login local
    try {
      final authService = AuthService();
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      // Manejo puntual de error en login local
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en login local: $e')),
      );
    return; // cortamos la ejecución si falla aquí
  }

// fin intento login local
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error al iniciar sesión')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      // Re-authenticate the user to send verification
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Correo de verificación reenviado. Por favor revisa tu bandeja de entrada.')),
        );
      }
      // Sign out again to preserve login flow
      await FirebaseAuth.instance.signOut();
      // Oculta el botón tras el reenvío
      setState(() => _showVerificationButton = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reenviar correo de verificación: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text('Iniciar Sesión', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) =>
                      val != null && val.contains('@') && val.contains('.') ? null : 'Ingrese un email válido',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (val) => val != null && val.length >= 6 ? null : 'La contraseña debe tener al menos 6 caracteres',
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(onPressed: _login, child: const Text('Entrar')),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
                if (_showVerificationButton)
                  TextButton(
                    onPressed: _resendVerificationEmail,
                    child: const Text('Reenviar correo de verificación'),
                    
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
