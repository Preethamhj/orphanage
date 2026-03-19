import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_state.dart';

class RealtimeSync {
  RealtimeSync._();
  static final RealtimeSync instance = RealtimeSync._();

  final List<RealtimeChannel> _channels = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _watchTable('children', 'children');
    _watchTable('staff', 'staff');
    _watchTable('donations', 'donations');
    _watchTable('donars', 'donations');
    _watchTable('adoptions', 'adoptions');
  }

  void _watchTable(String table, String dirtyKey) {
    final channel = Supabase.instance.client
        .channel('sync_$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) async {
            await SyncState.markDirty(dirtyKey);
            await SyncState.markDirty('dashboard_stats');
          },
        )
        .subscribe();
    _channels.add(channel);
  }
}
