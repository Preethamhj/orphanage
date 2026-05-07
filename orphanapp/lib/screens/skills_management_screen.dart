import 'package:flutter/material.dart';

import '../models/child_model.dart';
import '../models/child_skill_model.dart';
import '../services/role_manager.dart';
import '../services/student_grouping_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/messages.dart';

class SkillsManagementScreen extends StatefulWidget {
  const SkillsManagementScreen({super.key});

  @override
  State<SkillsManagementScreen> createState() => _SkillsManagementScreenState();
}

class _SkillsManagementScreenState extends State<SkillsManagementScreen> {
  final _service = StudentGroupingService();
  late Future<void> _loadFuture;
  List<ChildModel> _children = [];
  List<ChildSkillModel> _skills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final children = await _service.fetchChildren();
    final skills = <ChildSkillModel>[];
    for (final child in children) {
      skills.addAll(await _service.fetchSkills(child.childId!));
    }
    if (mounted) {
      setState(() {
        _children = children.where((child) => child.childId != null).toList();
        _skills = skills;
        _loading = false;
      });
    }
  }

  Future<void> _openSkillForm([ChildSkillModel? model]) async {
    final result = await showDialog<ChildSkillModel>(
      context: context,
      builder: (_) =>
          _SkillFormDialog(children: _children, initialSkill: model),
    );
    if (result == null) return;
    try {
      if (model == null) {
        await _service.addSkill(result);
        showMessage(context, 'Skill added');
      } else {
        await _service.updateSkill(result);
        showMessage(context, 'Skill updated');
      }
      await _loadData();
    } catch (e) {
      if (mounted)
        showMessage(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
    }
  }

  Future<void> _deleteSkill(String id) async {
    await _service.deleteSkill(id);
    if (!mounted) return;
    showMessage(context, 'Skill deleted');
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final canModify = RoleManager.instance.canManageSkills();
    return AppShell(
      title: 'Skills Management',
      child: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load skills: ${snapshot.error}'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total skills: ${_skills.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (canModify)
                    ElevatedButton.icon(
                      onPressed: () => _openSkillForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Skill'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _skills.isEmpty
                    ? const Center(child: Text('No skill entries yet.'))
                    : ListView.builder(
                        itemCount: _skills.length,
                        itemBuilder: (context, index) {
                          final skill = _skills[index];
                          final child = _children.firstWhere(
                            (c) => c.childId == skill.childId,
                            orElse: () => ChildModel(
                              name: 'Unknown',
                              childId: skill.childId,
                              age: 0,
                              gender: 'Unknown',
                              education: '-',
                              healthStatus: '-',
                              admissionDate: DateTime.now(),
                            ),
                          );
                          return Card(
                            child: ListTile(
                              title: Text(
                                '${skill.skillName} (${skill.skillLevel})',
                              ),
                              subtitle: Text(
                                '${child.name} • ${skill.description ?? 'No description'}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canModify)
                                    IconButton(
                                      onPressed: () => _openSkillForm(skill),
                                      icon: const Icon(Icons.edit),
                                    ),
                                  if (canModify)
                                    IconButton(
                                      onPressed: () => _deleteSkill(skill.id!),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SkillFormDialog extends StatefulWidget {
  final List<ChildModel> children;
  final ChildSkillModel? initialSkill;
  const _SkillFormDialog({required this.children, this.initialSkill});

  @override
  State<_SkillFormDialog> createState() => _SkillFormDialogState();
}

class _SkillFormDialogState extends State<_SkillFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedChildId;
  late final TextEditingController _skillNameCtrl;
  late final TextEditingController _skillLevelCtrl;
  late final TextEditingController _descriptionCtrl;

  @override
  void initState() {
    super.initState();
    _selectedChildId =
        widget.initialSkill?.childId ?? widget.children.first.childId;
    _skillNameCtrl = TextEditingController(
      text: widget.initialSkill?.skillName ?? '',
    );
    _skillLevelCtrl = TextEditingController(
      text: widget.initialSkill?.skillLevel ?? '',
    );
    _descriptionCtrl = TextEditingController(
      text: widget.initialSkill?.description ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialSkill == null ? 'Add Skill' : 'Edit Skill'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedChildId,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: widget.children
                      .map(
                        (child) => DropdownMenuItem(
                          value: child.childId,
                          child: Text(child.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedChildId = value),
                  validator: (value) =>
                      value == null ? 'Select a student' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _skillNameCtrl,
                  decoration: const InputDecoration(labelText: 'Skill Name'),
                  validator: _required,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _skillLevelCtrl,
                  decoration: const InputDecoration(labelText: 'Skill Level'),
                  validator: _required,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final skill = ChildSkillModel(
              id: widget.initialSkill?.id,
              childId: _selectedChildId!,
              skillName: _skillNameCtrl.text.trim(),
              skillLevel: _skillLevelCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
            );
            Navigator.pop(context, skill);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}
