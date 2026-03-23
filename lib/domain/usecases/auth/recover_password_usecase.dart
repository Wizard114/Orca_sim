import 'package:orca_sim/domain/repositories/auth_repository.dart';

class RecoverPasswordUseCase {
  RecoverPasswordUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  Future<String?> call(String email) {
    return _authRepository.recuperarSenha(email);
  }
}
