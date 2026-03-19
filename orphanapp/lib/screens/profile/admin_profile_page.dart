import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/cache_store.dart';
import '../../core/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/messages.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  static const _photoPathKey = 'admin_profile_photo_path';
  final _authService = AuthService();
  final _picker = ImagePicker();

  Map<String, dynamic>? _profile;
  String? _photoPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final row = await SupabaseService.client
          .from('users')
          .select('role, full_name, email')
          .eq('id', user.id)
          .maybeSingle();

      _photoPath = await CacheStore.readString(_photoPathKey);
      _profile = row ??
          {
            'full_name': user.userMetadata?['full_name'] ?? 'Admin',
            'email': user.email ?? '-',
            'contact_number': '-',
          };
      _profile = {...?_profile, 'role': (row?['role'] ?? 'staff').toString(), 'contact_number': '-'};
    } catch (e) {
      if (mounted) showMessage(context, 'Failed to load profile: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final permission = await Permission.photos.request();
    final storage = await Permission.storage.request();
    if (!permission.isGranted && !storage.isGranted) {
      if (mounted) showMessage(context, 'Storage permission denied', error: true);
      return;
    }

    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    _photoPath = image.path;
    await CacheStore.writeString(_photoPathKey, image.path);
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return AppShell(
      title: 'Admin Profile',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            backgroundImage: hasPhoto ? FileImage(File(_photoPath!)) : null,
                            child: hasPhoto ? null : Icon(Icons.person, size: 56, color: Theme.of(context).colorScheme.primary),
                          ),
                          TextButton.icon(
                            onPressed: _pickProfilePhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Change Photo'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_profile?['full_name'] ?? 'Admin').toString(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text((_profile?['email'] ?? '-').toString()),
                          const SizedBox(height: 4),
                          Text('Contact: ${(_profile?['contact_number'] ?? '-')}'),
                          const SizedBox(height: 6),
                          Chip(label: Text('Role: ${(_profile?['role'] ?? 'staff')}')),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
