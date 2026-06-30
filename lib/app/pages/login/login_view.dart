import 'package:flutter/material.dart';
import 'package:orca_sim/app/pages/home/home_view.dart';
import 'package:orca_sim/app/pages/login/login_controller.dart';
import 'package:orca_sim/data/services/auth_service.dart';
import 'package:orca_sim/injection.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = getIt<LoginController>();

  Future<void> _handleGoogleSignIn() async {
    final erro = await _controller.signInWithGoogle();

    if (!mounted) {
      return;
    }

    if (erro == AuthService.googleSignInCancelled) {
      return;
    }

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.redAccent),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeView()),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    final email = _controller.emailController.text.trim();
    final senha = _controller.senhaController.text.trim();

    if (!_controller.credenciaisPreenchidas(email: email, senha: senha)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha email e senha!')),
      );
      return;
    }

    final erro = await _controller.submit(email: email, senha: senha);

    if (!mounted) {
      return;
    }

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.redAccent),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeView()),
      (route) => false,
    );
  }

  Future<void> _recuperarSenha() async {
    final email = _controller.emailController.text.trim();
    if (!_controller.emailPreenchido(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe seu e-mail para recuperar a senha.'),
        ),
      );
      return;
    }

    final erro = await _controller.recuperarSenha(email);
    if (!mounted) {
      return;
    }

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.redAccent),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('E-mail de recuperacao enviado com sucesso.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    return Container(
      height: 120,
      width: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(blurRadius: 20),
        ],
      ),
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    );
  }

  Widget _buildCamposCredenciais() {
    return Column(
      children: [
        TextField(
          controller: _controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _controller.senhaController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLembrarDeMim() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: ValueListenableBuilder<bool>(
            valueListenable: _controller.lembrarDeMim,
            builder: (context, lembrarDeMim, _) => Checkbox(
              value: lembrarDeMim,
              activeColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (v) {
                _controller.setLembrarDeMim(v ?? true);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Lembrar de mim',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRecuperarSenha() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _recuperarSenha,
        child: const Text(
          'Esqueci minha senha',
          style: TextStyle(color: Colors.orangeAccent),
        ),
      ),
    );
  }

  Widget _buildBotaoPrincipal() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, _) => ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: _controller.isLogin,
                  builder: (context, _, __) => Text(
                    _controller.botaoTexto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivisorOu() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[800])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OU',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildBotaoGoogle() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, _) => ElevatedButton.icon(
          onPressed: isLoading ? null : _handleGoogleSignIn,
          icon: Image.asset('assets/google_icon.png', height: 24),
          label: const Text(
            'Entrar com Google',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildAlternarModo() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isLogin,
      builder: (context, _, __) => TextButton(
        onPressed: _controller.alternarModo,
        child: Text(
          _controller.alternarTexto,
          style: const TextStyle(color: Colors.orangeAccent),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 15),
            const Text(
              'Gestao simples para profissionais',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 35),
            _buildCamposCredenciais(),
            const SizedBox(height: 10),
            _buildLembrarDeMim(),
            _buildRecuperarSenha(),
            const SizedBox(height: 25),
            _buildBotaoPrincipal(),
            const SizedBox(height: 15),
            _buildDivisorOu(),
            const SizedBox(height: 15),
            _buildBotaoGoogle(),
            const SizedBox(height: 25),
            _buildAlternarModo(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
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
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Colors.grey[400],
          labelStyle: const TextStyle(color: Colors.grey),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: _buildBody(),
          );
        },
      ),
    );
  }
}
