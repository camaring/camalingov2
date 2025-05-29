/// SignupScreen module: provides UI to create a new user account.
/// Includes form fields for name, email, password, password confirmation,
/// and handles local and Firebase sign-up with email verification.

// ────────────────────────────────────────────────────────────────────────────
// Flutter framework imports
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
// ────────────────────────────────────────────────────────────────────────────
// Local app imports (constants and services)
// ────────────────────────────────────────────────────────────────────────────
import '../../constants.dart';
import '../../services/auth_service.dart';
// ────────────────────────────────────────────────────────────────────────────
// External Firebase imports
// ────────────────────────────────────────────────────────────────────────────
import 'package:firebase_auth/firebase_auth.dart';

/// Stateful widget for user sign-up screen.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => SignupScreenState();
}

/// State class for [SignupScreen], managing form and sign-up logic.
class SignupScreenState extends State<SignupScreen> {
  /// Key to validate and save the sign-up form.
  final _formKey = GlobalKey<FormState>();
  /// Controller for the name text field.
  final _nameController = TextEditingController();
  /// Controller for the email text field.
  final _emailController = TextEditingController();
  /// Controller for the password text field.
  final _passwordController = TextEditingController();
  /// Controller for the confirm password text field.
  final _confirmPasswordController = TextEditingController();

  @override
  /// Builds the sign-up form UI inside a scaffold.
  Widget build(BuildContext context) {
    // Root scaffold for the sign-up screen.
    return Scaffold(
      backgroundColor: AppColors.white,
      // AppBar with back button to return to previous screen.
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        // Back button: navigates to the previous screen.
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            if (!mounted) return;
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          // Form widget containing input fields and validation.
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Image.asset('assets/Logo.png', height: 120),
                const SizedBox(height: 20),
                Text('Create Account', style: AppTextStyles.heading1),
                const SizedBox(height: 40),
                // Name input field with validation for non-empty.
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Email input field with basic non-empty validation.
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Password input field (obscured) with non-empty validation.
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Confirm password field, must match the password field.
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Sign Up button: validates form and triggers sign-up logic.
                ElevatedButton(
                  onPressed: () async {
                    // Validate all form fields before proceeding.
                    if (_formKey.currentState!.validate()) {
                      // Perform local sign-up using AuthService.
                      final authService = AuthService();
                      await authService.signup(
                        email: _emailController.text,
                        password: _passwordController.text,
                        name: _nameController.text,
                      );

                      if (!mounted) return;

                      // Create Firebase user with email and password.
                      try {
                        final cred = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                        // Set the Firebase user display name.
                        await cred.user?.updateDisplayName(
                          _nameController.text.trim(),
                        );
                        // Send email verification to the new user.
                        await cred.user?.sendEmailVerification();

                        // Notify user that verification email has been sent.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Correo de verificación enviado a ${_emailController.text.trim()}. '
                              'Por favor revisa tu bandeja de entrada.',
                            ),
                          ),
                        );

                        // Sign out from Firebase to force re-login after verification.
                        await FirebaseAuth.instance.signOut();

                        if (!mounted) return;

                        // Navigate to login screen after successful sign-up.
                        Navigator.pushReplacementNamed(context, '/login');
                      } on FirebaseAuthException catch (e) {
                        // Handle Firebase sign-up errors and notify user.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            // Show error message returned by Firebase or a generic one.
                            content: Text(
                              e.message ?? 'Error al registrar usuario',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(color: AppColors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
