import 'package:flutter/material.dart';

import '../../core/cache_store.dart';
import '../../models/donation_model.dart';
import '../../services/role_manager.dart';
import '../../services/donation_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/last_synced_label.dart';
import '../../widgets/messages.dart';
import '../../widgets/sync_status_icon.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _service = DonationService();
  List<DonationModel> _items = [];
  DateTime? _from;
  DateTime? _to;
  bool _loading = true;
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _service.list(from: _from, to: _to);
      _lastSyncedAt = await CacheStore.readSavedAt('cache_donations_list');
      if (_items.isEmpty && mounted) {
        showMessage(context, 'No records found', error: true);
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final canModify = RoleManager.instance.canModifyDonations();
    final canViewAmount = RoleManager.instance.canViewDonationAmount();
    final total = _items.fold<double>(0, (sum, d) => sum + d.donationAmount);
    return AppShell(
      title: 'Donation Management',
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton(
            onPressed: () async {
              _from = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (mounted) setState(() {});
            },
            child: Text(_from == null ? 'From Date' : _from.toString().split(' ').first),
          ),
          OutlinedButton(
            onPressed: () async {
              _to = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (mounted) setState(() {});
            },
            child: Text(_to == null ? 'To Date' : _to.toString().split(' ').first),
          ),
          ElevatedButton(onPressed: _load, child: const Text('Filter')),
          if (canModify)
            ElevatedButton(
              onPressed: () async {
                final res = await showDialog<DonationModel>(context: context, builder: (_) => const _DonationForm());
                if (res != null) {
                  await _service.create(res);
                  if (!mounted) return;
                  await _load();
                  showMessage(context, 'Added');
                }
              },
              child: const Text('Add Donation'),
            ),
          if (canViewAmount) Chip(label: Text('Total: $total')),
        ]),
        const SizedBox(height: 12),
        LastSyncedLabel(lastSyncedAt: _lastSyncedAt),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: _items
                      .map((d) => Card(
                            child: ListTile(
                              title: Text('${d.donorName} - ${d.donationType}'),
                              subtitle: Text(
                                '${canViewAmount ? 'Amount: ${d.donationAmount} | ' : ''}${d.paymentMethod} | ${d.donationDate.toString().split(' ').first}',
                              ),
                              trailing: Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SyncStatusIcon(syncStatus: d.syncStatus),
                                  if (canModify)
                                    IconButton(
                                      onPressed: () async {
                                        await _service.delete(d.donationId!);
                                        if (!mounted) return;
                                        await _load();
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                    ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
        )
      ]),
    );
  }
}

class _DonationForm extends StatefulWidget {
  const _DonationForm();

  @override
  State<_DonationForm> createState() => _DonationFormState();
}

class _DonationFormState extends State<_DonationForm> {
  final _form = GlobalKey<FormState>();
  final _donor = TextEditingController();
  String _type = 'cash';
  final _amount = TextEditingController(text: '0');
  final _payment = TextEditingController();
  final _remarks = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Add Donation'),
      content: Form(
        key: _form,
        child: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _donor, decoration: const InputDecoration(labelText: 'Donor Name'), validator: _r),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Donation Type'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('cash')),
                DropdownMenuItem(value: 'clothes', child: Text('clothes')),
                DropdownMenuItem(value: 'food', child: Text('food')),
                DropdownMenuItem(value: 'others', child: Text('others')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'cash'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Donation Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final value = double.tryParse(v.trim());
                if (value == null || value < 0) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _payment, decoration: const InputDecoration(labelText: 'Payment Method'), validator: _r),
            const SizedBox(height: 8),
            TextFormField(controller: _remarks, decoration: const InputDecoration(labelText: 'Remarks')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${_date.toString().split(' ').first}'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              DonationModel(
                donorName: _donor.text.trim(),
                donationType: _type,
                donationAmount: double.parse(_amount.text.trim()),
                paymentMethod: _payment.text.trim(),
                donationDate: _date,
                remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
                syncStatus: 'pending',
              ),
            );
          },
          child: const Text('Save'),
        )
      ],
    );
  }

  String? _r(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}
