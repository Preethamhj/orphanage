import '../core/cache_store.dart';
import '../core/supabase_service.dart';
import '../models/child_model.dart';
import 'role_manager.dart';

class ChildrenService {
  Future<List<ChildModel>> list({String query = ''}) async {
    final trimmed = query.trim();
    final isNumeric = int.tryParse(trimmed) != null;

    var req = SupabaseService.client.from('children').select();
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
    final approvedIds = approvedRows.map((e) => (e['child_id'] as num).toInt()).toSet();

    final models = data
        .map((e) => ChildModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((c) => c.childId == null || !approvedIds.contains(c.childId))
        .toList();

    await CacheStore.writeJson('cache_children_list', models.map((e) => e.toJson()).toList());
    return models;
  }

  Future<void> create(ChildModel model) async {
    if (!RoleManager.instance.canModifyChildren()) throw Exception('Access denied');
    await SupabaseService.client.from('children').insert(model.toJson()..remove('child_id'));
  }

  Future<void> update(ChildModel model) async {
    if (!RoleManager.instance.canModifyChildren()) throw Exception('Access denied');
    await SupabaseService.client.from('children').update({
      'name': model.name,
      'age': model.age,
      'gender': model.gender,
      'education': model.education,
      'health_status': model.healthStatus,
      'admission_date': model.toJson()['admission_date'],
      'guardian_details': model.guardianDetails,
    }).eq('child_id', model.childId!);
  }

  Future<void> delete(int childId) async {
    if (!RoleManager.instance.canModifyChildren()) throw Exception('Access denied');
    await SupabaseService.client.from('children').delete().eq('child_id', childId);
  }
}
