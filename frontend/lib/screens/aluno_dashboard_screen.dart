import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AlunoDashboardScreen extends StatefulWidget {
  const AlunoDashboardScreen({super.key});

  @override
  State<AlunoDashboardScreen> createState() => _AlunoDashboardScreenState();
}

class _AlunoDashboardScreenState extends State<AlunoDashboardScreen> {
  List metas = [];
  bool carregando = true;
  String? erro;

  Future<void> carregarMetas() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://localhost:3001/metas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          metas = jsonDecode(response.body);
        });
      } else {
        setState(() => erro = 'Erro ao carregar metas.');
      }
    } catch (e) {
      setState(() => erro = 'Erro de conexão.');
    } finally {
      setState(() => carregando = false);
    }
  }

  Future<void> concluirMeta(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      await http.patch(
        Uri.parse('http://localhost:3001/metas/$id/concluir'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      await carregarMetas();
    } catch (_) {
      setState(() => erro = 'Erro ao concluir meta.');
    }
  }

  @override
  void initState() {
    super.initState();
    carregarMetas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Painel do Aluno')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            carregando
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minhas Metas de Hoje',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (erro != null)
                      Text(erro!, style: const TextStyle(color: Colors.red)),
                    Expanded(
                      child:
                          metas.isEmpty
                              ? const Center(
                                child: Text('Nenhuma meta encontrada.'),
                              )
                              : Container(
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
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Título')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Ações')),
                                    ],
                                    rows:
                                        metas.map<DataRow>((meta) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(meta['titulo'] ?? ''),
                                              ),
                                              DataCell(
                                                Text(
                                                  meta['concluida']
                                                      ? 'Concluída'
                                                      : 'Pendente',
                                                  style: TextStyle(
                                                    color:
                                                        meta['concluida']
                                                            ? Colors.green
                                                            : Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                meta['concluida']
                                                    ? const Icon(
                                                      Icons.check,
                                                      color: Colors.grey,
                                                    )
                                                    : IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        color: Colors.blue,
                                                      ),
                                                      onPressed:
                                                          () => concluirMeta(
                                                            meta['id'],
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}
