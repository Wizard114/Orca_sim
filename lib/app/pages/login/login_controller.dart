import 'package:flutter/material.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';
import 'package:orca_sim/domain/usecases/auth/login_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/recover_password_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/register_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/sign_in_with_google_usecase.dart';

class LoginController {
  LoginController(
    this._loginUseCase,
    this._registerUseCase,
    this._recoverPasswordUseCase,
    this._signInWithGoogleUseCase,
    this._firestoreService,
  );

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final RecoverPasswordUseCase _recoverPasswordUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final IFirestoreService _firestoreService;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  final ValueNotifier<bool> isLogin = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> lembrarDeMim = ValueNotifier<bool>(true);

  String get botaoTexto => isLogin.value ? 'ACESSAR SISTEMA' : 'CADASTRAR';
  String get alternarTexto => isLogin.value
      ? 'Ainda nao tem conta? Crie aqui'
      : 'Ja tem conta? Entre aqui';

  void alternarModo() {
    isLogin.value = !isLogin.value;
  }

  void setLembrarDeMim(bool value) {
    lembrarDeMim.value = value;
  }

  bool credenciaisPreenchidas({
    required String email,
    required String senha,
  }) {
    return email.trim().isNotEmpty && senha.trim().isNotEmpty;
  }

  bool emailPreenchido(String email) => email.trim().isNotEmpty;

  Future<String?> recuperarSenha(String email) {
    return _recoverPasswordUseCase(email.trim());
  }

  Future<String?> submit({
    required String email,
    required String senha,
  }) async {
    isLoading.value = true;

    try {
      if (isLogin.value) {
        final error = await _loginUseCase(email, senha);
        if (error == null) {
          await _firestoreService.preloadProdutosEmpresa();
        }
        return error;
      }

      final error = await _registerUseCase(email, senha);
      if (error == null) {
        await _firestoreService.preloadProdutosEmpresa();
      }
      return error;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final error = await _signInWithGoogleUseCase();
      if (error == null) {
        await _firestoreService.preloadProdutosEmpresa();
      }
      return error;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    isLogin.dispose();
    isLoading.dispose();
    lembrarDeMim.dispose();
  }
}
