import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_logger.dart';
import '../../services/auth_service.dart';
import '../../services/role_manager.dart';
import '../../widgets/messages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _adminEmail = 'admin@gmail.com';
  static const _adminPassword = 'Admin@123456';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _registerMode = false;
  bool _showPassword = false;
  String _selectedRole = 'staff';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_registerMode) {
        await AppLogger.instance.log('ui_register_submit', details: {'email': _emailCtrl.text.trim(), 'role': _selectedRole});
        await _authService.signUp(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          role: _selectedRole,
          contactNumber: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        );
        if (!mounted) return;
        showMessage(context, 'Registration successful. Please login.');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final username = _emailCtrl.text.trim();
        final password = _passwordCtrl.text.trim();
        await AppLogger.instance.log('ui_login_submit', details: {'email': username});

        if (username.toLowerCase() == _adminEmail && password == _adminPassword) {
          final adminRole = await _authService.signInAndGetRole(username, password);
          if (adminRole != 'admin') {
            throw Exception('Admin role is not configured for this account.');
          }
          RoleManager.instance.setLocalAdminSession(false);
          await AppLogger.instance.log('ui_static_admin_login_success_with_session', details: {'email': username});
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }

        final role = await _authService.signInAndGetRole(username, password);
        if (!mounted) return;
        final route = switch (role) {
          'admin' => '/dashboard',
          'staff' => '/staff-home',
          'donor' => '/donor-home',
          'adopter' => '/adopter-home',
          _ => '/staff-home',
        };
        Navigator.pushReplacementNamed(context, route);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      await AppLogger.instance.logError('ui_auth_error', e, details: {'screen': _registerMode ? 'register' : 'login', 'shown_message': message});
      showMessage(context, message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await SystemNavigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
            final width = constraints.maxWidth;
            final logoSize = (width * 0.364).clamp(117.0, 195.0);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width < 380 ? 14 : 20, vertical: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                            Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(Icons.home_work_rounded, size: logoSize, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'OrphanAge',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _registerMode ? 'Register' : 'Login',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 14),
                            if (_registerMode) ...[
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Full Name'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedRole,
                                decoration: const InputDecoration(labelText: 'Role'),
                                items: const [
                                  DropdownMenuItem(value: 'staff', child: Text('staff')),
                                  DropdownMenuItem(value: 'donor', child: Text('donor')),
                                  DropdownMenuItem(value: 'adopter', child: Text('adopter')),
                                ],
                                onChanged: (value) => setState(() => _selectedRole = value ?? 'staff'),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _contactCtrl,
                                decoration: const InputDecoration(labelText: 'Contact Number (optional)'),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(labelText: 'Email'),
                              validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: !_showPassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(_registerMode ? 'Register' : 'Login'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => setState(() {
                                        _registerMode = !_registerMode;
                                      }),
                              child: Text(_registerMode ? 'Already have an account? Login' : 'New user? Register'),
                            )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            },
          ),
        ),
      ),
    );
  }
}
