import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _lembrarDeMim = true;

  // Removido: _titulo (não estava sendo usado)
  String get _botaoTexto => _isLogin ? "ACESSAR SISTEMA" : "CADASTRAR";
  String get _alternarTexto =>
      _isLogin ? "Ainda não tem conta? Crie aqui" : "Já tem conta? Entre aqui";

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    String? erro = await AuthService().signInWithGoogle();
    setState(() => _isLoading = false);

    if (erro != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(erro), backgroundColor: Colors.redAccent));
      }
    } else {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false);
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha email e senha!")));
      return;
    }

    setState(() => _isLoading = true);

    String? erro;
    if (_isLogin) {
      erro = await AuthService().login(email, senha);
    } else {
      erro = await AuthService().registrar(email, senha);
    }

    setState(() => _isLoading = false);

    if (erro != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(erro), backgroundColor: Colors.redAccent));
      }
    } else {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(primary: Colors.orangeAccent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          prefixIconColor: Colors.grey[400],
          labelStyle: const TextStyle(color: Colors.grey),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
      child: Builder(builder: (context) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    height: 120,
                    width: 120,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black, blurRadius: 20)
                        ]),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 15),
                  const Text("Gestão simples para profissionais",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 35),
                  TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined)),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 15),
                  TextField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline)),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _lembrarDeMim,
                          activeColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _lembrarDeMim = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("Lembrar de mim",
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_botaoTexto,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey[800])),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OU",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12))),
                    Expanded(child: Divider(color: Colors.grey[800]))
                  ]),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.asset('assets/google_icon.png', height: 24),
                      label: const Text("Entrar com Google",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_alternarTexto,
                          style: const TextStyle(color: Colors.orangeAccent))),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
