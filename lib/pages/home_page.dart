import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import 'cadastro_empresa_page.dart';
import 'novo_orcamento_page.dart';
import 'relatorio_page.dart';
import 'splash_page.dart';
import 'pdf_preview_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _valoresVisiveis = true;
  int _diaFechamento = 1;
  String? _logoPath;
  String _nomeEmpresa = "Minha Empresa";

  @override
  void initState() {
    super.initState();
    _carregarConfigs();
  }

  void _carregarConfigs() async {
    final dados = await FirestoreService().pegarDadosEmpresa();
    if (dados != null && mounted) {
      setState(() {
        _diaFechamento = dados['dia_fechamento'] ?? 1;
        _logoPath = dados['logo_local_path'];
        _nomeEmpresa = (dados['nome_empresa'] != null &&
                dados['nome_empresa'].toString().isNotEmpty)
            ? dados['nome_empresa']
            : "Minha Empresa";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorData = DateFormat('dd/MM/yyyy');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTextSecondary = isDark ? Colors.grey[400] : Colors.grey[800];
    final colorTextPrimary = isDark ? Colors.white : Colors.black87;
    final colorGreen = isDark ? Colors.greenAccent : Colors.green[800]!;
    final colorOrange = isDark ? Colors.orangeAccent : Colors.orange[800]!;
    final colorCard = isDark ? Theme.of(context).cardColor : Colors.white;

    List<ItemOrcamento> converterItens(List<dynamic> listaDoBanco) {
      return listaDoBanco.map((itemJson) {
        return ItemOrcamento(
          descricao: itemJson['descricao'] ?? '',
          quantidade: itemJson['quantidade'] ?? 1,
          unidade: itemJson['unidade'] ?? 'un',
          valorUnitario: (itemJson['valor'] ?? 0.0).toDouble(),
        );
      }).toList();
    }

    void confirmarExclusao(String docId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Excluir Orçamento?"),
          content: const Text("Essa ação não pode ser desfeita."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar")),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pop(context);
                await FirestoreService().deletarOrcamento(docId);
              },
              child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    Map<String, dynamic> getStatusInfo(String status) {
      switch (status) {
        case 'Aprovado':
          return {'color': colorGreen, 'icon': Icons.check_circle};
        case 'Recusado':
          return {'color': Colors.redAccent, 'icon': Icons.cancel};
        default:
          return {'color': colorOrange, 'icon': Icons.access_time_filled};
      }
    }

    return Scaffold(
      appBar: AppBar(
        // MUDANÇA AQUI: Texto mais curto e fonte ajustada
        title: const Text("Meus Orçamentos",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
                _valoresVisiveis ? Icons.visibility : Icons.visibility_off),
            onPressed: () =>
                setState(() => _valoresVisiveis = !_valoresVisiveis),
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_nomeEmpresa,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? "Usuario",
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: isDark ? Colors.orangeAccent : Colors.white,
                backgroundImage:
                    _logoPath != null ? FileImage(File(_logoPath!)) : null,
                child: _logoPath == null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset('assets/logo.png'))
                    : null,
              ),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.orange[800]),
            ),
            ListTile(
              leading: Icon(Icons.business, color: colorOrange),
              title: Text("Minha Empresa",
                  style: TextStyle(color: colorTextPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CadastroEmpresaPage()))
                    .then((_) => _carregarConfigs());
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics_outlined, color: colorGreen),
              title: Text("Relatórios Financeiros",
                  style: TextStyle(color: colorTextPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RelatorioPage()));
              },
            ),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider()),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Sair do App",
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().sair();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SplashPage()),
                      (Route<dynamic> route) => false);
                }
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().streamOrcamentos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text("Nenhum orçamento.",
                    style: TextStyle(color: colorTextSecondary)));
          }

          final documentos = snapshot.data!.docs;

          double faturamentoMesAtual = 0.0;
          int qtdAprovados = 0;

          DateTime hoje = DateTime.now();
          DateTime inicioCiclo;
          if (hoje.day >= _diaFechamento) {
            inicioCiclo = DateTime(hoje.year, hoje.month, _diaFechamento);
          } else {
            inicioCiclo = DateTime(hoje.year, hoje.month - 1, _diaFechamento);
          }
          DateTime fimCiclo =
              DateTime(inicioCiclo.year, inicioCiclo.month + 1, _diaFechamento);

          for (var doc in documentos) {
            final dados = doc.data() as Map<String, dynamic>;
            Timestamp? dataTs = dados['data'];

            if (dados['status'] == 'Aprovado' && dataTs != null) {
              DateTime dataOrc = dataTs.toDate();
              if (dataOrc.isAfter(
                      inicioCiclo.subtract(const Duration(seconds: 1))) &&
                  dataOrc.isBefore(fimCiclo)) {
                faturamentoMesAtual += (dados['total'] ?? 0.0).toDouble();
                qtdAprovados++;
              }
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: colorCard,
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ]),
                child: Column(
                  children: [
                    Text("Faturamento (Ciclo Atual)",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorTextSecondary)),
                    const SizedBox(height: 10),
                    _valoresVisiveis
                        ? Text(formatadorMoeda.format(faturamentoMesAtual),
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: colorGreen))
                        : Container(
                            height: 36,
                            width: 180,
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: colorGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: colorGreen.withOpacity(0.3))),
                      child: Text("$qtdAprovados orçamentos este mês",
                          style: TextStyle(fontSize: 12, color: colorGreen)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: documentos.length,
                  padding: const EdgeInsets.all(15),
                  itemBuilder: (context, index) {
                    final doc = documentos[index];
                    final orcamento = doc.data() as Map<String, dynamic>;
                    String status = orcamento['status'] ?? 'Pendente';
                    final statusInfo = getStatusInfo(status);
                    String cliente =
                        orcamento['cliente_nome'] ?? 'Desconhecido';
                    double total = (orcamento['total'] ?? 0.0).toDouble();
                    Timestamp? dataTs = orcamento['data'];
                    String dataStr = dataTs != null
                        ? formatadorData.format(dataTs.toDate())
                        : '-';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border(
                              left: BorderSide(
                                  color: statusInfo['color'], width: 6)),
                          color: colorCard,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(statusInfo['icon'],
                                    color: statusInfo['color'])
                              ]),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(cliente,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorTextPrimary)),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 12, color: colorTextSecondary),
                                const SizedBox(width: 4),
                                Text(dataStr,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colorTextSecondary)),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _valoresVisiveis
                                  ? Text(formatadorMoeda.format(total),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: colorTextPrimary))
                                  : Container(
                                      width: 80,
                                      height: 20,
                                      color: isDark
                                          ? Colors.grey[900]
                                          : Colors.grey[300]),
                              const SizedBox(height: 4),
                              Text(status.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusInfo['color'])),
                            ],
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: colorCard,
                              builder: (BuildContext bc) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Wrap(
                                    children: <Widget>[
                                      Center(
                                          child: Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 15),
                                              child: Text("Gerenciar Orçamento",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          colorTextPrimary)))),
                                      ListTile(
                                        leading: Icon(Icons.check_circle,
                                            color: isDark
                                                ? Colors.greenAccent
                                                : Colors.green),
                                        title: Text('Aprovar',
                                            style: TextStyle(
                                                color: colorTextPrimary)),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await FirestoreService()
                                              .atualizarStatusOrcamento(
                                                  doc.id, 'Aprovado');
                                          setState(() {});
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.cancel,
                                            color: Colors.redAccent),
                                        title: Text('Recusar',
                                            style: TextStyle(
                                                color: colorTextPrimary)),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await FirestoreService()
                                              .atualizarStatusOrcamento(
                                                  doc.id, 'Recusado');
                                          setState(() {});
                                        },
                                      ),
                                      const Divider(),
                                      ListTile(
                                        leading: Icon(Icons.share,
                                            color: colorOrange),
                                        title: Text(
                                            'Visualizar/Compartilhar PDF',
                                            style: TextStyle(
                                                color: colorTextPrimary)),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text("Gerando...")));

                                          List<ItemOrcamento> listaItens =
                                              converterItens(
                                                  orcamento['itens'] ?? []);

                                          final bytes = await PdfService()
                                              .gerarPdfOrcamentoBytes(
                                            clienteNome: cliente,
                                            clienteCpfCnpj:
                                                orcamento['cliente_cpf_cnpj'] ??
                                                    '',
                                            nomeObra:
                                                orcamento['nome_obra'] ?? '',
                                            observacoes:
                                                orcamento['observacoes'] ?? '',
                                            itens: listaItens,
                                          );

                                          if (mounted) {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        PdfPreviewPage(
                                                            pdfBytes: bytes,
                                                            nomeArquivo:
                                                                "Orcamento_${cliente}.pdf")));
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.edit,
                                            color: Colors.grey),
                                        title: Text('Editar',
                                            style: TextStyle(
                                                color: colorTextPrimary)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      NovoOrcamentoPage(
                                                          orcamentoId: doc.id,
                                                          dadosExistentes:
                                                              orcamento)));
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red),
                                        title: const Text('Excluir',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onTap: () => confirmarExclusao(doc.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NovoOrcamentoPage())),
          backgroundColor: isDark ? Colors.orangeAccent : Colors.orange[800],
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 10,
          child: const Icon(Icons.add, size: 35),
        ),
      ),
    );
  }
}
