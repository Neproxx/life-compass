import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthService(this._firebaseAuth);

  // Method to get the current user's ID
  String? getUserId() {
    return _firebaseAuth.currentUser?.uid;
  }
}
