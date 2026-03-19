import '../core/cache_store.dart';
import '../core/date_utils.dart';
import '../core/supabase_service.dart';
import '../models/adoption_model.dart';
import 'role_manager.dart';

class AdoptionService {
  Future<List<AdoptionModel>> list({String query = ''}) async {
    final trimmed = query.trim();
    final isNumeric = int.tryParse(trimmed) != null;
    var req = SupabaseService.client.from('adoptions').select();
    if (trimmed.isNotEmpty) {
      if (isNumeric) {
        req = req.eq('child_id', int.parse(trimmed));
      } else {
        req = req.ilike('adopter_name', '%$trimmed%');
      }
    }
    final data = await req.order('adoption_id', ascending: false);
    final models = data.map((e) => AdoptionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    await CacheStore.writeJson('cache_adoptions_list', data);
    return models;
  }

  Future<void> create(AdoptionModel model) async {
    if (!(RoleManager.instance.canModifyAdoptions() || RoleManager.instance.canApplyAdoption())) {
      throw Exception('Access denied');
    }
    await SupabaseService.client.from('adoptions').insert(model.toJson()..remove('adoption_id'));
  }

  Future<void> update(AdoptionModel model) async {
    if (!RoleManager.instance.canModifyAdoptions()) throw Exception('Access denied');
    await SupabaseService.client.from('adoptions').update({
      'child_id': model.childId,
      'adopter_name': model.adopterName,
      'contact_information': model.contactInformation,
      'application_date': toIsoDate(model.applicationDate),
      'approval_status': model.approvalStatus,
      'completion_date': model.completionDate == null ? null : toIsoDate(model.completionDate!),
    }).eq('adoption_id', model.adoptionId!);
  }

  Future<void> delete(int adoptionId) async {
    if (!RoleManager.instance.canModifyAdoptions()) throw Exception('Access denied');
    await SupabaseService.client.from('adoptions').delete().eq('adoption_id', adoptionId);
  }
}
