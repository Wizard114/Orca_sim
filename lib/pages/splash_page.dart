import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 3), () {
      _verificarLogin();
    });
  }

  void _verificarLogin() {
    User? user = FirebaseAuth.instance.currentUser;
    _controller.dispose();
    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  user != null ? const HomePage() : const LoginPage()));
    }
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
              scale: _scaleAnimation,
              child: SizedBox(
                width: 150,
                height: 150,
                // CORREÇÃO: Agora aponta para logo.png
                child: Image.asset('assets/logo.png'),
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                    color: Colors.greenAccent, strokeWidth: 2)),
            const SizedBox(height: 20),
            const Text("Carregando sistema...",
                style: TextStyle(color: Colors.grey, fontSize: 10))
          ],
        ),
      ),
    );
  }
}
