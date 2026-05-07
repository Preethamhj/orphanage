import '../core/supabase_service.dart';
import '../models/child_model.dart';
import '../models/child_skill_model.dart';
import '../services/children_service.dart';
import '../services/role_manager.dart';

class StudentGroupingService {
  final _childrenService = ChildrenService();

  String calculateAcademicStatus(double? marks) {
    if (marks == null) return 'Weak Student';
    if (marks >= 85) return 'Excellent Student';
    if (marks >= 70) return 'Good Student';
    if (marks >= 50) return 'Average Student';
    return 'Weak Student';
  }

  Future<List<ChildModel>> fetchChildren({bool forceRefresh = false}) async {
    return _childrenService.list(query: '');
  }

  Future<List<ChildSkillModel>> fetchSkills(int childId) async {
    final data = await SupabaseService.client
        .from('child_skills')
        .select()
        .eq('child_id', childId)
        .order('created_at', ascending: false);
    return data
        .map(
          (e) => ChildSkillModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> addSkill(ChildSkillModel skill) async {
    if (!RoleManager.instance.canManageSkills()) {
      throw Exception('Access denied');
    }
    await SupabaseService.client
        .from('child_skills')
        .insert(skill.toJson()..remove('id'));
  }

  Future<void> updateSkill(ChildSkillModel skill) async {
    if (!RoleManager.instance.canManageSkills()) {
      throw Exception('Access denied');
    }
    if (skill.id == null) {
      throw Exception('Skill ID is required');
    }
    final payload = skill.toJson()..remove('id');
    await SupabaseService.client
        .from('child_skills')
        .update(payload)
        .eq('id', skill.id!);
  }

  Future<void> deleteSkill(String id) async {
    if (!RoleManager.instance.canManageSkills()) {
      throw Exception('Access denied');
    }
    await SupabaseService.client.from('child_skills').delete().eq('id', id);
  }

  Map<String, int> groupByAcademicStatus(List<ChildModel> children) {
    final result = <String, int>{
      'Excellent Student': 0,
      'Good Student': 0,
      'Average Student': 0,
      'Weak Student': 0,
    };
    for (final child in children) {
      final status = _normalizeAcademicStatus(
        child.academicStatus,
        child.lastExamMarks,
      );
      result[status] = (result[status] ?? 0) + 1;
    }
    return result;
  }

  String _normalizeAcademicStatus(String? status, double? marks) {
    switch (status) {
      case 'Excellent Student':
      case 'Good Student':
      case 'Average Student':
      case 'Weak Student':
        return status!;
      case 'Best Student':
        return 'Excellent Student';
    }
    return calculateAcademicStatus(marks);
  }

  Map<String, List<ChildModel>> groupByAge(List<ChildModel> children) {
    final groups = <String, List<ChildModel>>{
      '5-8': [],
      '9-12': [],
      '13-16': [],
      '17+': [],
    };
    for (final child in children) {
      final age = child.currentAge;
      if (age >= 5 && age <= 8) {
        groups['5-8']!.add(child);
      } else if (age >= 9 && age <= 12) {
        groups['9-12']!.add(child);
      } else if (age >= 13 && age <= 16) {
        groups['13-16']!.add(child);
      } else {
        groups['17+']!.add(child);
      }
    }
    return groups;
  }

  Map<String, List<ChildModel>> groupBySkill(List<ChildModel> children) {
    final groups = <String, List<ChildModel>>{};
    for (final child in children) {
      for (final skill in child.skills) {
        final key = skill.skillName;
        groups.putIfAbsent(key, () => []).add(child);
      }
    }
    return groups;
  }

  Future<Map<String, int>> mostCommonSkills() async {
    final rows = await SupabaseService.client
        .from('child_skills')
        .select('skill_name')
        .order('skill_name');
    final counts = <String, int>{};
    for (final row in rows) {
      final skill = (row['skill_name'] as String?) ?? 'Unknown';
      counts[skill] = (counts[skill] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> ageDistribution(List<ChildModel> children) {
    final result = <String, int>{'5-8': 0, '9-12': 0, '13-16': 0, '17+': 0};
    for (final child in children) {
      final age = child.currentAge;
      if (age >= 5 && age <= 8) {
        result['5-8'] = result['5-8']! + 1;
      } else if (age >= 9 && age <= 12) {
        result['9-12'] = result['9-12']! + 1;
      } else if (age >= 13 && age <= 16) {
        result['13-16'] = result['13-16']! + 1;
      } else {
        result['17+'] = result['17+']! + 1;
      }
    }
    return result;
  }

  Map<String, int> classDistribution(List<ChildModel> children) {
    final result = <String, int>{};
    for (final child in children) {
      final key = child.schoolClass == null
          ? 'Unknown class'
          : 'Class ${child.schoolClass}';
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  Map<String, int> skillDistribution(List<ChildModel> children) {
    final result = <String, int>{};
    for (final child in children) {
      for (final skill in child.skills) {
        result[skill.skillName] = (result[skill.skillName] ?? 0) + 1;
      }
    }
    return result;
  }
}
