import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_shell.dart';

class RoleHomeScreen extends StatelessWidget {
  final String title;
  final String description;
  final List<(String label, String route)> actions;
  const RoleHomeScreen({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      child: FutureBuilder<Map<String, int>>(
        future: _loadOverview(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? const {'children': 0, 'staff': 0, 'adoptions': 0};
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/dashboard_banner.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.2)),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              title,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(description),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.6,
                  children: [
                    _overviewCard(context, 'Total Children', '${stats['children'] ?? 0}', Icons.child_care_outlined),
                    _overviewCard(context, 'Total Staff', '${stats['staff'] ?? 0}', Icons.badge_outlined),
                    _overviewCard(context, 'Total Adoptions', '${stats['adoptions'] ?? 0}', Icons.favorite_outline),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actions
                      .map(
                        (a) => ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, a.$2),
                          child: Text(a.$1),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _loadOverview() async {
    final client = Supabase.instance.client;
    final children = (await client.from('children').select('child_id')).length;
    final staff = (await client.from('staff').select('staff_id')).length;
    final adoptions = (await client.from('adoptions').select('adoption_id')).length;
    return {'children': children, 'staff': staff, 'adoptions': adoptions};
  }

  Widget _overviewCard(BuildContext context, String title, String value, IconData icon) {
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
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
