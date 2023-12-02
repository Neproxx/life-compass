import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  set userId(String? id) {
    _userId = id;
    notifyListeners();
  }
}
