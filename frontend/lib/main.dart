import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/aluno_dashboard_screen.dart';
import 'screens/recepcao_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Cabines',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard/aluno': (context) => const AlunoDashboardScreen(),
        '/dashboard/recepcao': (context) => const RecepcaoDashboardScreen(),
      },
    );
  }
}
