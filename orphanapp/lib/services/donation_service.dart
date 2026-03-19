import '../core/cache_store.dart';
import '../core/date_utils.dart';
import '../core/supabase_service.dart';
import '../models/donation_model.dart';
import 'role_manager.dart';

class DonationService {
  static const _table = 'donars';

  Future<List<DonationModel>> list({DateTime? from, DateTime? to}) async {
    var req = SupabaseService.client.from(_table).select();
    if (from != null) req = req.gte('donation_date', toIsoDate(from));
    if (to != null) req = req.lte('donation_date', toIsoDate(to));
    final data = await req.order('donation_id', ascending: false);
    final models = data.map((e) => DonationModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    await CacheStore.writeJson('cache_donations_list', data);
    return models;
  }

  Future<void> create(DonationModel model) async {
    if (!RoleManager.instance.canModifyDonations()) throw Exception('Access denied');
    await SupabaseService.client.from(_table).insert(model.toJson()..remove('donation_id'));
  }

  Future<void> update(DonationModel model) async {
    if (!RoleManager.instance.canModifyDonations()) throw Exception('Access denied');
    await SupabaseService.client.from(_table).update({
      'donor_name': model.donorName,
      'donation_type': model.donationType,
      'donation_amount': model.donationAmount,
      'payment_method': model.paymentMethod,
      'donation_date': toIsoDate(model.donationDate),
      'remarks': model.remarks,
    }).eq('donation_id', model.donationId!);
  }

  Future<void> delete(int donationId) async {
    if (!RoleManager.instance.canModifyDonations()) throw Exception('Access denied');
    await SupabaseService.client.from(_table).delete().eq('donation_id', donationId);
  }
}
