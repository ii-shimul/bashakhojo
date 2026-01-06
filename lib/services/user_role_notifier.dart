import 'package:flutter/foundation.dart';

/// A simple notifier to trigger home screen rebuild when user role changes
class UserRoleNotifier extends ChangeNotifier {
  static final UserRoleNotifier _instance = UserRoleNotifier._internal();

  factory UserRoleNotifier() => _instance;

  UserRoleNotifier._internal();

  String? _role;

  String? get role => _role;

  void setRole(String? role) {
    _role = role;
    notifyListeners();
  }
}
