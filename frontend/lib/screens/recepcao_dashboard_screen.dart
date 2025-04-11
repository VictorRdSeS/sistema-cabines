import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class RecepcaoDashboardScreen extends StatefulWidget {
  const RecepcaoDashboardScreen({super.key});

  @override
  State<RecepcaoDashboardScreen> createState() =>
      _RecepcaoDashboardScreenState();
}

class _RecepcaoDashboardScreenState extends State<RecepcaoDashboardScreen>
    with SingleTickerProviderStateMixin {
  String? token;
  bool carregando = true;
  List alunos = [], cabines = [], todosAlunos = [];
  int livres = 0, ocupadas = 0;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final buscaController = TextEditingController();
  DateTime? dataSelecionada;
  int? alunoEditandoId;

  bool modoEscuro = true;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
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
          todosAlunos = listaAlunos;
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
    } finally {
      setState(() => carregando = false);
    }
  }

  void abrirDialogAluno({Map? aluno}) {
    if (aluno != null) {
      alunoEditandoId = aluno['id'];
      nomeController.text = aluno['nome'] ?? '';
      emailController.text = aluno['email'] ?? '';
      dataSelecionada = DateTime.tryParse(aluno['vencimento'] ?? '');
    } else {
      alunoEditandoId = null;
      nomeController.clear();
      emailController.clear();
      dataSelecionada = null;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(aluno != null ? 'Editar Aluno' : 'Novo Aluno'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        dataSelecionada != null
                            ? 'Vencimento: ${DateFormat('dd/MM/yyyy').format(dataSelecionada!)}'
                            : 'Selecione o vencimento',
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final selecionada = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (selecionada != null) {
                            setState(() => dataSelecionada = selecionada);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: salvarAluno,
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  Future<void> salvarAluno() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();

    if (nome.isEmpty || email.isEmpty || dataSelecionada == null) {
      Navigator.of(context).pop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(contextRoot).showSnackBar(
            const SnackBar(
              content: Text('Preencha nome, email e vencimento.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });

      return;
    }

    final body = jsonEncode({
      'nome': nome,
      'email': email,
      'vencimento': dataSelecionada!.toIso8601String(),
    });

    final url =
        alunoEditandoId != null
            ? 'http://localhost:3001/usuarios/$alunoEditandoId/vencimento'
            : 'http://localhost:3001/usuarios';

    final res =
        await (alunoEditandoId != null
            ? http.patch(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: body,
            )
            : http.post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: body,
            ));

    if (context.mounted) Navigator.pop(context);
    carregarDados();
  }

  void confirmarExclusaoAluno(int id, String nome) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text('Deseja realmente excluir o aluno "$nome"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.pop(context); // Fecha o diálogo
                  await excluirAluno(id);
                },
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
  }

  Future<void> excluirAluno(int id) async {
    final res = await http.delete(
      Uri.parse('http://localhost:3001/usuarios/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    carregarDados();

    // Aguarda o diálogo fechar antes de mostrar o SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final mensagem =
            res.statusCode == 200
                ? 'Aluno excluído com sucesso'
                : 'Erro ao excluir aluno';
        final cor = res.statusCode == 200 ? Colors.green : Colors.red;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
      }
    });
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (context.mounted) Navigator.pushReplacementNamed(context, '/');
  }

  late BuildContext contextRoot;

  @override
  Widget build(BuildContext context) {
    contextRoot = context;
    final alunosFiltrados =
        todosAlunos
            .where(
              (a) => a['nome'].toLowerCase().contains(
                buscaController.text.toLowerCase(),
              ),
            )
            .toList();
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
          title: const Text('Painel da Recepção'),
          bottom: TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Vencimento Próximo'),
              Tab(text: 'Todos os Alunos'),
            ],
          ),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => abrirDialogAluno(),
          icon: const Icon(Icons.person_add),
          label: const Text('Novo Aluno'),
        ),
        body:
            carregando
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      _tabelaAlunos(alunos, isDark),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: buscaController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Buscar aluno por nome',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _tabelaAlunos(alunosFiltrados, isDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _tabelaAlunos(List lista, bool isDark) {
    return lista.isEmpty
        ? const Center(child: Text('Nenhum aluno encontrado.'))
        : Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Vencimento')),
                DataColumn(label: Text('Ações')),
              ],
              rows:
                  lista.map<DataRow>((aluno) {
                    final venc = DateTime.tryParse(aluno['vencimento'] ?? '');
                    return DataRow(
                      cells: [
                        DataCell(Text(aluno['nome'] ?? '')),
                        DataCell(Text(aluno['email'] ?? '')),
                        DataCell(
                          Text(
                            venc != null
                                ? DateFormat('dd/MM/yyyy').format(venc)
                                : '',
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => abrirDialogAluno(aluno: aluno),
                                tooltip: 'Editar / Renovar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed:
                                    () => confirmarExclusaoAluno(
                                      aluno['id'],
                                      aluno['nome'],
                                    ),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        );
  }
}
