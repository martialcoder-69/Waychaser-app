import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  String? uid;
  String? idToken;

  Future<void> loadFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid;
    idToken = await user?.getIdToken();
  }
}
