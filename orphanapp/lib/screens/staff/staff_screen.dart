import 'package:flutter/material.dart';

import '../../core/cache_store.dart';
import '../../models/staff_model.dart';
import '../../services/role_manager.dart';
import '../../services/staff_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/last_synced_label.dart';
import '../../widgets/messages.dart';
import '../../widgets/sync_status_icon.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _service = StaffService();
  final _search = TextEditingController();
  List<StaffModel> _items = [];
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
      _lastSyncedAt = await CacheStore.readSavedAt('cache_staff_list');
      if (_search.text.trim().isNotEmpty && _items.isEmpty && mounted) {
        showMessage(context, 'No records found', error: true);
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save([StaffModel? m]) async {
    final res = await showDialog<StaffModel>(context: context, builder: (_) => _StaffForm(model: m));
    if (res == null) return;
    try {
      m == null ? await _service.create(res) : await _service.update(res);
      if (!mounted) return;
      showMessage(context, 'Saved');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canModify = RoleManager.instance.canModifyStaff();
    return AppShell(
      title: 'Staff Management',
      child: Column(children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final searchField = TextField(controller: _search, decoration: const InputDecoration(labelText: 'Search by name or ID'));
            if (compact) {
              return Column(
                children: [
                  searchField,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: _load, child: const Text('Search'))),
                      if (canModify) const SizedBox(width: 8),
                      if (canModify) Expanded(child: ElevatedButton(onPressed: () => _save(), child: const Text('Add'))),
                    ],
                  ),
                ],
              );
            }
            return Row(children: [
              Expanded(child: searchField),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _load, child: const Text('Search')),
              if (canModify) const SizedBox(width: 8),
              if (canModify) ElevatedButton(onPressed: () => _save(), child: const Text('Add')),
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
                      .map((s) => Card(
                            child: ListTile(
                              title: Text('${s.name} (#${s.staffId})'),
                              subtitle: Text('${s.role} | ${s.department} | ${s.email}'),
                              trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                                SyncStatusIcon(syncStatus: s.syncStatus),
                                if (canModify) IconButton(onPressed: () => _save(s), icon: const Icon(Icons.edit)),
                                if (canModify)
                                  IconButton(
                                      onPressed: () async {
                                        await _service.delete(s.staffId!);
                                        if (!mounted) return;
                                        await _load();
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red)),
                              ]),
                            ),
                          ))
                      .toList(),
                ),
        )
      ]),
    );
  }
}

class _StaffForm extends StatefulWidget {
  final StaffModel? model;
  const _StaffForm({this.model});

  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> c;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    c = [
      TextEditingController(text: m?.name ?? ''),
      TextEditingController(text: m?.role ?? ''),
      TextEditingController(text: m?.contactNumber ?? ''),
      TextEditingController(text: m?.email ?? ''),
      TextEditingController(text: m?.department ?? ''),
    ];
    _date = m?.joiningDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.model == null ? 'Add Staff' : 'Edit Staff'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: c[0], decoration: const InputDecoration(labelText: 'Name'), validator: _r),
              const SizedBox(height: 8),
              TextFormField(controller: c[1], decoration: const InputDecoration(labelText: 'Role'), validator: _r),
              const SizedBox(height: 8),
              TextFormField(controller: c[2], decoration: const InputDecoration(labelText: 'Contact Number'), validator: _r),
              const SizedBox(height: 8),
              TextFormField(controller: c[3], decoration: const InputDecoration(labelText: 'Email'), validator: _r),
              const SizedBox(height: 8),
              TextFormField(controller: c[4], decoration: const InputDecoration(labelText: 'Department'), validator: _r),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Joining Date: ${_date.toString().split(' ').first}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              )
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
              StaffModel(
                staffId: widget.model?.staffId,
                name: c[0].text.trim(),
                role: c[1].text.trim(),
                contactNumber: c[2].text.trim(),
                email: c[3].text.trim(),
                joiningDate: _date,
                department: c[4].text.trim(),
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
