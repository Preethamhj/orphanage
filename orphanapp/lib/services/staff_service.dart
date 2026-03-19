import '../core/cache_store.dart';
import '../core/supabase_service.dart';
import '../models/staff_model.dart';
import 'role_manager.dart';

class StaffService {
  Future<List<StaffModel>> list({String query = ''}) async {
    final trimmed = query.trim();
    final isNumeric = int.tryParse(trimmed) != null;

    var req = SupabaseService.client.from('staff').select();
    if (trimmed.isNotEmpty) {
      if (isNumeric) {
        req = req.eq('staff_id', int.parse(trimmed));
      } else {
        req = req.ilike('name', '%$trimmed%');
      }
    }
    final data = await req.order('staff_id', ascending: false);
    final models = data.map((e) => StaffModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    await CacheStore.writeJson('cache_staff_list', data);
    return models;
  }

  Future<void> create(StaffModel model) async {
    if (!RoleManager.instance.canModifyStaff()) throw Exception('Access denied');
    await SupabaseService.client.from('staff').insert(model.toJson()..remove('staff_id'));
  }

  Future<void> update(StaffModel model) async {
    if (!RoleManager.instance.canModifyStaff()) throw Exception('Access denied');
    await SupabaseService.client.from('staff').update({
      'name': model.name,
      'role': model.role,
      'contact_number': model.contactNumber,
      'email': model.email,
      'joining_date': model.toJson()['joining_date'],
      'department': model.department,
    }).eq('staff_id', model.staffId!);
  }

  Future<void> delete(int staffId) async {
    if (!RoleManager.instance.canModifyStaff()) throw Exception('Access denied');
    await SupabaseService.client.from('staff').delete().eq('staff_id', staffId);
  }
}
