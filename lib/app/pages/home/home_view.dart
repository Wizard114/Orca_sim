import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orca_sim/app/pages/budget/new_budget_view.dart';
import 'package:orca_sim/app/pages/company/company_view.dart';
import 'package:orca_sim/app/pages/home/home_controller.dart';
import 'package:orca_sim/app/pages/pdf_preview/pdf_preview_view.dart';
import 'package:orca_sim/app/pages/products/products_view.dart';
import 'package:orca_sim/app/pages/report/report_view.dart';
import 'package:orca_sim/app/pages/splash/splash_view.dart';
import 'package:orca_sim/injection.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController _controller = getIt<HomeController>();

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    await _controller.carregarConfigs();
    if (mounted) {
      _controller.notificarUi();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmarExclusao(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Orcamento?'),
        content: const Text('Essa acao nao pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await _controller.deletarOrcamento(docId);
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer({
    required bool isDark,
    required Color colorOrange,
    required Color colorGreen,
    required Color colorTextPrimary,
  }) {
    final user = _controller.currentUser;
    final logoPath = _controller.logoPath;
    final hasLogoFile = _controller.possuiArquivoLogo();
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _controller.nomeEmpresa,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              user?.email ?? 'Usuario',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: isDark ? Colors.orangeAccent : Colors.white,
              backgroundImage: hasLogoFile && logoPath != null
                  ? FileImage(File(logoPath))
                  : null,
              child: !hasLogoFile
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/logo.png'),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.orange[800],
            ),
          ),
          ListTile(
            leading: Icon(Icons.business, color: colorOrange),
            title: Text(
              'Minha Empresa',
              style: TextStyle(color: colorTextPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompanyView()),
              ).then((_) => _loadConfigs());
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics_outlined, color: colorGreen),
            title: Text(
              'Relatorios Financeiros',
              style: TextStyle(color: colorTextPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportView()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory_2_outlined, color: colorOrange),
            title: Text(
              'Meus Produtos',
              style: TextStyle(color: colorTextPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductsView()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Sair do App',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _controller.sair();
              if (!mounted) {
                return;
              }
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SplashView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResumoHeader({
    required bool isDark,
    required Color colorCard,
    required Color colorTextSecondary,
    required Color colorGreen,
    required NumberFormat formatadorMoeda,
    required double faturamentoMesAtual,
    required int qtdAprovados,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Faturamento (Ciclo Atual)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _controller.valoresVisiveis
              ? Text(
                  formatadorMoeda.format(faturamentoMesAtual),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: colorGreen,
                  ),
                )
              : Container(
                  height: 36,
                  width: 180,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorGreen.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$qtdAprovados orcamentos este mes',
              style: TextStyle(fontSize: 12, color: colorGreen),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirAcoesOrcamento({
    required bool isDark,
    required Color colorCard,
    required Color colorOrange,
    required Color colorTextPrimary,
    required String docId,
    required String cliente,
    required Map<String, dynamic> orcamento,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorCard,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: Icon(
              Icons.check_circle,
              color: isDark ? Colors.greenAccent : Colors.green,
            ),
            title: Text(
              'Aprovar',
              style: TextStyle(color: colorTextPrimary),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _controller.atualizarStatusOrcamento(docId, 'Aprovado');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.redAccent),
            title: Text(
              'Recusar',
              style: TextStyle(color: colorTextPrimary),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _controller.atualizarStatusOrcamento(docId, 'Recusado');
            },
          ),
          ListTile(
            leading: Icon(Icons.share, color: colorOrange),
            title: Text(
              'Visualizar/Compartilhar PDF',
              style: TextStyle(color: colorTextPrimary),
            ),
            onTap: () async {
              Navigator.pop(context);
              final bytes = await _controller.gerarPdfOrcamento(
                cliente: cliente,
                orcamento: orcamento,
              );

              if (!mounted) {
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfPreviewView(
                    pdfBytes: bytes,
                    nomeArquivo: 'Orcamento_$cliente.pdf',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.grey),
            title: Text(
              'Editar',
              style: TextStyle(color: colorTextPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewBudgetView(
                    orcamentoId: docId,
                    dadosExistentes: orcamento,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmarExclusao(docId),
          ),
        ],
      ),
    );
  }

  Widget _buildOrcamentoItem({
    required bool isDark,
    required Color colorCard,
    required Color colorOrange,
    required Color colorTextPrimary,
    required Color colorTextSecondary,
    required NumberFormat formatadorMoeda,
    required DateFormat formatadorData,
    required QueryDocumentSnapshot<Object?> doc,
  }) {
    final orcamento = doc.data() as Map<String, dynamic>;
    final status = orcamento['status'] ?? 'Pendente';
    final statusInfo = _controller.getStatusInfo(
      status: status,
      colorGreen: isDark ? Colors.greenAccent : Colors.green[800]!,
      colorOrange: isDark ? Colors.orangeAccent : Colors.orange[800]!,
    );
    final cliente = orcamento['cliente_nome'] ?? 'Desconhecido';
    final total = (orcamento['total'] ?? 0.0).toDouble();
    final dataTs = orcamento['data'];
    final dataStr =
        dataTs is Timestamp ? formatadorData.format(dataTs.toDate()) : '-';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border(
            left: BorderSide(
              color: statusInfo['color'],
              width: 6,
            ),
          ),
          color: colorCard,
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Icon(
            statusInfo['icon'],
            color: statusInfo['color'],
          ),
          title: Text(
            cliente,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorTextPrimary,
            ),
          ),
          subtitle: Text(
            dataStr,
            style: TextStyle(fontSize: 12, color: colorTextSecondary),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _controller.valoresVisiveis
                  ? Text(
                      formatadorMoeda.format(total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorTextPrimary,
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 20,
                      color: isDark ? Colors.grey[900] : Colors.grey[300],
                    ),
              const SizedBox(height: 4),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusInfo['color'],
                ),
              ),
            ],
          ),
          onTap: () => _abrirAcoesOrcamento(
            isDark: isDark,
            colorCard: colorCard,
            colorOrange: colorOrange,
            colorTextPrimary: colorTextPrimary,
            docId: doc.id,
            cliente: cliente,
            orcamento: orcamento,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color colorCard,
    required Color colorGreen,
    required Color colorOrange,
    required Color colorTextPrimary,
    required Color colorTextSecondary,
    required NumberFormat formatadorMoeda,
    required DateFormat formatadorData,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.streamOrcamentos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Nenhum orcamento.',
              style: TextStyle(color: colorTextSecondary),
            ),
          );
        }

        final documentos = snapshot.data!.docs;
        final (faturamentoMesAtual, qtdAprovados) =
            _controller.calcularResumoCiclo(documentos);

        return Column(
          children: [
            _buildResumoHeader(
              isDark: isDark,
              colorCard: colorCard,
              colorTextSecondary: colorTextSecondary,
              colorGreen: colorGreen,
              formatadorMoeda: formatadorMoeda,
              faturamentoMesAtual: faturamentoMesAtual,
              qtdAprovados: qtdAprovados,
            ),
            Expanded(
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: documentos.length,
                padding: const EdgeInsets.all(15),
                itemBuilder: (context, index) => _buildOrcamentoItem(
                  isDark: isDark,
                  colorCard: colorCard,
                  colorOrange: colorOrange,
                  colorTextPrimary: colorTextPrimary,
                  colorTextSecondary: colorTextSecondary,
                  formatadorMoeda: formatadorMoeda,
                  formatadorData: formatadorData,
                  doc: documentos[index],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _controller.uiTick,
      builder: (context, _, __) {
        final formatadorMoeda =
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final formatadorData = DateFormat('dd/MM/yyyy');

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorTextSecondary =
            isDark ? Colors.grey[400]! : Colors.grey[800]!;
        final colorTextPrimary = isDark ? Colors.white : Colors.black87;
        final colorGreen = isDark ? Colors.greenAccent : Colors.green[800]!;
        final colorOrange = isDark ? Colors.orangeAccent : Colors.orange[800]!;
        final colorCard = isDark ? Theme.of(context).cardColor : Colors.white;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Meus Orcamentos',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _controller.valoresVisiveis
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  _controller.toggleValoresVisiveis();
                  _controller.notificarUi();
                },
              ),
            ],
          ),
          drawer: _buildDrawer(
            isDark: isDark,
            colorOrange: colorOrange,
            colorGreen: colorGreen,
            colorTextPrimary: colorTextPrimary,
          ),
          body: _buildBody(
            isDark: isDark,
            colorCard: colorCard,
            colorGreen: colorGreen,
            colorOrange: colorOrange,
            colorTextPrimary: colorTextPrimary,
            colorTextSecondary: colorTextSecondary,
            formatadorMoeda: formatadorMoeda,
            formatadorData: formatadorData,
          ),
          floatingActionButton: SizedBox(
            height: 70,
            width: 70,
            child: FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewBudgetView()),
              ),
              backgroundColor:
                  isDark ? Colors.orangeAccent : Colors.orange[800],
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 10,
              child: const Icon(Icons.add, size: 35),
            ),
          ),
        );
      },
    );
  }
}
