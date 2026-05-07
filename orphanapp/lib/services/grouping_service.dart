import '../core/cache_store.dart';
import '../core/memory_store.dart';
import '../core/supabase_service.dart';
import '../models/academic_model.dart';
import '../models/child_model.dart';
import 'role_manager.dart';

class GroupingService {
  static const _childrenCacheKey = 'cache_student_intelligence_children';

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  int ageOf(ChildModel child) => child.dob == null ? child.age : calculateAge(child.dob!);

  Map<String, List<ChildModel>> groupByAge(List<ChildModel> children) {
    final groups = <String, List<ChildModel>>{'5-8': [], '9-12': [], '13-16': []};
    for (final child in children) {
      final age = ageOf(child);
      if (age >= 5 && age <= 8) groups['5-8']!.add(child);
      if (age >= 9 && age <= 12) groups['9-12']!.add(child);
      if (age >= 13 && age <= 16) groups['13-16']!.add(child);
    }
    return groups;
  }

  Map<String, List<ChildModel>> groupByClass(List<ChildModel> children) {
    final groups = <String, List<ChildModel>>{};
    for (final child in children) {
      final key = child.schoolClass == null ? 'Class not set' : 'Class ${child.schoolClass}';
      groups.putIfAbsent(key, () => []).add(child);
    }
    return groups;
  }

  Map<String, List<ChildModel>> groupByClassAndAge(List<ChildModel> children) {
    final groups = <String, List<ChildModel>>{};
    for (final child in children) {
      final age = ageOf(child);
      final range = age <= 8
          ? '5-8'
          : age <= 12
              ? '9-12'
              : age <= 16
                  ? '13-16'
                  : 'Other';
      final classLabel = child.schoolClass == null ? 'Class not set' : 'Class ${child.schoolClass}';
      groups.putIfAbsent('$classLabel - Age $range', () => []).add(child);
    }
    return groups;
  }

  String calculatePerformanceLevel(num marks) {
    if (marks >= 85) return 'Excellent';
    if (marks >= 70) return 'Good';
    if (marks >= 50) return 'Average';
    return 'Poor';
  }

  Future<List<ChildModel>> fetchChildren({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final mem = MemoryStore.get<List<ChildModel>>(_childrenCacheKey);
      if (mem != null) return mem;

      final cached = await CacheStore.readJson<List<ChildModel>>(
        _childrenCacheKey,
        (json) => (json as List)
            .map((e) => ChildModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
      if (cached != null) {
        MemoryStore.set(_childrenCacheKey, cached);
        return cached;
      }
    }

    final data = await SupabaseService.client.from('children').select().order('child_id');
    final children = data.map((e) => ChildModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    await CacheStore.writeJson(_childrenCacheKey, children.map((e) => e.toJson()).toList());
    MemoryStore.set(_childrenCacheKey, children);
    return children;
  }

  Future<List<AcademicRecordModel>> fetchAcademicRecords(int childId) async {
    final data = await SupabaseService.client
        .from('academic_records')
        .select()
        .eq('child_id', childId)
        .order('year', ascending: false);
    return data.map((e) => AcademicRecordModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> insertAcademicRecord(AcademicRecordModel record) async {
    if (!RoleManager.instance.isAdmin && !RoleManager.instance.isStaff) {
      throw Exception('Access denied');
    }
    final payload = record.toJson()..remove('id');
    await SupabaseService.client.from('academic_records').insert(payload);
  }

  Future<void> updateChildDetails(ChildModel child) async {
    if (!RoleManager.instance.isAdmin && !RoleManager.instance.isStaff) {
      throw Exception('Access denied');
    }
    await SupabaseService.client.from('children').update({
      'dob': child.dob?.toIso8601String().split('T').first,
      'class': child.schoolClass,
      'section': child.section,
      'school_name': child.schoolName,
    }).eq('child_id', child.childId!);
    MemoryStore.remove(_childrenCacheKey);
  }

  Future<Map<int, int>> totalStudentsPerClass() async {
    final children = await fetchChildren();
    final result = <int, int>{};
    for (final child in children) {
      final klass = child.schoolClass;
      if (klass != null) result[klass] = (result[klass] ?? 0) + 1;
    }
    return result;
  }

  Future<Map<int, double>> averageMarksPerClass() async {
    final rows = await SupabaseService.client.from('academic_records').select('class, marks');
    final totals = <int, double>{};
    final counts = <int, int>{};
    for (final row in rows) {
      final klass = (row['class'] as num?)?.toInt();
      final marks = (row['marks'] as num?)?.toDouble();
      if (klass == null || marks == null) continue;
      totals[klass] = (totals[klass] ?? 0) + marks;
      counts[klass] = (counts[klass] ?? 0) + 1;
    }
    return totals.map((klass, total) => MapEntry(klass, total / counts[klass]!));
  }

  Future<List<AcademicRecordModel>> weakStudents() async {
    final rows = await SupabaseService.client
        .from('academic_records')
        .select()
        .lt('marks', 50)
        .order('marks');
    return rows.map((e) => AcademicRecordModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
