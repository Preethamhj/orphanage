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
  final _donationFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _occupationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  String _donationType = 'cash';
  String _paymentMethod = 'UPI';
  bool _profileComplete = false;
  bool _loading = true;
  bool _saving = false;
  bool _donating = false;

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
    _occupationController.dispose();
    _salaryController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
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
          .select('full_name, email, contact_number, occupation, monthly_salary')
          .eq('user_id', user.id)
          .maybeSingle();

      if (row != null) {
        _nameController.text = (row['full_name'] as String?) ?? '';
        _emailController.text = (row['email'] as String?) ?? _emailController.text;
        _contactController.text = (row['contact_number'] as String?) ?? '';
        _occupationController.text = (row['occupation'] as String?) ?? '';
        _salaryController.text = ((row['monthly_salary'] as num?)?.toString()) ?? '';
        _profileComplete =
            _nameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _occupationController.text.trim().isNotEmpty &&
            _salaryController.text.trim().isNotEmpty;
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
        'occupation': _occupationController.text.trim(),
        'monthly_salary': double.parse(_salaryController.text.trim()),
      }, onConflict: 'user_id');

      if (mounted) {
        setState(() => _profileComplete = true);
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

  Future<void> _submitDonation() async {
    if (!_donationFormKey.currentState!.validate()) return;
    setState(() => _donating = true);
    try {
      await Supabase.instance.client.from('donars').insert({
        'donor_name': _nameController.text.trim(),
        'donation_type': _donationType,
        'donation_amount': double.parse(_amountController.text.trim()),
        'payment_method': _paymentMethod,
        'donation_date': DateTime.now().toIso8601String().split('T').first,
        'remarks': _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      });

      _amountController.clear();
      _remarksController.clear();
      if (mounted) showMessage(context, 'Donation recorded. Thank you!');
    } catch (e) {
      if (mounted) {
        showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _donating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Donor Dashboard',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileCard(),
                  const SizedBox(height: 12),
                  if (_profileComplete) _donationCard(),
                ],
              ),
            ),
    );
  }

  Widget _profileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _profileComplete ? 'Your Information' : 'Complete Your Donor Profile',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _profileComplete
                    ? 'These details are saved in your donor profile.'
                    : 'Please save these details once before making donations.',
              ),
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
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Work / Occupation'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Monthly Salary'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Required';
                  final amount = double.tryParse(v);
                  if (amount == null || amount < 0) return 'Enter valid salary';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _saveDonor,
                child: Text(_saving ? 'Saving...' : 'Save Information'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _donationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _donationFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What would you like to donate?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _donationType,
                decoration: const InputDecoration(labelText: 'Donation Type'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'food', child: Text('Food')),
                  DropdownMenuItem(value: 'clothes', child: Text('Clothes')),
                  DropdownMenuItem(value: 'others', child: Text('Others')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _donationType = value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Estimated Amount / Value'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Required';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment / Delivery Method'),
                items: const [
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'In-kind Delivery', child: Text('In-kind Delivery')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _paymentMethod = value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _donating ? null : _submitDonation,
                child: Text(_donating ? 'Submitting...' : 'Donate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;
}
