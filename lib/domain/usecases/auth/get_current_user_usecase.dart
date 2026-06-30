import 'package:firebase_auth/firebase_auth.dart';

import 'package:orca_sim/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  User? call() {
    return _authRepository.currentUser;
  }
}
