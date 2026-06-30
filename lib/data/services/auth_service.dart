import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orca_sim/domain/services/auth_service.dart';

class AuthService implements IAuthService {
  static const googleSignInCancelled = 'google_sign_in_cancelled';

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return googleSignInCancelled;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      return null;
    } on FirebaseAuthException catch (e) {
      return 'Erro no login Google: ${e.message}';
    } catch (_) {
      return 'Falha ao iniciar login com Google. Verifique sua conexão.';
    }
  }

  @override
  Future<String?> login(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'E-mail não encontrado.';
      }
      if (e.code == 'wrong-password') {
        return 'Senha incorreta.';
      }
      if (e.code == 'invalid-credential') {
        return 'E-mail ou senha inválidos.';
      }
      return 'Erro no login: ${e.message}';
    } catch (e) {
      return 'Erro desconhecido: $e';
    }
  }

  @override
  Future<String?> registrar(String email, String senha) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'A senha é muito fraca.';
      }
      if (e.code == 'email-already-in-use') {
        return 'Este e-mail já está cadastrado.';
      }
      return 'Erro no cadastro: ${e.message}';
    } catch (e) {
      return 'Erro ao cadastrar: $e';
    }
  }

  @override
  Future<String?> recuperarSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        return 'E-mail invalido.';
      }
      if (e.code == 'user-not-found') {
        return 'E-mail nao encontrado.';
      }
      return 'Erro ao recuperar senha: ${e.message}';
    } catch (e) {
      return 'Erro ao recuperar senha: $e';
    }
  }

  @override
  Future<void> sair() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
