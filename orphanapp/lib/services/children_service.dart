import '../core/cache_store.dart';
import '../core/supabase_service.dart';
import '../models/child_model.dart';
import 'role_manager.dart';

class ChildrenService {
  Future<List<ChildModel>> list({String query = ''}) async {
    final trimmed = query.trim();
    final isNumeric = int.tryParse(trimmed) != null;

    var req = SupabaseService.client
        .from('children')
        .select('*, child_skills(*)');
    if (trimmed.isNotEmpty) {
      if (isNumeric) {
        req = req.eq('child_id', int.parse(trimmed));
      } else {
        req = req.ilike('name', '%$trimmed%');
      }
    }

    final data = await req.order('child_id', ascending: false);
    final approvedRows = await SupabaseService.client
        .from('adoptions')
        .select('child_id')
        .eq('approval_status', 'approved');
    final approvedIds = approvedRows
        .map((e) => (e['child_id'] as num).toInt())
        .toSet();

    final models = data
        .map((e) => ChildModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((c) => c.childId == null || !approvedIds.contains(c.childId))
        .toList();

    await CacheStore.writeJson(
      'cache_children_list',
      models.map((e) => e.toJson(includeSkills: true)).toList(),
    );
    return models;
  }

  Future<void> create(ChildModel model) async {
    if (!RoleManager.instance.canModifyChildren())
      throw Exception('Access denied');
    final payload = model.toJson(includeSkills: false)
      ..remove('child_id')
      ..remove('child_skills');
    await SupabaseService.client.from('children').insert(payload);
  }

  Future<void> update(ChildModel model) async {
    if (!RoleManager.instance.canModifyChildren())
      throw Exception('Access denied');
    final payload = model.toJson(includeSkills: false)
      ..remove('child_id')
      ..remove('child_skills');
    await SupabaseService.client
        .from('children')
        .update(payload)
        .eq('child_id', model.childId!);
  }

  Future<void> delete(int childId) async {
    if (!RoleManager.instance.canModifyChildren())
      throw Exception('Access denied');
    await SupabaseService.client
        .from('children')
        .delete()
        .eq('child_id', childId);
  }
}
