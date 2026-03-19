import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_logger.dart';
import 'core/app_config.dart';
import 'core/realtime_sync.dart';
import 'core/app_theme.dart';
import 'core/database_schema.dart';
import 'services/role_manager.dart';
import 'screens/adoptions/adoption_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/children/children_screen.dart';
import 'screens/common/access_denied_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/donations/donation_screen.dart';
import 'screens/donor/donor_dashboard_screen.dart';
import 'screens/profile/admin_profile_page.dart';
import 'screens/role_home/role_home_screen.dart';
import 'screens/staff/staff_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.instance.init();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.instance.logError(
      'flutter_error',
      details.exception,
      stackTrace: details.stack,
      details: {'library': details.library ?? 'unknown'},
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.logError('platform_error', error, stackTrace: stack);
    return false;
  };
  await AppLogger.instance.log('app_start');

  if (AppConfig.isConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
    await AppLogger.instance.log('supabase_initialized');
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      try {
        final row = await Supabase.instance.client
            .from('users')
            .select('role, approval_status')
            .eq('id', currentUser.id)
            .maybeSingle();
        final role = ((row?['role'] as String?) ?? 'staff').toLowerCase().trim();
        final approval = (row?['approval_status'] as String?) ?? 'pending';
        if (role != 'admin' && approval != 'approved') {
          await Supabase.instance.client.auth.signOut();
          RoleManager.instance.setRole(null);
          await AppLogger.instance.log(
            'session_blocked_pending_approval',
            details: {'user_id': currentUser.id, 'role': role, 'approval_status': approval},
          );
        } else {
          RoleManager.instance.setRole(role);
          await AppLogger.instance.log('session_role_loaded', details: {'user_id': currentUser.id, 'role': RoleManager.instance.role});
        }
      } catch (_) {
        await Supabase.instance.client.auth.signOut();
        RoleManager.instance.setRole(null);
        await AppLogger.instance.log('session_role_load_failed_signed_out');
      }
    }
    await RealtimeSync.instance.init();
  } else {
    await AppLogger.instance.log('app_config_missing');
  }
  runApp(const OrphanageApp());
}

class OrphanageApp extends StatelessWidget {
  const OrphanageApp({super.key});

  bool _isAuthenticated() {
    if (RoleManager.instance.localAdminAuthenticated) return true;
    if (!AppConfig.isConfigured) return false;
    return Supabase.instance.client.auth.currentSession != null;
  }

  Route<dynamic> _guardedRoute(
    Widget screen, {
    bool requiresAuth = true,
    List<String>? allowedRoles,
  }) {
    final authed = _isAuthenticated();
    if (requiresAuth && !authed) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
    final role = RoleManager.instance.role;
    if (requiresAuth && allowedRoles != null && !allowedRoles.contains(role)) {
      return MaterialPageRoute(builder: (_) => const AccessDeniedScreen());
    }
    if (!requiresAuth && authed) {
      final home = _homeByRole(role);
      return MaterialPageRoute(builder: (_) => home);
    }
    return MaterialPageRoute(builder: (_) => screen);
  }

  Widget _homeByRole(String role) {
    switch (role) {
      case 'admin':
        return const DashboardScreen();
      case 'staff':
        return RoleHomeScreen(
          title: 'Staff Home',
          description: 'Staff access: view children and staff.',
          actions: [
            ('Children', '/children'),
            ('Staff', '/staff'),
          ],
        );
      case 'donor':
        return const DonorDashboardScreen();
      case 'adopter':
        return RoleHomeScreen(
          title: 'Adopter Home',
          description: 'Adopter access: apply and track adoption status.',
          actions: [
            ('Children', '/children'),
            ('Adoptions', '/adoptions'),
          ],
        );
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialScreen = !AppConfig.isConfigured
        ? const _ConfigHelpScreen()
        : (_isAuthenticated()
            ? _homeByRole(RoleManager.instance.role)
            : const LoginScreen());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orphanage Management',
      theme: AppTheme.light,
      home: initialScreen,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return _guardedRoute(const LoginScreen(), requiresAuth: false);
          case '/dashboard':
            return _guardedRoute(const DashboardScreen(), allowedRoles: ['admin']);
          case '/children':
            return _guardedRoute(const ChildrenScreen(), allowedRoles: ['admin', 'staff', 'donor', 'adopter']);
          case '/staff':
            return _guardedRoute(const StaffScreen(), allowedRoles: ['admin', 'staff', 'donor', 'adopter']);
          case '/donations':
            return _guardedRoute(const DonationScreen(), allowedRoles: ['admin']);
          case '/adoptions':
            return _guardedRoute(const AdoptionScreen(), allowedRoles: ['admin', 'adopter']);
          case '/staff-home':
            return _guardedRoute(
              RoleHomeScreen(
                title: 'Staff Home',
                description: 'Staff access: children and staff summaries.',
                actions: [
                  ('Children', '/children'),
                  ('Staff', '/staff'),
                ],
              ),
              allowedRoles: ['staff'],
            );
          case '/donor-home':
            return _guardedRoute(const DonorDashboardScreen(), allowedRoles: ['donor']);
          case '/adopter-home':
            return _guardedRoute(
              RoleHomeScreen(
                title: 'Adopter Home',
                description: 'Track your application and view children information.',
                actions: [
                  ('Children', '/children'),
                  ('Adoptions', '/adoptions'),
                ],
              ),
              allowedRoles: ['adopter'],
            );
          case '/profile':
            return _guardedRoute(const AdminProfilePage());
          default:
            return _guardedRoute(const DashboardScreen());
        }
      },
    );
  }
}

class _ConfigHelpScreen extends StatelessWidget {
  const _ConfigHelpScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Configuration Required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Run with dart-defines:'),
            const SizedBox(height: 8),
            const SelectableText('flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY'),
            const SizedBox(height: 16),
            const Text('Supabase SQL Schema (copy into SQL editor):'),
            const SizedBox(height: 8),
            SelectableText(DatabaseSchema.sql),
          ],
        ),
      ),
    );
  }
}
