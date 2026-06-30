import 'package:firebase_auth/firebase_auth.dart';
import 'package:orca_sim/domain/repositories/auth_repository.dart';
import 'package:orca_sim/domain/services/auth_service.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository(this._authService);

  final IAuthService _authService;

  @override
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  @override
  User? get currentUser => _authService.currentUser;

  @override
  Future<String?> signInWithGoogle() => _authService.signInWithGoogle();

  @override
  Future<String?> login(String email, String senha) =>
      _authService.login(email, senha);

  @override
  Future<String?> registrar(String email, String senha) =>
      _authService.registrar(email, senha);

  @override
  Future<String?> recuperarSenha(String email) =>
      _authService.recuperarSenha(email);

  @override
  Future<void> sair() => _authService.sair();
}
