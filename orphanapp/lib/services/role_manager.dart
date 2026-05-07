import 'package:flutter/foundation.dart';

class RoleManager {
  RoleManager._();
  static final RoleManager instance = RoleManager._();

  final ValueNotifier<String?> currentRole = ValueNotifier<String?>(null);
  bool localAdminAuthenticated = false;

  String get role => currentRole.value ?? 'staff';
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isDonor => role == 'donor';
  bool get isAdopter => role == 'adopter';

  void setRole(String? role) {
    currentRole.value = role;
  }

  void setLocalAdminSession(bool value) {
    localAdminAuthenticated = value;
    if (value) {
      currentRole.value = 'admin';
    }
  }

  bool canViewChildren() => true;
  bool canModifyChildren() => isAdmin;
  bool canModifyAcademic() => isAdmin || isStaff;
  bool canManageSkills() => isAdmin || isStaff;

  bool canViewStaff() => true;
  bool canModifyStaff() => isAdmin;

  bool canAccessDonations() => isAdmin;
  bool canViewDonationAmount() => isAdmin;
  bool canModifyDonations() => isAdmin;

  bool canAccessAdoptions() => isAdmin || isAdopter;
  bool canModifyAdoptions() => isAdmin;
  bool canApplyAdoption() => isAdopter;

  bool canAccessRoute(String route) {
    switch (route) {
      case '/dashboard':
        return isAdmin;
      case '/children':
        return canViewChildren();
      case '/grouping':
        return isAdmin || isStaff;
      case '/staff':
        return canViewStaff();
      case '/donations':
        return canAccessDonations();
      case '/adoptions':
        return canAccessAdoptions();
      case '/student-categories':
        return isAdmin || isStaff;
      case '/skills-management':
        return isAdmin || isStaff;
      case '/donor-home':
        return isDonor;
      case '/adopter-home':
        return isAdopter;
      case '/staff-home':
        return isStaff;
      default:
        return true;
    }
  }

  String homeRoute() {
    switch (role) {
      case 'admin':
        return '/dashboard';
      case 'staff':
        return '/staff-home';
      case 'donor':
        return '/donor-home';
      case 'adopter':
        return '/adopter-home';
      default:
        return '/staff-home';
    }
  }
}
