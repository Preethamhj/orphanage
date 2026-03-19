import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_shell.dart';
import '../../widgets/messages.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDonor();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadDonor() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User session not found');
      }

      _emailController.text = user.email ?? '';
      final row = await Supabase.instance.client
          .from('donors')
          .select('full_name, email, contact_number')
          .eq('user_id', user.id)
          .maybeSingle();

      if (row != null) {
        _nameController.text = (row['full_name'] as String?) ?? '';
        _emailController.text = (row['email'] as String?) ?? _emailController.text;
        _contactController.text = (row['contact_number'] as String?) ?? '';
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDonor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User session not found');

      await Supabase.instance.client.from('donors').upsert({
        'user_id': user.id,
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact_number': _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      }, onConflict: 'user_id');

      if (mounted) {
        showMessage(context, 'Donor details saved');
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Donor Dashboard',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Donation Form',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text('Fill and save your details. These values are stored in the donors table.'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: _required,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Enter valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _contactController,
                          decoration: const InputDecoration(labelText: 'Contact Number'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saving ? null : _saveDonor,
                          child: Text(_saving ? 'Saving...' : 'Save'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;
}
