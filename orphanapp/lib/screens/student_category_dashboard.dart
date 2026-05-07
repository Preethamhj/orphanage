import 'package:flutter/material.dart';

import '../models/child_model.dart';
import '../services/student_grouping_service.dart';
import '../widgets/app_shell.dart';

class StudentCategoryDashboard extends StatefulWidget {
  const StudentCategoryDashboard({super.key});

  @override
  State<StudentCategoryDashboard> createState() =>
      _StudentCategoryDashboardState();
}

class _StudentCategoryDashboardState extends State<StudentCategoryDashboard> {
  final _service = StudentGroupingService();
  late Future<List<ChildModel>> _childrenFuture;

  String? _classFilter;
  String _ageGroupFilter = 'All';
  String _academicFilter = 'All';
  String _skillFilter = 'All';
  String _genderFilter = 'All';

  @override
  void initState() {
    super.initState();
    _childrenFuture = _service.fetchChildren();
  }

  List<ChildModel> _applyFilters(List<ChildModel> children) {
    return children.where((child) {
      final ageGroup = _ageGroup(child.currentAge);
      final academic =
          child.academicStatus ??
          _service.calculateAcademicStatus(child.lastExamMarks);
      final hasSkill =
          _skillFilter == 'All' ||
          child.skills.any((skill) => skill.skillName == _skillFilter);
      final classOk =
          _classFilter == null ||
          _classFilter == 'All' ||
          'Class ${child.schoolClass ?? 'Unknown'}' == _classFilter;
      final ageOk = _ageGroupFilter == 'All' || ageGroup == _ageGroupFilter;
      final academicOk =
          _academicFilter == 'All' || academic == _academicFilter;
      final genderOk = _genderFilter == 'All' || child.gender == _genderFilter;
      return classOk && ageOk && academicOk && hasSkill && genderOk;
    }).toList();
  }

  String _ageGroup(int age) {
    if (age <= 8) return '5-8';
    if (age <= 12) return '9-12';
    if (age <= 16) return '13-16';
    return '17+';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Student Categorization',
      child: FutureBuilder<List<ChildModel>>(
        future: _childrenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load students: ${snapshot.error}'),
            );
          }

          final children = snapshot.data ?? [];
          final filtered = _applyFilters(children);
          final academicTotals = _service.groupByAcademicStatus(children);
          final ageGroups = _service.groupByAge(children);
          final skillGroups = _service.groupBySkill(children);
          final classNames =
              children
                  .map(
                    (e) => e.schoolClass == null
                        ? 'Class Unknown'
                        : 'Class ${e.schoolClass}',
                  )
                  .toSet()
                  .toList()
                ..sort();
          final skillNames =
              children
                  .expand((e) => e.skills)
                  .map((s) => s.skillName)
                  .toSet()
                  .toList()
                ..sort();

          return Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statCard(
                        'Excellent Students',
                        '${academicTotals['Excellent Student'] ?? 0}',
                        Icons.star_border,
                      ),
                      _statCard(
                        'Good Students',
                        '${academicTotals['Good Student'] ?? 0}',
                        Icons.trending_up,
                      ),
                      _statCard(
                        'Average Students',
                        '${academicTotals['Average Student'] ?? 0}',
                        Icons.insights_outlined,
                      ),
                      _statCard(
                        'Weak Students',
                        '${academicTotals['Weak Student'] ?? 0}',
                        Icons.warning_amber_outlined,
                      ),
                      _statCard(
                        'Age Groups',
                        '${ageGroups.values.map((list) => list.length).reduce((a, b) => a + b)}',
                        Icons.timeline,
                      ),
                      _statCard(
                        'Skill Types',
                        '${skillGroups.keys.length}',
                        Icons.auto_awesome,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildDropdown<String>(
                            'Class',
                            ['All', ...classNames],
                            _classFilter ?? 'All',
                            (value) {
                              if (value != null) {
                                setState(
                                  () => _classFilter = value == 'All'
                                      ? null
                                      : value,
                                );
                              }
                            },
                          ),
                          _buildDropdown<String>(
                            'Age Group',
                            ['All', '5-8', '9-12', '13-16', '17+'],
                            _ageGroupFilter,
                            (value) {
                              if (value != null) {
                                setState(() => _ageGroupFilter = value);
                              }
                            },
                          ),
                          _buildDropdown<String>(
                            'Academic',
                            [
                              'All',
                              'Excellent Student',
                              'Good Student',
                              'Average Student',
                              'Weak Student',
                            ],
                            _academicFilter,
                            (value) {
                              if (value != null) {
                                setState(() => _academicFilter = value);
                              }
                            },
                          ),
                          _buildDropdown<String>(
                            'Skill',
                            ['All', ...skillNames],
                            _skillFilter,
                            (value) {
                              if (value != null) {
                                setState(() => _skillFilter = value);
                              }
                            },
                          ),
                          _buildDropdown<String>(
                            'Gender',
                            ['All', 'Male', 'Female', 'Other'],
                            _genderFilter,
                            (value) {
                              if (value != null) {
                                setState(() => _genderFilter = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Students by Age Group',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...ageGroups.entries.map(
                              (entry) => ListTile(
                                dense: true,
                                title: Text(entry.key),
                                trailing: Text('${entry.value.length}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Students by Skill',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...skillGroups.entries.map(
                              (entry) => ListTile(
                                dense: true,
                                title: Text(entry.key),
                                trailing: Text('${entry.value.length}'),
                              ),
                            ),
                            if (skillGroups.isEmpty)
                              const Text('No skill assignments available yet.'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filtered Students',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (filtered.isEmpty)
                              const Text('No students match these filters.')
                            else
                              ...filtered.map(
                                (child) => ListTile(
                                  title: Text(child.name),
                                  subtitle: Text(
                                    '${child.currentAge} yrs • ${child.schoolClass != null ? 'Class ${child.schoolClass}' : 'Unknown class'} • ${child.gender}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    List<T> options,
    T value,
    ValueChanged<T?> onChanged,
  ) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: options
            .map(
              (option) => DropdownMenuItem<T>(
                value: option,
                child: Text(option.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
