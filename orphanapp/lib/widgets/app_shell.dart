import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_manager.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showAccountActions;
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showAccountActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final role = RoleManager.instance.role;
    final isAdmin = role == 'admin';
    final topActions = <Widget>[
      if (showAccountActions)
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      if (showAccountActions)
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await authService.signOut();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
        ),
      ...?actions,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: topActions),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.home_work_rounded,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'OrphanAge',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _item(context, 'Home', RoleManager.instance.homeRoute(), Icons.dashboard_outlined),
              _item(context, 'Children', '/children', Icons.child_care_outlined),
              if (isAdmin || role == 'staff') _item(context, 'Student Groups', '/grouping', Icons.school_outlined),
              if (isAdmin || role == 'staff') _item(context, 'Student Skills', '/skills-management', Icons.auto_awesome),
              _item(context, 'Staff', '/staff', Icons.badge_outlined),
              if (isAdmin) _item(context, 'Donations', '/donations', Icons.volunteer_activism_outlined),
              if (isAdmin || role == 'adopter') _item(context, 'Adoptions', '/adoptions', Icons.favorite_border),
              _item(context, 'Profile', '/profile', Icons.person_outline),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 700;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 12, vertical: 12),
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String label, String route, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name == route) return;
        Navigator.pushNamed(context, route);
      },
    );
  }
}
