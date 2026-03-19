import 'package:flutter/foundation.dart';

class RoleSession {
  RoleSession._();
  static final RoleSession instance = RoleSession._();

  final ValueNotifier<String?> role = ValueNotifier<String?>(null);

  bool get isAdmin => role.value == 'admin';
  bool get isStaff => role.value == 'staff';
  bool get isDonor => role.value == 'donor';
  bool get isAdopter => role.value == 'adopter';
}
