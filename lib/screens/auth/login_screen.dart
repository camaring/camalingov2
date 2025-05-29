/// LoginScreen module: provides UI for user authentication.
/// Includes email/password fields, validation, Firebase login,
/// email verification flow, and local credential storage.

// ────────────────────────────────────────────────────────────────────────────
// Flutter framework imports
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
// ────────────────────────────────────────────────────────────────────────────
// External Firebase imports
// ────────────────────────────────────────────────────────────────────────────
import 'package:firebase_auth/firebase_auth.dart';
// ────────────────────────────────────────────────────────────────────────────
// Local app imports (constants and services)
// ────────────────────────────────────────────────────────────────────────────
import '../../constants.dart';
import '../../services/auth_service.dart';

/// Stateful widget for user login screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State for [LoginScreen], managing form validation, login flow, and UI state.
class _LoginScreenState extends State<LoginScreen> {
  /// Key for validating and saving the login form.
  final _formKey = GlobalKey<FormState>();
  /// Controller for the email input field.
  final TextEditingController _emailController = TextEditingController();
  /// Controller for the password input field.
  final TextEditingController _passwordController = TextEditingController();
  /// True when a login attempt is in progress.
  bool _loading = false;
  /// Controls visibility of the 'Resend verification' button.
  bool _showVerificationButton = false;

  @override
  /// Dispose controllers when state object is removed.
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Attempts user login via Firebase Auth and local AuthService.
  /// Handles email verification requirement and error display.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    // Show loading indicator while authentication is in progress.
    setState(() => _loading = true);

    try {
      // 1. Authenticate with Firebase using email and password.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseAuth.instance.currentUser?.reload();
      final firebaseUser = FirebaseAuth.instance.currentUser;

      // Check if the authenticated user’s email is verified.
      if (firebaseUser != null && !firebaseUser.emailVerified) {
        // Force sign-out to prevent unverified access.
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Debes verificar tu correo antes de iniciar sesión. '
              'Revisa tu bandeja y confirma tu dirección de email.',
            ),
          ),
        );
        setState(() {
          _loading = false;
          _showVerificationButton = true;
        });
        return;
      }

      // 2. Save credentials locally with AuthService.
      final authService = AuthService();
      await authService.login(
        firebaseUser?.email ?? '',
        _passwordController.text.trim(),
      );
      // Update local user profile information.
      await authService.updateUserProfile(
        name:
            firebaseUser?.displayName ??
            (firebaseUser?.email?.split('@')[0] ?? 'Usuario'),
        email: firebaseUser?.email ?? '',
      );

      // 3. Navigate to home screen on successful login.
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors.
      ScaffoldMessenger.of(context).showSnackBar(
        // Display error message to the user.
        SnackBar(content: Text(e.message ?? 'Error al iniciar sesión')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Resends email verification to the user if not verified.
  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      // Sign in temporarily to obtain user object for verification.
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        // Send a new verification email to the user.
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Correo de verificación reenviado. Revisa tu bandeja de entrada.',
            ),
          ),
        );
      }
      // Sign out immediately after sending verification email.
      await FirebaseAuth.instance.signOut();
      // Hide the resend button once email is sent.
      setState(() => _showVerificationButton = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reenviar correo de verificación: $e')),
      );
    }
  }

  @override
  /// Builds the login UI: form fields, buttons, and conditional widgets.
  Widget build(BuildContext context) {
    // Root scaffold for login screen.
    return Scaffold(
      backgroundColor: AppColors.white,
      // Center content vertically and horizontally.
      body: Center(
        // Enables scrolling when keyboard covers inputs.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          // Form for email and password inputs.
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // LOGO
                Image.asset('assets/Logo.png', height: 120),
                const SizedBox(height: 20),
                Text(
                  'Iniciar Sesión',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                // Email input field with simple validation.
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator:
                      (val) =>
                          val != null && val.contains('@') && val.contains('.')
                              ? null
                              : 'Ingrese un email válido',
                ),
                const SizedBox(height: 10),
                // Password input field (obscured) with length validation.
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator:
                      (val) =>
                          val != null && val.length >= 6
                              ? null
                              : 'La contraseña debe tener al menos 6 caracteres',
                ),
                const SizedBox(height: 20),
                // Show spinner when loading, otherwise display login button.
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Entrar'),
                    ),
                // Navigate to signup screen if user does not have an account.
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
                // Conditionally show button to resend email verification.
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
