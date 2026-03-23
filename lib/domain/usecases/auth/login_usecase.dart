import 'package:orca_sim/domain/repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  Future<String?> call(String email, String senha) {
    return _authRepository.login(email, senha);
  }
}
