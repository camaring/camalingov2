import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/streak_service.dart';

/// Screen for user settings including profile info, streak status, and account actions.
///
/// Displays user details, allows editing profile, password reset, sign out, and account deletion.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State for [SettingsScreen], handling user and streak data loading and UI actions.
class _SettingsScreenState extends State<SettingsScreen> {
  /// Authentication service for user profile operations.
  final _auth = AuthService();

  /// Currently loaded user profile, or null if none.
  User? _user;

  /// Indicates whether user or streak data is being loaded.
  bool _loading = true;

  /// True if the daily activity streak is currently active.
  bool _streakOn = false;

  /// Number of consecutive days the user has recorded activity.
  int _streakCount = 0;

  @override
  void initState() {
    super.initState();
    // Automatically load streak status and user profile on widget creation.

    // Load the current activity streak status and count.
    _loadStreak();

    // Load the current authenticated user's profile.
    _loadUser();
  }

  /// Loads the user profile from secure storage and updates loading state.
  Future<void> _loadUser() async {
    // Show loading indicator.
    setState(() => _loading = true);
    final user = await _auth.getCurrentUser();
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  /// Retrieves streak active status and count from [StreakService].
  Future<void> _loadStreak() async {
    final on = await StreakService.isStreakOn();
    final count = await StreakService.getStreakCount();
    if (!mounted) return;
    setState(() {
      _streakOn = on;
      _streakCount = count;
    });
  }

  /// Opens a dialog to edit name and email, then reloads user profile.
  Future<void> _editProfile() async {
    if (_user == null) return;
    final nameCtrl = TextEditingController(text: _user!.name);
    final emailCtrl = TextEditingController(text: _user!.email);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter a name'
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter an email'
                                : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await _auth.updateUserProfile(
                      name: nameCtrl.text,
                      email: emailCtrl.text,
                    );
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (saved == true) {
      setState(
        () => _loading = true,
      ); // Mostrar splash mientras se recargan los datos
      await _loadUser();
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  /// Prompts the user to confirm password reset and sends reset email.
  Future<void> _resetPassword() async {
    if (_user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Reset Password'),
            content: const Text('Send reset email to your address?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _auth.sendPasswordResetEmail(_user!.email);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reset email sent')));
    }
  }

  /// Signs out the current user and navigates to the login screen.
  Future<void> _signOut() async {
    await _auth.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// Prompts confirmation and deletes the user account, then navigates to login.
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text('This action is irreversible. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _auth.deleteAccount();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  /// Builds the settings UI: header, action list, and version info.
  @override
  Widget build(BuildContext context) {
    // Show loading spinner while data is loading.
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If no user is loaded, display a message.
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        body: Center(
          child: Text('No user logged in', style: AppTextStyles.body),
        ),
      );
    }

    // 3. Usuario válido: construimos la UI normal.
    final user = _user!;

    // Root scaffold of the settings screen.
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      // AppBar showing settings icon and title.
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/settings.png',
              width: 60,
              height: 60,
            ),
            const SizedBox(width: 10),
            const Text('Settings', style: AppTextStyles.heading2),
          ],
        ),
        backgroundColor: AppColors.backgroundGrey,
        elevation: 0,
      ),
      // Scrollable area containing settings content.
      body: SingleChildScrollView(
        // Column layout stacking header and action items.
        child: Column(
          children: [
            // Profile header: avatar, name, email, and streak indicator.
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreen),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryGreen,
                    child: Icon(Icons.person, size: 40, color: AppColors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: AppTextStyles.heading2),
                  const SizedBox(height: 4),
                  Text(user.email, style: AppTextStyles.body),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        _streakOn ? 'assets/R_prendida.png' : 'assets/R_apagado.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_streakCount días',
                        style: AppTextStyles.body.copyWith(
                          color: _streakOn ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User account actions.
            // Divider between profile header and actions.
            const Divider(height: 1),
            // Option to edit user name and email.
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editProfile,
            ),
            const Divider(height: 1),
            // Option to send a password reset email.
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Reset Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _resetPassword,
            ),
            const Divider(height: 1),
            // Option to sign out of the application.
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sign Out'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _signOut,
            ),
            const Divider(height: 1),
            // Option to delete the user account permanently.
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: _deleteAccount,
            ),
            const Divider(height: 1),

            // App version display.
            // Display current application version.
            const SizedBox(height: 24),
            Text(
              'Version 1.0.0',
              style: AppTextStyles.body.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
