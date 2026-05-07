import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/cache_store.dart';
import '../../services/dashboard_service.dart';
import '../../services/role_manager.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/last_synced_label.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _lastSyncedAt;
  final _service = DashboardService();
  List<Map<String, dynamic>> _recentLogins = [];
  List<Map<String, dynamic>> _pendingUsers = [];
  RealtimeChannel? _loginChannel;

  Future<Map<String, dynamic>> _loadStats() async {
    final stats = await _service.getStats();
    _lastSyncedAt = await CacheStore.readSavedAt('cache_dashboard_stats');
    _recentLogins = List<Map<String, dynamic>>.from(
      await Supabase.instance.client
          .from('login_logs')
          .select('email, role, login_time')
          .order('login_time', ascending: false)
          .limit(8),
    );
    _pendingUsers = List<Map<String, dynamic>>.from(
      await Supabase.instance.client
          .from('users')
          .select('id, email, full_name, role, approval_status, created_at')
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false)
          .limit(20),
    );
    return stats;
  }

  Future<void> _approveUser(String userId) async {
    await Supabase.instance.client
        .from('users')
        .update({'approval_status': 'approved'})
        .eq('id', userId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User approved')));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (RoleManager.instance.isAdmin) {
      _loginChannel = Supabase.instance.client
          .channel('admin_login_notifier')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'login_logs',
            callback: (payload) async {
              final email = (payload.newRecord['email'] ?? '').toString();
              final role = (payload.newRecord['role'] ?? '').toString();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('New login: $email ($role)')),
              );
              setState(() {});
            },
          )
          .subscribe();
    }
  }

  @override
  void dispose() {
    if (_loginChannel != null) {
      Supabase.instance.client.removeChannel(_loginChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final popped = await Navigator.of(context).maybePop();
        if (!popped) {
          await SystemNavigator.pop();
        }
      },
      child: AppShell(
        title: 'Dashboard',
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load stats: ${snapshot.error}'),
              );
            }

            final stats = snapshot.data ?? {};
            final cards = <({String title, String value, IconData icon})>[
              (
                title: 'Total Children',
                value: '${stats['children'] ?? 0}',
                icon: Icons.child_care_outlined,
              ),
              (
                title: 'Total Staff',
                value: '${stats['staff'] ?? 0}',
                icon: Icons.badge_outlined,
              ),
              (
                title: 'Total Donations',
                value: '${stats['donations'] ?? 0}',
                icon: Icons.volunteer_activism_outlined,
              ),
              (
                title: 'Total Adoptions',
                value: '${stats['adoptions'] ?? 0}',
                icon: Icons.favorite_outline,
              ),
              (
                title: 'Donation Amount',
                value: '${stats['totalDonationAmount'] ?? 0}',
                icon: Icons.currency_rupee,
              ),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                final bannerHeight = compact ? 180.0 : 264.0;
                final links = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _linkButton(context, 'Children', '/children'),
                    _linkButton(context, 'Staff', '/staff'),
                    _linkButton(context, 'Donations', '/donations'),
                    _linkButton(context, 'Adoptions', '/adoptions'),
                    _linkButton(context, 'Student Groups', '/grouping'),
                    _linkButton(
                      context,
                      'Student Categories',
                      '/student-categories',
                    ),
                    _linkButton(
                      context,
                      'Skills Management',
                      '/skills-management',
                    ),
                    _linkButton(context, 'Profile', '/profile'),
                  ],
                );

                final cardRatio = constraints.maxWidth < 380 ? 1.35 : 1.65;

                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            width: double.infinity,
                            height: bannerHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/dashboard_banner.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.2),
                                ),
                                const Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Welcome to OrphanAge',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LastSyncedLabel(lastSyncedAt: _lastSyncedAt),
                        const SizedBox(height: 8),
                        GridView.builder(
                          itemCount: cards.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: cardRatio,
                              ),
                          itemBuilder: (context, index) {
                            final c = cards[index];
                            return _card(context, c.title, c.value, c.icon);
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Student Intelligence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _studentIntelligence(stats),
                        const SizedBox(height: 14),
                        const Text(
                          'Quick Links',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        links,
                        const SizedBox(height: 14),
                        const Text(
                          'Recent Logins',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _recentLogins.isEmpty
                                ? const Text('No recent logins')
                                : Column(
                                    children: _recentLogins
                                        .map(
                                          (e) => ListTile(
                                            dense: true,
                                            title: Text(
                                              '${e['email']} (${e['role']})',
                                            ),
                                            subtitle: Text(
                                              (e['login_time'] ?? '')
                                                  .toString(),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Pending User Approvals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _pendingUsers.isEmpty
                                ? const Text('No pending users')
                                : Column(
                                    children: _pendingUsers
                                        .map(
                                          (u) => ListTile(
                                            dense: true,
                                            title: Text(
                                              '${u['email']} (${u['role']})',
                                            ),
                                            subtitle: Text(
                                              (u['full_name'] ?? '').toString(),
                                            ),
                                            trailing: TextButton(
                                              onPressed: () => _approveUser(
                                                (u['id'] ?? '').toString(),
                                              ),
                                              child: const Text('Approve'),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkButton(BuildContext context, String label, String route) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(label),
    );
  }

  Widget _studentIntelligence(Map<String, dynamic> stats) {
    final weakStudents = stats['weakStudents'] ?? 0;
    final academicStatus = Map<String, dynamic>.from(
      (stats['studentsByAcademicStatus'] as Map?) ?? {},
    );
    final ageGroups = Map<String, dynamic>.from(
      (stats['studentsByAgeGroup'] as Map?) ?? {},
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber_outlined),
              title: const Text('Weak Students'),
              trailing: Text('$weakStudents'),
            ),
            const Divider(),
            const Text(
              'Academic Distribution',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: academicStatus.entries
                  .map(
                    (entry) =>
                        Chip(label: Text('${entry.key}: ${entry.value}')),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Age Distribution',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ageGroups.entries
                  .map(
                    (entry) =>
                        Chip(label: Text('${entry.key}: ${entry.value}')),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
