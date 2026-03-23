import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthService {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<String?> signInWithGoogle();
  Future<String?> login(String email, String senha);
  Future<String?> registrar(String email, String senha);
  Future<String?> recuperarSenha(String email);
  Future<void> sair();
}
