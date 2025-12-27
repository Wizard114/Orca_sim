import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pages/splash_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pt_BR', null);

  runApp(const OrcaSimApp());
}

class OrcaSimApp extends StatelessWidget {
  const OrcaSimApp({super.key});

  void _carregarTemaUsuario(User? user) async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('tema_app')) {
        bool isDark = doc.data()!['tema_app'] == 'Escuro';
        themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _carregarTemaUsuario(FirebaseAuth.instance.currentUser);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Orça Sim',
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange, primary: Colors.orange[800]),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
                backgroundColor: Colors.orange[800],
                foregroundColor: Colors.white,
                centerTitle: true),
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
                elevation: 0),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black),
          ),
          home: const SplashPage(),
        );
      },
    );
  }
}
