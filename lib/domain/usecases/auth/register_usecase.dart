import 'package:orca_sim/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  Future<String?> call(String email, String senha) {
    return _authRepository.registrar(email, senha);
  }
}
