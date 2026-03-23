import 'package:flutter/material.dart';
import 'package:orca_sim/app/pages/home/home_view.dart';
import 'package:orca_sim/app/pages/login/login_view.dart';
import 'package:orca_sim/app/pages/splash/splash_controller.dart';
import 'package:orca_sim/injection.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  final SplashController _controller = getIt<SplashController>();

  @override
  void initState() {
    super.initState();
    _controller.inicializarAnimacao(vsync: this);

    Future.delayed(const Duration(seconds: 3), _navigateFromSplash);
  }

  Future<void> _navigateFromSplash() async {
    if (!mounted) {
      return;
    }

    await _controller.preloadWorkspaceData();
    if (!mounted) {
      return;
    }

    final destino = _controller.rotaDestino(
      autenticado: _controller.isAuthenticated,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            destino == '/home' ? const HomeView() : const LoginView(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _controller.scaleAnimation,
              child: SizedBox(
                width: 150,
                height: 150,
                child: Image.asset('assets/logo.png'),
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.greenAccent,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Carregando sistema...',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
