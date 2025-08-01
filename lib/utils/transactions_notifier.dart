import 'package:flutter/foundation.dart';

class TransactionsNotifier extends ChangeNotifier {
  TransactionsNotifier._();
  static final instance = TransactionsNotifier._();

  void notify() {
    notifyListeners();
  }
  
  void refresh() {
    notifyListeners();
  }
}
