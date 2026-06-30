import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orca_sim/app/pages/pdf_preview/pdf_preview_view.dart';
import 'package:orca_sim/app/pages/report/report_controller.dart';
import 'package:orca_sim/injection.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  final ReportController _controller = getIt<ReportController>();

  @override
  void initState() {
    super.initState();
    _controller.inicializar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildProdutosMaisUsados({
    required bool isDark,
    required Color colorGreen,
    required Color colorTextPrimary,
    required Color? colorTextSecondary,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PRODUTOS MAIS USADOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (_controller.carregando.value)
            const SizedBox(
              height: 26,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_controller.produtosMaisUsados.value.isEmpty)
            Text(
              'Nenhum produto com uso registrado.',
              style: TextStyle(color: colorTextSecondary),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controller.produtosMaisUsados.value.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final produto = _controller.produtosMaisUsados.value[index];
                final nome = _controller.nomeProduto(produto);
                final usage = _controller.usageCountProduto(produto);
                return Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        color: colorGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorTextPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$usage usos',
                      style: TextStyle(
                        color: colorGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMesSelector({
    required Color colorGreen,
    required Color colorTextPrimary,
    required DateFormat formatadorDataCurta,
    required DateFormat formatadorMesAno,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: DropdownButton<DateTime>(
        value: _controller.mesSelecionado.value,
        isExpanded: true,
        underline: Container(height: 1, color: colorGreen),
        items: _controller.gerarUltimos6Meses().map((dataRef) {
          final (ini, fim) = _controller.calcularDatasCiclo(dataRef);
          final nomeMes = _controller.textoMesAno(dataRef).toUpperCase();
          final ciclo =
              '(${formatadorDataCurta.format(ini)} a ${formatadorDataCurta.format(fim)})';
          return DropdownMenuItem(
            value: dataRef,
            child: Text(
              '$nomeMes $ciclo',
              style: TextStyle(color: colorTextPrimary),
            ),
          );
        }).toList(),
        onChanged: (novoMes) {
          if (novoMes != null) {
            _controller.selecionarMes(novoMes);
            _controller.buscarDadosDoMesSelecionado();
          }
        },
      ),
    );
  }

  Widget _buildResumo({
    required bool isDark,
    required Color colorGreen,
    required Color? colorTextSecondary,
    required NumberFormat formatadorMoeda,
    required String textoCiclo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: isDark ? Colors.black26 : Colors.grey[200],
      child: Column(
        children: [
          Text(
            'FATURAMENTO APROVADO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorTextSecondary,
            ),
          ),
          const SizedBox(height: 5),
          _controller.carregando.value
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Text(
                  formatadorMoeda.format(_controller.totalFaturado.value),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorGreen,
                  ),
                ),
          const SizedBox(height: 10),
          Text(
            textoCiclo,
            style: TextStyle(fontSize: 11, color: colorGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildListaOrcamentos({
    required Color colorGreen,
    required Color colorTextPrimary,
    required Color? colorTextSecondary,
    required NumberFormat formatadorMoeda,
    required DateFormat formatadorDataCompleta,
  }) {
    if (_controller.carregando.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.listaOrcamentos.value.isEmpty) {
      return Center(
        child: Text(
          'Nenhum orcamento aprovado neste ciclo.',
          style: TextStyle(color: colorTextSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: _controller.listaOrcamentos.value.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _controller.listaOrcamentos.value[index];
        final ts = item['data'];
        final data = ts is Timestamp ? ts.toDate() : DateTime.now();
        return ListTile(
          leading: Icon(
            Icons.check_circle,
            color: colorGreen,
            size: 20,
          ),
          title: Text(
            item['cliente_nome'] ?? 'Cliente',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
          subtitle: Text(
            formatadorDataCompleta.format(data),
            style: TextStyle(
              color: colorTextSecondary,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            formatadorMoeda.format(item['total']),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotaoPdf({
    required String nomeMesRef,
    required String textoCiclo,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: !_controller.podeGerar(
                    carregando: _controller.carregando.value,
                  ) ||
                  _controller.listaOrcamentos.value.isEmpty
              ? null
              : () async {
                  final nomePdf = '$nomeMesRef ($textoCiclo)';
                  final bytes = await _controller.gerarPdfRelatorio(
                    mesReferencia: nomePdf,
                    orcamentos: _controller.listaOrcamentos.value,
                    totalFaturado: _controller.totalFaturado.value,
                  );

                  if (!mounted) {
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewView(
                        pdfBytes: bytes,
                        nomeArquivo: 'Relatorio_$nomeMesRef.pdf',
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('VISUALIZAR RELATORIO PDF'),
        ),
      ),
    );
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

    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller.mesSelecionado,
        _controller.carregando,
        _controller.listaOrcamentos,
        _controller.totalFaturado,
        _controller.produtosMaisUsados,
      ]),
      builder: (context, _) {
        final (inicioCicloAtual, fimCicloAtual) =
            _controller.calcularDatasCiclo(_controller.mesSelecionado.value);
        final textoCiclo =
            'Ciclo: ${formatadorDataCurta.format(inicioCicloAtual)} ate ${formatadorDataCurta.format(fimCicloAtual)}';
        final nomeMesRef = _controller
            .textoMesAno(_controller.mesSelecionado.value)
            .toUpperCase();

        return Scaffold(
          appBar: AppBar(title: const Text('Relatórios Financeiros')),
          body: Column(
            children: [
              _buildMesSelector(
                colorGreen: colorGreen,
                colorTextPrimary: colorTextPrimary,
                formatadorDataCurta: formatadorDataCurta,
                formatadorMesAno: formatadorMesAno,
              ),
              _buildResumo(
                isDark: isDark,
                colorGreen: colorGreen,
                colorTextSecondary: colorTextSecondary,
                formatadorMoeda: formatadorMoeda,
                textoCiclo: textoCiclo,
              ),
              _buildProdutosMaisUsados(
                isDark: isDark,
                colorGreen: colorGreen,
                colorTextPrimary: colorTextPrimary,
                colorTextSecondary: colorTextSecondary,
              ),
              Expanded(
                child: _buildListaOrcamentos(
                  colorGreen: colorGreen,
                  colorTextPrimary: colorTextPrimary,
                  colorTextSecondary: colorTextSecondary,
                  formatadorMoeda: formatadorMoeda,
                  formatadorDataCompleta: formatadorDataCompleta,
                ),
              ),
              _buildBotaoPdf(nomeMesRef: nomeMesRef, textoCiclo: textoCiclo),
            ],
          ),
        );
      },
    );
  }
}
