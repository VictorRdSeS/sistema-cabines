import 'package:flutter/material.dart';

class RecepcaoDashboardScreen extends StatelessWidget {
  const RecepcaoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel da Recepção')),
      body: const Center(child: Text('Bem-vindo à recepção!')),
    );
  }
}
