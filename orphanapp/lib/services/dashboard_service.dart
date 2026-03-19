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
    final dirty = await SyncState.isDirty(_dirtyKey);
    if (!dirty) {
      final mem = MemoryStore.get<Map<String, dynamic>>(_cacheKey);
      if (mem != null) return mem;

      final cached = await CacheStore.readJsonAny<Map<String, dynamic>>(
        _cacheKey,
        (json) => Map<String, dynamic>.from(json as Map),
      );
      if (cached != null) {
        MemoryStore.set(_cacheKey, cached);
        return cached;
      }
    }

    final donationTable = await _resolveDonationsTable();
    final children = await _count('children');
    final staff = await _count('staff');
    final donations = await _count(donationTable);
    final adoptions = await _count('adoptions');

    final donationRows = await SupabaseService.client.from(donationTable).select('donation_amount');
    double totalAmount = 0;
    for (final row in donationRows) {
      totalAmount += (row['donation_amount'] as num?)?.toDouble() ?? 0;
    }

    final stats = {
      'children': children,
      'staff': staff,
      'donations': donations,
      'adoptions': adoptions,
      'totalDonationAmount': totalAmount,
    };

    await CacheStore.writeJson(_cacheKey, stats);
    MemoryStore.set(_cacheKey, stats);
    await SyncState.clearDirty(_dirtyKey);
    return stats;
  }

  Future<String> _resolveDonationsTable() async {
    try {
      await SupabaseService.client.from('donations').select('donation_id').limit(1);
      return 'donations';
    } catch (_) {
      return 'donars';
    }
  }
}
