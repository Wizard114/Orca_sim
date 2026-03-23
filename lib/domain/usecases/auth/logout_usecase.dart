import 'package:orca_sim/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  LogoutUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  Future<void> call() {
    return _authRepository.sair();
  }
}
