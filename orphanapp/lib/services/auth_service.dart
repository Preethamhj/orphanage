import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../core/supabase_service.dart';
import 'role_manager.dart';

class AuthService {
  Future<String> signInAndGetRole(String email, String password) async {
    await AppLogger.instance.log('auth_login_request', details: {'email': email});
    try {
      final res = await SupabaseService.client.auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) {
        await AppLogger.instance.log('auth_login_failed_null_user', details: {'email': email});
        throw Exception('Login failed');
      }
      await AppLogger.instance.log('auth_login_success', details: {'user_id': user.id, 'email': user.email ?? email});

      final row = await SupabaseService.client
          .from('users')
          .select('role, email, approval_status')
          .eq('id', user.id)
          .maybeSingle();
      final userRow = row;
      if (userRow == null) {
        await AppLogger.instance.log(
          'users_row_missing_after_login',
          details: {'user_id': user.id, 'email': user.email ?? email},
        );
        throw Exception('User profile missing. Contact admin to complete role setup.');
      }

      final role = ((userRow['role'] as String?) ?? 'staff').toLowerCase().trim();
      final approvalStatus = (userRow['approval_status'] as String?) ?? 'pending';
      if (role != 'admin' && approvalStatus != 'approved') {
        await SupabaseService.client.from('login_logs').insert({
          'user_id': user.id,
          'email': userRow['email'] ?? user.email,
          'role': 'pending_$role',
          'login_time': DateTime.now().toIso8601String(),
        });
        await AppLogger.instance.log(
          'auth_login_blocked_pending_approval',
          details: {'user_id': user.id, 'role': role, 'approval_status': approvalStatus},
        );
        throw Exception('Account pending admin approval.');
      }
      RoleManager.instance.setRole(role);

      await SupabaseService.client.from('login_logs').insert({
        'user_id': user.id,
        'email': userRow['email'] ?? user.email,
        'role': role,
        'login_time': DateTime.now().toIso8601String(),
      });
      await AppLogger.instance.log('auth_login_log_inserted', details: {'user_id': user.id, 'role': role});

      return role;
    } on AuthException catch (e) {
      await AppLogger.instance.logError('auth_login_auth_exception', e, details: {'email': email, 'raw_message': e.message});
      final msg = e.message.toLowerCase();
      if (_isNetworkFailure(msg)) {
        throw Exception('Network error: unable to reach Supabase. Check internet/DNS and Supabase URL.');
      }
      if (msg.contains('email not confirmed')) {
        throw Exception('Email not confirmed');
      }
      if (msg.contains('rate limit')) {
        throw Exception('Too many attempts. Please try again later.');
      }
      throw Exception('Invalid email or password');
    } on PostgrestException catch (e, st) {
      await AppLogger.instance.logError('auth_login_postgrest_exception', e, stackTrace: st, details: {'email': email});
      throw Exception('Login failed due to permission issue');
    } catch (e, st) {
      await AppLogger.instance.logError('auth_login_unknown_exception', e, stackTrace: st, details: {'email': email});
      rethrow;
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? contactNumber,
  }) async {
    await AppLogger.instance.log('auth_register_request', details: {'email': email, 'role': role, 'full_name': fullName});
    try {
      await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'contact_number': contactNumber,
          'role': role,
        },
      );
      // Prevent auto-login after sign-up; user must login explicitly.
      await SupabaseService.client.auth.signOut();
      await AppLogger.instance.log('auth_register_success', details: {'email': email, 'role': role});
    } on AuthException catch (e) {
      await AppLogger.instance.logError('auth_register_auth_exception', e, details: {'email': email, 'raw_message': e.message, 'role': role});
      final msg = e.message.toLowerCase();
      if (_isNetworkFailure(msg)) {
        throw Exception('Network error: unable to reach Supabase. Check internet/DNS and Supabase URL.');
      }
      if (msg.contains('already') || msg.contains('registered')) {
        throw Exception('Email already registered');
      }
      if (msg.contains('invalid email')) {
        throw Exception('Invalid email format');
      }
      if (msg.contains('rate limit')) {
        throw Exception('Too many signup attempts. Please try later.');
      }
      if (msg.contains('database error saving new user') || msg.contains('unexpected_failure')) {
        throw Exception('Registration failed due to database trigger configuration. Ask admin to run latest schema SQL.');
      }
      if (msg.contains('password') && (msg.contains('weak') || msg.contains('short'))) {
        throw Exception('Weak password. Use at least 6 characters.');
      }
      throw Exception('Registration failed. Please try again.');
    } on PostgrestException catch (e, st) {
      await AppLogger.instance.logError('auth_register_postgrest_exception', e, stackTrace: st, details: {'email': email, 'role': role});
      throw Exception('Registration failed due to permission issue');
    } catch (e, st) {
      await AppLogger.instance.logError('auth_register_unknown_exception', e, stackTrace: st, details: {'email': email, 'role': role});
      rethrow;
    }
  }

  Future<void> signOut() async {
    await AppLogger.instance.log('auth_logout_request');
    await SupabaseService.client.auth.signOut();
    RoleManager.instance.setRole(null);
    RoleManager.instance.setLocalAdminSession(false);
    await AppLogger.instance.log('auth_logout_success');
  }

  bool get isLoggedIn => SupabaseService.client.auth.currentUser != null;

  bool _isNetworkFailure(String msg) {
    return msg.contains('failed host lookup') ||
        msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('timed out') ||
        msg.contains('network');
  }
}
