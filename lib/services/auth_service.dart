import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Certifique-se que esta linha está aqui

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- FUNÇÃO QUE ESTAVA FALTANDO ---
  Future<String?> signInWithGoogle() async {
    try {
      // 1. Inicia o fluxo de login interativo do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // O usuário fechou a janelinha do Google sem logar
        return null;
      }

      // 2. Obtém os detalhes de autenticação do pedido
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Cria uma credencial nova para o Firebase usando o token do Google
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Faz o login no Firebase com essa credencial
      await _auth.signInWithCredential(credential);

      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return 'Erro no login Google: ${e.message}';
    } catch (e) {
      return 'Falha ao iniciar login com Google. Verifique sua conexão.';
    }
  }
  // ----------------------------------

  Future<String?> login(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')
        return 'E-mail não encontrado.';
      else if (e.code == 'wrong-password')
        return 'Senha incorreta.';
      else if (e.code == 'invalid-credential')
        return 'E-mail ou senha inválidos.';
      return 'Erro no login: ${e.message}';
    } catch (e) {
      return 'Erro desconhecido: $e';
    }
  }

  Future<String?> registrar(String email, String senha) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password')
        return 'A senha é muito fraca.';
      else if (e.code == 'email-already-in-use')
        return 'Este e-mail já está cadastrado.';
      return 'Erro no cadastro: ${e.message}';
    } catch (e) {
      return 'Erro ao cadastrar: $e';
    }
  }

  Future<void> sair() async {
    await _googleSignIn.signOut(); // Desloga do Google
    await _auth.signOut(); // Desloga do Firebase
  }
}
