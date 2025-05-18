import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            if (!mounted) {
              return; // Verificación de mounted antes de usar context
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create Account', style: AppTextStyles.heading1),
                const SizedBox(height: 40),
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
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                     
                      //local sign up begin
                      
                        final authService = AuthService();
                        await authService.signup(
                          email: _emailController.text,
                          password: _passwordController.text,
                          name: _nameController.text,
                        );  

                        if (!mounted) {
                          return; // Verificación de mounted antes de usar context
                       }

                      //local sign up end
                     
                      try {
                        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        await cred.user?.updateDisplayName(_nameController.text.trim());

                        // Send email verification
                        await cred.user?.sendEmailVerification();

                        // Inform user that a verification email has been sent
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Correo de verificación enviado a ${_emailController.text.trim()}. '
                              'Por favor revisa tu bandeja de entrada.'
                            ),
                          ),
                        );

                        // Optionally sign the user out to force verification before login
                        await FirebaseAuth.instance.signOut();

                        if (!mounted) return;

                        // Redirect back to login screen so user can sign in after verification
                        Navigator.pushReplacementNamed(context, '/login');
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message ?? 'Error al registrar usuario')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: Size(double.infinity, 50),
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
