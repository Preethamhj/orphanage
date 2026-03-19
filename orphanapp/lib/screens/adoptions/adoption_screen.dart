import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/cache_store.dart';
import '../../models/adoption_model.dart';
import '../../services/adoption_service.dart';
import '../../services/role_manager.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/last_synced_label.dart';
import '../../widgets/messages.dart';
import '../../widgets/sync_status_icon.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key});

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  final _service = AdoptionService();
  final _search = TextEditingController();
  List<AdoptionModel> _items = [];
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
      _items = await _service.list(query: _search.text.trim());
      if (RoleManager.instance.isAdopter) {
        final email = Supabase.instance.client.auth.currentUser?.email?.toLowerCase() ?? '';
        _items = _items.where((e) => e.contactInformation.toLowerCase() == email).toList();
      }
      _lastSyncedAt = await CacheStore.readSavedAt('cache_adoptions_list');
      if (_search.text.trim().isNotEmpty && _items.isEmpty && mounted) {
        showMessage(context, 'No records found', error: true);
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = RoleManager.instance.isAdmin;
    final canApply = RoleManager.instance.canApplyAdoption();
    return AppShell(
      title: 'Adoption Management',
      child: Column(children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final addButton = ElevatedButton(
              onPressed: () async {
                final res = await showDialog<AdoptionModel>(context: context, builder: (_) => const _AdoptionForm());
                if (res != null) {
                  await _service.create(res);
                  if (!mounted) return;
                  await _load();
                  showMessage(context, 'Added');
                }
              },
              child: Text(canApply ? 'Apply Adoption' : 'Add Adoption'),
            );
            final searchField = TextField(controller: _search, decoration: const InputDecoration(labelText: 'Search by adopter or child_id'));
            if (compact) {
              return Column(
                children: [
                  searchField,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: _load, child: const Text('Search'))),
                      const SizedBox(width: 8),
                      if (isAdmin || canApply) Expanded(child: addButton),
                    ],
                  ),
                ],
              );
            }
            return Row(children: [
              Expanded(child: searchField),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _load, child: const Text('Search')),
              if (isAdmin || canApply) const SizedBox(width: 8),
              if (isAdmin || canApply) addButton,
            ]);
          },
        ),
        const SizedBox(height: 12),
        LastSyncedLabel(lastSyncedAt: _lastSyncedAt),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: _items
                      .map((a) => Card(
                            child: ListTile(
                              title: Text('${a.adopterName} -> Child #${a.childId}'),
                              subtitle: Text('Status: ${a.approvalStatus} | Application: ${a.applicationDate.toString().split(' ').first}'),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SyncStatusIcon(syncStatus: a.syncStatus),
                                  if (isAdmin)
                                    IconButton(
                                      onPressed: () async {
                                        final updated = await showDialog<AdoptionModel>(
                                          context: context,
                                          builder: (_) => _AdoptionForm(model: a),
                                        );
                                        if (updated == null) return;
                                        await _service.update(updated);
                                        if (!mounted) return;
                                        await _load();
                                        showMessage(context, 'Updated');
                                      },
                                      icon: const Icon(Icons.edit),
                                    ),
                                  if (isAdmin)
                                    IconButton(
                                      onPressed: () async {
                                        await _service.delete(a.adoptionId!);
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

class _AdoptionForm extends StatefulWidget {
  final AdoptionModel? model;
  const _AdoptionForm({this.model});

  @override
  State<_AdoptionForm> createState() => _AdoptionFormState();
}

class _AdoptionFormState extends State<_AdoptionForm> {
  final _form = GlobalKey<FormState>();
  final _childId = TextEditingController();
  final _adopter = TextEditingController();
  final _contact = TextEditingController();
  String _status = 'pending';
  DateTime _appDate = DateTime.now();
  DateTime? _completion;

  @override
  void initState() {
    super.initState();
    final isAdopter = RoleManager.instance.isAdopter;
    final m = widget.model;
    if (m != null) {
      _childId.text = m.childId.toString();
      _adopter.text = m.adopterName;
      _contact.text = m.contactInformation;
      _status = m.approvalStatus;
      _appDate = m.applicationDate;
      _completion = m.completionDate;
    } else if (isAdopter) {
      _status = 'pending';
      _contact.text = Supabase.instance.client.auth.currentUser?.email ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = RoleManager.instance.isAdmin;
    return AlertDialog(
      title: Text(widget.model == null ? 'Add Adoption' : 'Edit Adoption'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _childId,
                enabled: widget.model == null,
                decoration: const InputDecoration(labelText: 'Child ID'),
                keyboardType: TextInputType.number,
                validator: _r,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _adopter, decoration: const InputDecoration(labelText: 'Adopter Name'), validator: _r),
              const SizedBox(height: 8),
              TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact Information'), validator: _r),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('pending')),
                  DropdownMenuItem(value: 'approved', child: Text('approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('rejected')),
                ],
                onChanged: isAdmin ? (value) => setState(() => _status = value ?? 'pending') : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Application Date: ${_appDate.toString().split(' ').first}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final p = await showDatePicker(context: context, initialDate: _appDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (p != null) setState(() => _appDate = p);
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Completion Date: ${_completion == null ? '-' : _completion.toString().split(' ').first}'),
                trailing: IconButton(
                  icon: const Icon(Icons.event_available),
                  onPressed: () async {
                    final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (p != null) setState(() => _completion = p);
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              AdoptionModel(
                adoptionId: widget.model?.adoptionId,
                childId: int.parse(_childId.text.trim()),
                adopterName: _adopter.text.trim(),
                contactInformation: _contact.text.trim(),
                applicationDate: _appDate,
                approvalStatus: _status,
                completionDate: _completion,
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
