import 'package:flutter/material.dart';

import '../models/academic_model.dart';
import '../models/child_model.dart';
import '../models/child_skill_model.dart';
import '../services/grouping_service.dart';
import '../services/role_manager.dart';
import '../services/student_grouping_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/messages.dart';

class StudentProfileScreen extends StatefulWidget {
  final ChildModel child;
  const StudentProfileScreen({super.key, required this.child});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _academicService = GroupingService();
  final _groupingService = StudentGroupingService();
  late Future<List<AcademicRecordModel>> _recordsFuture;
  late Future<List<ChildSkillModel>> _skillsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadRecords();
    _skillsFuture = _loadSkills();
  }

  Future<List<AcademicRecordModel>> _loadRecords() {
    return _academicService.fetchAcademicRecords(widget.child.childId!);
  }

  Future<List<ChildSkillModel>> _loadSkills() async {
    if (widget.child.skills.isNotEmpty) {
      return widget.child.skills;
    }
    return _groupingService.fetchSkills(widget.child.childId!);
  }

  String get _academicStatus {
    final child = widget.child;
    return child.academicStatus ??
        _groupingService.calculateAcademicStatus(child.lastExamMarks);
  }

  Future<void> _addRecord() async {
    final child = widget.child;
    final result = await showDialog<AcademicRecordModel>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        final yearController = TextEditingController(
          text: DateTime.now().year.toString(),
        );
        final classController = TextEditingController(
          text: child.schoolClass?.toString() ?? '',
        );
        final marksController = TextEditingController();
        final attendanceController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Academic Record'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: classController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Class'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter class' : null,
                  ),
                  TextFormField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Year'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter year' : null,
                  ),
                  TextFormField(
                    controller: marksController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Marks'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter marks' : null,
                  ),
                  TextFormField(
                    controller: attendanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Attendance %',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter attendance'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final record = AcademicRecordModel(
                  childId: child.childId!,
                  schoolClass: int.parse(classController.text),
                  year: int.parse(yearController.text),
                  marks: double.parse(marksController.text),
                  attendance: double.parse(attendanceController.text),
                  performanceLevel: _academicService.calculatePerformanceLevel(
                    double.parse(marksController.text),
                  ),
                );
                Navigator.of(dialogContext).pop(record);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _academicService.insertAcademicRecord(result);
      if (!mounted) return;
      setState(() {
        _recordsFuture = _loadRecords();
      });
      showMessage(context, 'Academic record added successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final age = child.currentAge;
    return AppShell(
      title: 'Student Profile',
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.profileSummary,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _detailChip('Age', '$age'),
                      _detailChip('Gender', child.gender),
                      _detailChip('Status', _academicStatus),
                      _detailChip(
                        'Attendance',
                        child.attendancePercentage != null
                            ? '${child.attendancePercentage}%'
                            : '-',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: const Text('Personal Information'),
            children: [
              _infoRow('Gender', child.gender),
              _infoRow('Age', '$age'),
              _infoRow(
                'Date of Birth',
                child.dob != null
                    ? child.dob!.toLocal().toString().split(' ').first
                    : '-',
              ),
              _infoRow('Class', child.schoolClass?.toString() ?? '-'),
              _infoRow('Section', child.section ?? '-'),
              _infoRow('School Name', child.schoolName ?? '-'),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: const Text('Orphanage Joining Information'),
            children: [
              _infoRow(
                'Joining Date',
                child.joiningDate != null
                    ? child.joiningDate!.toLocal().toString().split(' ').first
                    : '-',
              ),
              _infoRow('Joining Reason', child.joiningReason ?? '-'),
              _infoRow('Brought By', child.broughtBy ?? '-'),
              _infoRow('Guardian Details', child.guardianDetails ?? '-'),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: const Text('Academic Details'),
            children: [
              _infoRow('Academic Status', _academicStatus),
              _infoRow(
                'Last Exam Marks',
                child.lastExamMarks?.toStringAsFixed(1) ?? '-',
              ),
              _infoRow(
                'Attendance %',
                child.attendancePercentage?.toStringAsFixed(1) ?? '-',
              ),
              _infoRow('Health Status', child.healthStatus),
              if (RoleManager.instance.canModifyAcademic())
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _addRecord,
                    icon: const Icon(Icons.add_chart),
                    label: const Text('Add Academic Record'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: const Text('Skills & Talents'),
            children: [
              FutureBuilder<List<ChildSkillModel>>(
                future: _skillsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final skills = snapshot.data ?? [];
                  if (skills.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('No skills recorded yet.'),
                    );
                  }
                  return Column(
                    children: skills
                        .map(
                          (skill) => ListTile(
                            title: Text(skill.skillName),
                            subtitle: Text(
                              '${skill.skillLevel} • ${skill.description ?? 'No description'}',
                            ),
                            trailing: Text(
                              skill.createdAt
                                  .toLocal()
                                  .toString()
                                  .split(' ')
                                  .first,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              if (RoleManager.instance.canManageSkills())
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      '/skills-management',
                      arguments: widget.child.childId,
                    ),
                    icon: const Icon(Icons.manage_search),
                    label: const Text('Manage Skills'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: const Text('Medical Notes'),
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  child.medicalNotes?.isNotEmpty == true
                      ? child.medicalNotes!
                      : 'No medical notes available.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: const Text('Background Information'),
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  child.childBackground?.isNotEmpty == true
                      ? child.childBackground!
                      : 'No background summary provided.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<AcademicRecordModel>>(
            future: _recordsFuture,
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Academic History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (snapshot.hasError)
                        Text('Failed to load records: ${snapshot.error}')
                      else if (records.isEmpty)
                        const Text('No academic records available yet.')
                      else
                        ...records.map(
                          (record) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Class ${record.schoolClass} • ${record.year}',
                            ),
                            subtitle: Text(
                              'Marks: ${record.marks} • Attendance: ${record.attendance}%',
                            ),
                            trailing: Text(record.performanceLevel),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }
}
