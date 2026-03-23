import 'package:orca_sim/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  SignInWithGoogleUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  Future<String?> call() {
    return _authRepository.signInWithGoogle();
  }
}
