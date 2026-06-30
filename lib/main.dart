import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orca_sim/app/pages/splash/splash_view.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';
import 'package:orca_sim/injection.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pt_BR');
  inject();

  runApp(const OrcaSimApp());
}

class OrcaSimApp extends StatefulWidget {
  const OrcaSimApp({super.key});

  @override
  State<OrcaSimApp> createState() => _OrcaSimAppState();
}

class _OrcaSimAppState extends State<OrcaSimApp> {
  StreamSubscription<User?>? _authSubscription;
  String? _temaCarregadoUid;

  @override
  void initState() {
    super.initState();
    _onAuthChanged(FirebaseAuth.instance.currentUser);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
          _onAuthChanged,
        );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  ThemeMode _themeModeFromTemaApp(String? tema) {
    switch (tema) {
      case 'Escuro':
        return ThemeMode.dark;
      case 'Claro':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _temaCarregadoUid = null;
      themeNotifier.value = ThemeMode.system;
      return;
    }

    if (_temaCarregadoUid == user.uid) {
      return;
    }

    _temaCarregadoUid = user.uid;
    final dados = await getIt<IFirestoreService>().pegarDadosEmpresa();
    if (!mounted || _temaCarregadoUid != user.uid) {
      return;
    }

    if (dados != null && dados.containsKey('tema_app')) {
      themeNotifier.value =
          _themeModeFromTemaApp(dados['tema_app']?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Orça Sim',
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              primary: Colors.orange[800],
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF000000),
            cardColor: const Color(0xFF1C1C1E),
            colorScheme: const ColorScheme.dark(
              primary: Colors.orangeAccent,
              secondary: Colors.greenAccent,
              surface: Color(0xFF1C1C1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1C1C1E),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
          ),
          home: const SplashView(),
        );
      },
    );
  }
}
