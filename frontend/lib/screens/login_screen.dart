import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  bool loading = false;
  String? erro;

  Future<void> realizarLogin() async {
    setState(() {
      loading = true;
      erro = null;
    });

    final response = await http.post(
      Uri.parse('http://localhost:3001/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text.trim(),
        'senha': senhaController.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final role = data['usuario']['role'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      if (role == 'ALUNO') {
        Navigator.pushReplacementNamed(context, '/dashboard/aluno');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard/recepcao');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Sistema de Cabines', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 16),
              if (erro != null) ...[
                Text(erro!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: loading ? null : realizarLogin,
                child:
                    loading
                        ? const CircularProgressIndicator()
                        : const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
