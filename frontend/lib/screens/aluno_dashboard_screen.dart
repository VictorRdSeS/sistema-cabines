import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

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
  bool modoEscuro = true;

  final tituloController = TextEditingController();
  int? metaEditandoId;

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
          vencimento = DateFormat('dd/MM/yyyy').format(data);
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
    final isDark = modoEscuro;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDark ? Colors.black : Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Painel do Aluno'),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => modoEscuro = !modoEscuro),
            ),
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
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (vencimento != null)
                          Text(
                            '🗓️ Seu vencimento: $vencimento',
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.white,
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
                                    onPressed:
                                        emExecucao ? null : iniciarPomodoro,
                                    child: const Text('Iniciar'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed:
                                        emExecucao ? pararPomodoro : null,
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
                              onPressed: () => {},
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
                                  (_) =>
                                      setState(() => exibirConcluidas = false),
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text('Concluídas'),
                              selected: exibirConcluidas,
                              onSelected:
                                  (_) =>
                                      setState(() => exibirConcluidas = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        metasFiltradas.isEmpty
                            ? const Center(
                              child: Text('Nenhuma meta encontrada.'),
                            )
                            : Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
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
                                scrollDirection: Axis.horizontal,
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
                                                      onPressed: () {},
                                                    ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.amber,
                                                    ),
                                                    onPressed: () {},
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {},
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
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
