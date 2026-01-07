import 'package:flutter/foundation.dart';

class SavedPropertiesNotifier extends ChangeNotifier {
  static final SavedPropertiesNotifier _instance = SavedPropertiesNotifier._();

  SavedPropertiesNotifier._();

  factory SavedPropertiesNotifier() {
    return _instance;
  }

  void notifyChange() {
    notifyListeners();
  }
}
