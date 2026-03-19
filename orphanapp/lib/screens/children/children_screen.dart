import 'package:flutter/material.dart';

import '../../core/cache_store.dart';
import '../../models/child_model.dart';
import '../../services/role_manager.dart';
import '../../services/children_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/last_synced_label.dart';
import '../../widgets/messages.dart';
import '../../widgets/sync_status_icon.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  final _service = ChildrenService();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<ChildModel> _items = [];
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _service.list(query: _searchCtrl.text.trim());
      _lastSyncedAt = await CacheStore.readSavedAt('cache_children_list');
      if (_searchCtrl.text.trim().isNotEmpty && _items.isEmpty && mounted) {
        showMessage(context, 'No records found', error: true);
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([ChildModel? model]) async {
    final result = await showDialog<ChildModel>(context: context, builder: (_) => _ChildFormDialog(model: model));
    if (result == null) return;
    try {
      if (model == null) {
        await _service.create(result);
      } else {
        await _service.update(result);
      }
      if (!mounted) return;
      showMessage(context, 'Saved');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _delete(int id) async {
    await _service.delete(id);
    if (!mounted) return;
    showMessage(context, 'Deleted');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final canModify = RoleManager.instance.canModifyChildren();
    return AppShell(
      title: 'Children Management',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final searchField = TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(labelText: 'Search by name or ID'),
                onSubmitted: (_) => _load(),
              );
              final actions = [
                ElevatedButton(onPressed: _load, child: const Text('Search')),
                if (canModify) ElevatedButton(onPressed: () => _openForm(), child: const Text('Add')),
              ];
              if (compact) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: actions[0]),
                        if (canModify) const SizedBox(width: 8),
                        if (canModify) Expanded(child: actions[1]),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  actions[0],
                  if (canModify) const SizedBox(width: 8),
                  if (canModify) actions[1],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LastSyncedLabel(lastSyncedAt: _lastSyncedAt),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final c = _items[i];
                      return Card(
                        child: ListTile(
                          title: Text('${c.name} (#${c.childId})'),
                          subtitle: Text('Age: ${c.age} | ${c.gender} | ${c.education}'),
                          trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            SyncStatusIcon(syncStatus: c.syncStatus),
                            if (canModify) IconButton(onPressed: () => _openForm(c), icon: const Icon(Icons.edit)),
                            if (canModify) IconButton(onPressed: () => _delete(c.childId!), icon: const Icon(Icons.delete, color: Colors.red)),
                          ]),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

class _ChildFormDialog extends StatefulWidget {
  final ChildModel? model;
  const _ChildFormDialog({this.model});

  @override
  State<_ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<_ChildFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _gender;
  late final TextEditingController _education;
  late final TextEditingController _health;
  late final TextEditingController _guardian;
  DateTime _admissionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    _name = TextEditingController(text: m?.name ?? '');
    _age = TextEditingController(text: m?.age.toString() ?? '');
    _gender = TextEditingController(text: m?.gender ?? '');
    _education = TextEditingController(text: m?.education ?? '');
    _health = TextEditingController(text: m?.healthStatus ?? '');
    _guardian = TextEditingController(text: m?.guardianDetails ?? '');
    _admissionDate = m?.admissionDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.model == null ? 'Add Child' : 'Edit Child'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
              const SizedBox(height: 8),
              TextFormField(controller: _age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number, validator: _required),
              const SizedBox(height: 8),
              TextFormField(controller: _gender, decoration: const InputDecoration(labelText: 'Gender'), validator: _required),
              const SizedBox(height: 8),
              TextFormField(controller: _education, decoration: const InputDecoration(labelText: 'Education'), validator: _required),
              const SizedBox(height: 8),
              TextFormField(controller: _health, decoration: const InputDecoration(labelText: 'Health Status'), validator: _required),
              const SizedBox(height: 8),
              TextFormField(controller: _guardian, decoration: const InputDecoration(labelText: 'Guardian Details (Optional)')),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Admission: ${_admissionDate.toLocal().toString().split(' ').first}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _admissionDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setState(() => _admissionDate = picked);
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
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              ChildModel(
                childId: widget.model?.childId,
                name: _name.text.trim(),
                age: int.parse(_age.text.trim()),
                gender: _gender.text.trim(),
                education: _education.text.trim(),
                healthStatus: _health.text.trim(),
                admissionDate: _admissionDate,
                guardianDetails: _guardian.text.trim().isEmpty ? null : _guardian.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        )
      ],
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;
}
