import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecepcaoDashboardScreen extends StatefulWidget {
  const RecepcaoDashboardScreen({super.key});

  @override
  State<RecepcaoDashboardScreen> createState() =>
      _RecepcaoDashboardScreenState();
}

class _RecepcaoDashboardScreenState extends State<RecepcaoDashboardScreen> {
  String? token;
  bool carregando = true;
  List alunos = [], cabines = [];
  int livres = 0, ocupadas = 0;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    setState(() => carregando = true);
    try {
      final aRes = await http.get(
        Uri.parse('http://localhost:3001/usuarios/alunos'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final cRes = await http.get(
        Uri.parse('http://localhost:3001/cabines'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (aRes.statusCode == 200 && cRes.statusCode == 200) {
        final listaAlunos = jsonDecode(aRes.body);
        final listaCabines = jsonDecode(cRes.body);

        final hoje = DateTime.now();
        final depois = hoje.add(const Duration(days: 3));

        setState(() {
          alunos =
              listaAlunos.where((a) {
                final venc =
                    DateTime.tryParse(a['vencimento'] ?? '') ?? DateTime(1900);
                return venc.isBefore(depois) &&
                    venc.isAfter(hoje.subtract(const Duration(days: 1)));
              }).toList();

          cabines = listaCabines;
          livres = listaCabines.where((c) => c['status'] == 'LIVRE').length;
          ocupadas = listaCabines.where((c) => c['status'] == 'OCUPADA').length;
        });
      }
    } catch (_) {
      // erro silencioso
    } finally {
      setState(() => carregando = false);
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (context.mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Painel da Recepção'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body:
          carregando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _cardResumo('Cabines Livres', livres, Colors.green),
                        _cardResumo('Cabines Ocupadas', ocupadas, Colors.red),
                        _cardResumo(
                          'Alunos com Vencimento Próximo',
                          alunos.length,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Vencimentos nos próximos 3 dias',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          alunos.isEmpty
                              ? const Center(
                                child: Text(
                                  'Nenhum aluno com vencimento próximo.',
                                ),
                              )
                              : ListView.builder(
                                itemCount: alunos.length,
                                itemBuilder: (context, index) {
                                  final aluno = alunos[index];
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.person_outline),
                                      title: Text(aluno['nome'] ?? ''),
                                      subtitle: Text(
                                        'Vence em: ${aluno['vencimento']?.toString().split('T')[0] ?? ''}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _cardResumo(String titulo, int valor, Color cor) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: cor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor.toString(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
