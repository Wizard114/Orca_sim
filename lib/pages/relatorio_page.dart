import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_page.dart'; // Importe para visualizar

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  int _diaFechamento = 1;
  DateTime _mesSelecionado = DateTime.now();
  bool _carregando = true;
  List<Map<String, dynamic>> _listaOrcamentos = [];
  double _totalFaturado = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarConfigEBuscar();
  }

  Future<void> _carregarConfigEBuscar() async {
    final dados = await FirestoreService().pegarDadosEmpresa();
    if (dados != null) {
      _diaFechamento = dados['dia_fechamento'] ?? 1;
    }
    DateTime hoje = DateTime.now();
    _mesSelecionado = DateTime(hoje.year, hoje.month, 1);
    await _buscarDadosDoMes();
  }

  (DateTime, DateTime) _calcularDatasCiclo(
      DateTime mesReferencia, int diaFechamento) {
    DateTime dataInicio =
        DateTime(mesReferencia.year, mesReferencia.month, diaFechamento);
    DateTime dataFim =
        DateTime(mesReferencia.year, mesReferencia.month + 1, diaFechamento)
            .subtract(const Duration(seconds: 1));
    return (dataInicio, dataFim);
  }

  Future<void> _buscarDadosDoMes() async {
    setState(() => _carregando = true);
    final (dataInicio, dataFim) =
        _calcularDatasCiclo(_mesSelecionado, _diaFechamento);
    List<Map<String, dynamic>> resultados =
        await FirestoreService().pegarOrcamentosPorPeriodo(dataInicio, dataFim);

    double total = 0;
    for (var item in resultados) {
      total += (item['total'] ?? 0.0);
    }

    setState(() {
      _listaOrcamentos = resultados;
      _totalFaturado = total;
      _carregando = false;
    });
  }

  List<DateTime> _gerarUltimos6Meses() {
    List<DateTime> lista = [];
    DateTime hoje = DateTime.now();
    for (int i = 0; i < 6; i++) {
      lista.add(DateTime(hoje.year, hoje.month - i, 1));
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorDataCurta = DateFormat('dd/MM');
    final formatadorDataCompleta = DateFormat('dd/MM/yyyy');
    final formatadorMesAno = DateFormat('MMMM yyyy', 'pt_BR');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorTextPrimary = isDark ? Colors.white : Colors.black87;
    final colorTextSecondary = isDark ? Colors.grey[400] : Colors.grey[700];
    final colorGreen = isDark ? Colors.greenAccent : Colors.green[800]!;

    final (inicioCicloAtual, fimCicloAtual) =
        _calcularDatasCiclo(_mesSelecionado, _diaFechamento);
    String textoCiclo =
        "Ciclo: ${formatadorDataCurta.format(inicioCicloAtual)} até ${formatadorDataCurta.format(fimCicloAtual)}";
    String nomeMesRef = formatadorMesAno.format(_mesSelecionado).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text("Relatórios Financeiros")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selecione o Mês de Referência:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorTextSecondary,
                        fontSize: 12)),
                DropdownButton<DateTime>(
                  value: _mesSelecionado,
                  isExpanded: true,
                  underline: Container(height: 1, color: colorGreen),
                  items: _gerarUltimos6Meses().map((dataRef) {
                    final (ini, fim) =
                        _calcularDatasCiclo(dataRef, _diaFechamento);
                    String nomeMes =
                        formatadorMesAno.format(dataRef).toUpperCase();
                    String ciclo =
                        "(${formatadorDataCurta.format(ini)} a ${formatadorDataCurta.format(fim)})";
                    return DropdownMenuItem(
                      value: dataRef,
                      child: Text("$nomeMes $ciclo",
                          style: TextStyle(
                              color: colorTextPrimary,
                              fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (novoMes) {
                    if (novoMes != null) {
                      setState(() => _mesSelecionado = novoMes);
                      _buscarDadosDoMes();
                    }
                  },
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: isDark ? Colors.black26 : Colors.grey[200],
            child: Column(
              children: [
                Text("FATURAMENTO APROVADO",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorTextSecondary)),
                const SizedBox(height: 5),
                _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(formatadorMoeda.format(_totalFaturado),
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorGreen)),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: colorGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorGreen.withOpacity(0.3))),
                  child: Text(textoCiclo,
                      style: TextStyle(
                          fontSize: 11,
                          color: colorGreen,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _listaOrcamentos.isEmpty
                    ? Center(
                        child: Text("Nenhum orçamento aprovado neste ciclo.",
                            style: TextStyle(color: colorTextSecondary)))
                    : ListView.separated(
                        itemCount: _listaOrcamentos.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _listaOrcamentos[index];
                          Timestamp ts = item['data'];
                          return ListTile(
                            leading: Icon(Icons.check_circle,
                                color: colorGreen, size: 20),
                            title: Text(item['cliente_nome'] ?? 'Cliente',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorTextPrimary)),
                            subtitle: Text(
                                formatadorDataCompleta.format(ts.toDate()),
                                style: TextStyle(
                                    color: colorTextSecondary, fontSize: 12)),
                            trailing: Text(
                                formatadorMoeda.format(item['total']),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorTextPrimary)),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _carregando || _listaOrcamentos.isEmpty
                    ? null
                    : () async {
                        // GERA OS BYTES DO PDF
                        String nomePdf = "$nomeMesRef ($textoCiclo)";
                        final bytes =
                            await PdfService().gerarRelatorioFinanceiro(
                          mesReferencia: nomePdf,
                          orcamentos: _listaOrcamentos,
                          totalFaturado: _totalFaturado,
                        );

                        // NAVEGA PARA O PREVIEW
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfPreviewPage(
                                pdfBytes: bytes,
                                nomeArquivo: "Relatorio_$nomeMesRef.pdf",
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("VISUALIZAR RELATÓRIO PDF"), // Texto mudou
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.orangeAccent : Colors.orange[800],
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
