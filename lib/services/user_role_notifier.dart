import 'package:flutter/foundation.dart';

class UserRoleNotifier extends ChangeNotifier {
  static final UserRoleNotifier _instance = UserRoleNotifier._();

  UserRoleNotifier._();

  factory UserRoleNotifier() {
    return _instance;
  }

  String? _role;

  String? get role {
    return _role;
  }

  void setRole(String? newRole) {
    _role = newRole;
    notifyListeners();
  }
}
