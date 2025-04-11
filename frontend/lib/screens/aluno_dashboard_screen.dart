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
  bool exibirConcluidas = false;
  String? token;

  final tituloController = TextEditingController();
  int? metaEditandoId;

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
      token = prefs.getString('token');

      final usuarioDecoded = parseJwt(token!);
      final venc = usuarioDecoded['vencimento'];
      if (venc != null) {
        final data = DateTime.tryParse(venc);
        if (data != null) {
          vencimento =
              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
        }
      }

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
      }
    } catch (e) {
      setState(() => erro = 'Erro de conexão.');
    } finally {
      setState(() => carregando = false);
    }
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded);
  }

  Future<void> concluirMeta(int id) async {
    try {
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

  Future<void> excluirMeta(int id) async {
    try {
      await http.delete(
        Uri.parse('http://localhost:3001/metas/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await carregarMetas();
    } catch (_) {
      setState(() => erro = 'Erro ao excluir meta.');
    }
  }

  Future<void> salvarMeta() async {
    final titulo = tituloController.text.trim();
    if (titulo.isEmpty) return;

    final url =
        metaEditandoId != null
            ? 'http://localhost:3001/metas/$metaEditandoId'
            : 'http://localhost:3001/metas';
    final method = metaEditandoId != null ? 'PATCH' : 'POST';

    try {
      final response =
          await (method == 'POST'
              ? http.post(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'titulo': titulo,
                  'data': DateTime.now().toIso8601String().split('T')[0],
                }),
              )
              : http.patch(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({'titulo': titulo}),
              ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        tituloController.clear();
        metaEditandoId = null;
        Navigator.of(context).pop();
        carregarMetas();
      } else {
        setState(() => erro = 'Erro ao salvar meta.');
      }
    } catch (e) {
      setState(() => erro = 'Erro de conexão.');
    }
  }

  void abrirDialogMeta({Map? meta}) {
    if (meta != null) {
      metaEditandoId = meta['id'];
      tituloController.text = meta['titulo'];
    } else {
      metaEditandoId = null;
      tituloController.clear();
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(metaEditandoId != null ? 'Editar Meta' : 'Nova Meta'),
            content: TextField(
              controller: tituloController,
              decoration: const InputDecoration(labelText: 'Título da Meta'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: salvarMeta,
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (context.mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  void initState() {
    super.initState();
    carregarMetas();
  }

  @override
  Widget build(BuildContext context) {
    final metasFiltradas =
        metas.where((m) => m['concluida'] == exibirConcluidas).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Painel do Aluno'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Sair',
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
                    if (vencimento != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '🗓️ Vencimento: $vencimento',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                    // Pomodoro
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
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
                        children: [
                          const Text(
                            'Pomodoro de Estudo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatarTempo(tempoRestante),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: emExecucao ? null : iniciarPomodoro,
                                child: const Text('Iniciar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: emExecucao ? pararPomodoro : null,
                                child: const Text('Parar'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: resetarPomodoro,
                                child: const Text('Resetar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Metas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Minhas Metas de Hoje',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => abrirDialogMeta(),
                          icon: const Icon(Icons.add),
                          label: const Text('Nova Meta'),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Pendentes'),
                          selected: !exibirConcluidas,
                          onSelected:
                              (_) => setState(() => exibirConcluidas = false),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Concluídas'),
                          selected: exibirConcluidas,
                          onSelected:
                              (_) => setState(() => exibirConcluidas = true),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Expanded(
                      child:
                          metasFiltradas.isEmpty
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
                                        metasFiltradas.map<DataRow>((meta) {
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
                                                Row(
                                                  children: [
                                                    if (!meta['concluida'])
                                                      IconButton(
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
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.amber,
                                                      ),
                                                      onPressed:
                                                          () => abrirDialogMeta(
                                                            meta: meta,
                                                          ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed:
                                                          () => excluirMeta(
                                                            meta['id'],
                                                          ),
                                                    ),
                                                  ],
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
