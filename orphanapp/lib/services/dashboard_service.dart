import '../core/cache_store.dart';
import '../core/memory_store.dart';
import '../core/supabase_service.dart';
import '../core/sync_state.dart';

class DashboardService {
  static const _cacheKey = 'cache_dashboard_stats';
  static const _dirtyKey = 'dashboard_stats';

  Future<int> _count(String table) async {
    final data = await SupabaseService.client.from(table).select('*');
    return data.length;
  }

  Future<Map<String, dynamic>> getStats() async {
    final donationTable = await _resolveDonationsTable();
    final children = await _count('children');
    final staff = await _count('staff');
    final donations = await _count(donationTable);
    final adoptions = await _count('adoptions');

    final donationRows = await SupabaseService.client
        .from(donationTable)
        .select('donation_amount');
    double totalAmount = 0;
    for (final row in donationRows) {
      totalAmount += (row['donation_amount'] as num?)?.toDouble() ?? 0;
    }

    final stats = <String, dynamic>{
      'children': children,
      'staff': staff,
      'donations': donations,
      'adoptions': adoptions,
      'totalDonationAmount': totalAmount,
    };

    await _attachStudentIntelligence(stats);

    await CacheStore.writeJson(_cacheKey, stats);
    MemoryStore.set(_cacheKey, stats);
    await SyncState.clearDirty(_dirtyKey);
    return stats;
  }

  Future<String> _resolveDonationsTable() async {
    try {
      await SupabaseService.client
          .from('donars')
          .select('donation_id')
          .limit(1);
      return 'donars';
    } catch (_) {
      return 'donations';
    }
  }

  Future<void> _attachStudentIntelligence(Map<String, dynamic> stats) async {
    try {
      final childrenRows = await SupabaseService.client
          .from('children')
          .select('age, class, academic_status, last_exam_marks');
      final academicRows = await SupabaseService.client
          .from('academic_records')
          .select('child_id, class, year, marks')
          .eq('year', 2025);
      final skillRows = await SupabaseService.client
          .from('child_skills')
          .select('skill_name');

      final studentsPerClass = <String, int>{};
      final ageGroups = <String, int>{'5-8': 0, '9-12': 0, '13-16': 0, '17+': 0};
      for (final row in childrenRows) {
        final klass = (row['class'] as num?)?.toInt();
        if (klass != null) {
          final key = klass.toString();
          studentsPerClass[key] = (studentsPerClass[key] ?? 0) + 1;
        }

        final age = (row['age'] as num?)?.toInt();
        if (age == null) continue;
        if (age >= 5 && age <= 8) {
          ageGroups['5-8'] = ageGroups['5-8']! + 1;
        } else if (age <= 12) {
          ageGroups['9-12'] = ageGroups['9-12']! + 1;
        } else if (age <= 16) {
          ageGroups['13-16'] = ageGroups['13-16']! + 1;
        } else {
          ageGroups['17+'] = ageGroups['17+']! + 1;
        }
      }

      final academicStatus = <String, int>{
        'Excellent Student': 0,
        'Good Student': 0,
        'Average Student': 0,
        'Weak Student': 0,
      };
      final markTotals = <String, double>{};
      final markCounts = <String, int>{};
      var weakStudents = 0;
      for (final row in childrenRows) {
        final rawStatus = (row['academic_status'] as String?)?.trim();
        final marks = (row['last_exam_marks'] as num?)?.toDouble();
        final status = _normalizeAcademicStatus(rawStatus, marks);
        academicStatus[status] = (academicStatus[status] ?? 0) + 1;
        if (status == 'Weak Student') weakStudents++;
      }

      for (final row in academicRows) {
        final marks = (row['marks'] as num?)?.toDouble();
        final klass = (row['class'] as num?)?.toInt();
        if (marks == null) continue;

        if (klass != null) {
          final key = klass.toString();
          markTotals[key] = (markTotals[key] ?? 0) + marks;
          markCounts[key] = (markCounts[key] ?? 0) + 1;
        }
      }

      final averageMarksPerClass = markTotals.map(
        (klass, total) => MapEntry(klass, total / markCounts[klass]!),
      );

      final skillsCounts = <String, int>{};
      for (final row in skillRows) {
        final skill = (row['skill_name'] as String?)?.trim();
        if (skill == null || skill.isEmpty) continue;
        skillsCounts[skill] = (skillsCounts[skill] ?? 0) + 1;
      }

      stats['studentsPerClass'] = studentsPerClass;
      stats['averageMarksPerClass'] = averageMarksPerClass;
      stats['weakStudents'] = weakStudents;
      stats['studentsByAcademicStatus'] = academicStatus;
      stats['studentsByAgeGroup'] = ageGroups;
      stats['skillsCounts'] = skillsCounts;
      stats['classDistribution'] = studentsPerClass.map(
        (klass, count) => MapEntry('Class $klass', count),
      );
    } catch (_) {
      stats['studentsPerClass'] = <String, int>{};
      stats['averageMarksPerClass'] = <String, double>{};
      stats['weakStudents'] = 0;
      stats['studentsByAcademicStatus'] = <String, int>{};
      stats['studentsByAgeGroup'] = <String, int>{};
      stats['skillsCounts'] = <String, int>{};
      stats['classDistribution'] = <String, int>{};
    }
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

    if (marks == null) return 'Weak Student';
    if (marks >= 85) return 'Excellent Student';
    if (marks >= 70) return 'Good Student';
    if (marks >= 50) return 'Average Student';
    return 'Weak Student';
  }
}
