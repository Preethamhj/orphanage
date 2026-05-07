import 'package:flutter/material.dart';

import '../models/academic_model.dart';
import '../models/child_model.dart';
import '../services/grouping_service.dart';
import '../widgets/app_shell.dart';
import 'student_profile_screen.dart';

class GroupingScreen extends StatefulWidget {
  const GroupingScreen({super.key});

  @override
  State<GroupingScreen> createState() => _GroupingScreenState();
}

class _GroupingScreenState extends State<GroupingScreen> {
  final _service = GroupingService();
  late Future<_GroupingData> _future;
  int? _classFilter;
  RangeValues _ageRange = const RangeValues(5, 16);
  String _performanceFilter = 'All';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GroupingData> _load() async {
    final children = await _service.fetchChildren();
    final recordsByChild = <int, List<AcademicRecordModel>>{};
    for (final child in children.where((c) => c.childId != null)) {
      recordsByChild[child.childId!] = await _service.fetchAcademicRecords(child.childId!);
    }
    return _GroupingData(children, recordsByChild);
  }

  List<ChildModel> _filtered(_GroupingData data) {
    return data.children.where((child) {
      final age = _service.ageOf(child);
      final records = data.recordsByChild[child.childId] ?? [];
      final latestPerformance = records.isEmpty ? null : records.first.performanceLevel;
      final classOk = _classFilter == null || child.schoolClass == _classFilter;
      final ageOk = age >= _ageRange.start.round() && age <= _ageRange.end.round();
      final performanceOk = _performanceFilter == 'All' || latestPerformance == _performanceFilter;
      return classOk && ageOk && performanceOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Student Grouping',
      child: FutureBuilder<_GroupingData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load groups: ${snapshot.error}'));
          }
          final data = snapshot.data ?? const _GroupingData([], {});
          final classOptions = data.children.map((e) => e.schoolClass).whereType<int>().toSet().toList()..sort();
          final children = _filtered(data);
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _filters(classOptions),
                const TabBar(
                  tabs: [
                    Tab(text: 'Age-wise'),
                    Tab(text: 'Class-wise'),
                    Tab(text: 'Combined'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _groupList(_service.groupByAge(children)),
                      _groupList(_service.groupByClass(children)),
                      _groupList(_service.groupByClassAndAge(children)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters(List<int> classOptions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _classFilter,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All')),
                      ...classOptions.map((e) => DropdownMenuItem<int?>(value: e, child: Text('Class $e'))),
                    ],
                    onChanged: (value) => setState(() => _classFilter = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _performanceFilter,
                    decoration: const InputDecoration(labelText: 'Performance'),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                      DropdownMenuItem(value: 'Good', child: Text('Good')),
                      DropdownMenuItem(value: 'Average', child: Text('Average')),
                      DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                    ],
                    onChanged: (value) => setState(() => _performanceFilter = value ?? 'All'),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _ageRange,
              min: 5,
              max: 16,
              divisions: 11,
              labels: RangeLabels('${_ageRange.start.round()}', '${_ageRange.end.round()}'),
              onChanged: (value) => setState(() => _ageRange = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupList(Map<String, List<ChildModel>> groups) {
    final entries = groups.entries.where((e) => e.value.isNotEmpty).toList();
    if (entries.isEmpty) return const Center(child: Text('No students match these filters'));
    return ListView(
      children: entries
          .map(
            (entry) => Card(
              child: ExpansionTile(
                title: Text('${entry.key} (${entry.value.length})'),
                children: entry.value
                    .map(
                      (child) => ListTile(
                        title: Text(child.name),
                        subtitle: Text('Age ${_service.ageOf(child)} | Class ${child.schoolClass ?? '-'} | ${child.schoolName ?? '-'}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StudentProfileScreen(child: child)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GroupingData {
  final List<ChildModel> children;
  final Map<int, List<AcademicRecordModel>> recordsByChild;
  const _GroupingData(this.children, this.recordsByChild);
}
