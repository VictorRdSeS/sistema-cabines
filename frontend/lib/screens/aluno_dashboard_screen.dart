import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class AlunoDashboardScreen extends StatefulWidget {
  const AlunoDashboardScreen({super.key});

  @override
  State<AlunoDashboardScreen> createState() => _AlunoDashboardScreenState();
}

class _AlunoDashboardScreenState extends State<AlunoDashboardScreen> {
  List metas = [];
  bool carregando = true;
  String? erro;
  String? vencimento;

  final tituloController = TextEditingController();

  // Pomodoro
  int tempoRestante = 25 * 60;
  Timer? timer;
  bool emExecucao = false;

  void iniciarPomodoro() {
    setState(() => emExecucao = true);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (tempoRestante > 0) {
          tempoRestante--;
        } else {
          t.cancel();
          emExecucao = false;
        }
      });
    });
  }

  void pararPomodoro() {
    timer?.cancel();
    setState(() => emExecucao = false);
  }

  void resetarPomodoro() {
    timer?.cancel();
    setState(() {
      tempoRestante = 25 * 60;
      emExecucao = false;
    });
  }

  String formatarTempo(int segundos) {
    final min = (segundos ~/ 60).toString().padLeft(2, '0');
    final seg = (segundos % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

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

      final userInfo = await http.get(
        Uri.parse('http://localhost:3001/usuarios/alunos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          metas = jsonDecode(response.body);
        });
      }

      if (userInfo.statusCode == 200) {
        final usuarioLogado = jsonDecode(
          userInfo.body,
        ).firstWhere((e) => e['role'] == 'ALUNO');
        final data = DateTime.tryParse(usuarioLogado['vencimento'] ?? '');
        if (data != null) {
          vencimento =
              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
        }
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

  Future<void> criarMeta() async {
    final titulo = tituloController.text.trim();
    if (titulo.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3001/metas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'titulo': titulo,
          'data': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 201) {
        tituloController.clear();
        Navigator.of(context).pop();
        carregarMetas();
      } else {
        setState(() => erro = 'Erro ao criar meta.');
      }
    } catch (e) {
      setState(() => erro = 'Erro de conexão.');
    }
  }

  void abrirDialogNovaMeta() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nova Meta'),
            content: TextField(
              controller: tituloController,
              decoration: const InputDecoration(labelText: 'Título da Meta'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(onPressed: criarMeta, child: const Text('Salvar')),
            ],
          ),
    );
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
      appBar: AppBar(
        title: const Text('Painel do Aluno'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Nova Meta',
            onPressed: abrirDialogNovaMeta,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            carregando
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vencimento != null) ...[
                      Text(
                        '🗓️ Seu vencimento: $vencimento',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Pomodoro de Estudo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formatarTempo(tempoRestante),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: emExecucao ? null : iniciarPomodoro,
                                child: const Text('Iniciar'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: emExecucao ? pararPomodoro : null,
                                child: const Text('Parar'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: resetarPomodoro,
                                child: const Text('Resetar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
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
                                child: Text('Crie sua primeira Meta!'),
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
