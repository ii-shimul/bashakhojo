import 'package:flutter/foundation.dart';

class SavedPropertiesNotifier extends ChangeNotifier {
  static final SavedPropertiesNotifier _instance =
      SavedPropertiesNotifier._internal();

  factory SavedPropertiesNotifier() => _instance;

  SavedPropertiesNotifier._internal();

  void notifyChange() {
    notifyListeners();
  }
}
