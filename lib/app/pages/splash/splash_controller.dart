import 'package:flutter/material.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';
import 'package:orca_sim/domain/usecases/auth/get_current_user_usecase.dart';

class SplashController {
  SplashController(this._getCurrentUserUseCase, this._firestoreService);

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final IFirestoreService _firestoreService;

  late AnimationController animationController;
  late Animation<double> scaleAnimation;

  void inicializarAnimacao({required TickerProvider vsync}) {
    animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: vsync,
    )..repeat(reverse: true);
    scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
  }

  void dispose() {
    animationController.dispose();
  }

  bool get isAuthenticated => _getCurrentUserUseCase() != null;

  String rotaDestino({required bool autenticado}) {
    return autenticado ? '/home' : '/login';
  }

  Future<void> preloadWorkspaceData() async {
    if (!isAuthenticated) {
      return;
    }
    await _firestoreService.preloadProdutosEmpresa();
  }
}
