import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import '../pages/novo_orcamento_page.dart';

class PdfService {
  Future<Uint8List> gerarPdfOrcamentoBytes({
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required String observacoes,
    required List<ItemOrcamento> itens,
  }) async {
    final pdf = pw.Document();

    final dadosEmpresa = await FirestoreService().pegarDadosEmpresa();

    pw.MemoryImage? logoImage;
    if (dadosEmpresa != null && dadosEmpresa['logo_local_path'] != null) {
      final file = File(dadosEmpresa['logo_local_path']);
      if (file.existsSync()) {
        logoImage = pw.MemoryImage(file.readAsBytesSync());
      }
    }

    final int diasValidade = dadosEmpresa?['validade_orcamento'] ?? 15;
    final String corHex = dadosEmpresa?['cor_pdf'] ?? '0xFF448AFF';
    final PdfColor corDestaque = PdfColor.fromInt(int.parse(corHex));
    final String nomeEmpresa = dadosEmpresa?['nome_empresa'] ?? "Minha Empresa";
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dataHoje = DateTime.now();
    final dataValidade = dataHoje.add(Duration(days: diasValidade));
    final formatadorData = DateFormat('dd/MM/yyyy');

    double totalGeral = itens.fold(0, (soma, item) => soma + item.total);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoImage != null)
                  pw.Container(
                      height: 70, width: 70, child: pw.Image(logoImage))
                else
                  pw.Text(nomeEmpresa,
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: corDestaque)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(nomeEmpresa,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text(dadosEmpresa?['cnpj'] ?? ""),
                    pw.Text(dadosEmpresa?['telefone'] ?? ""),
                    pw.Text(dadosEmpresa?['endereco'] ?? "",
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: corDestaque),
            pw.SizedBox(height: 10),

            pw.Center(
                child: pw.Text("ORÇAMENTO",
                    style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: corDestaque))),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("CLIENTE:",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                      color: corDestaque)),
                              pw.Text(clienteNome,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 14)),
                              if (clienteCpfCnpj.isNotEmpty)
                                pw.Text("CPF/CNPJ: $clienteCpfCnpj",
                                    style: const pw.TextStyle(fontSize: 10)),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                  "DATA: ${formatadorData.format(dataHoje)}"),
                              pw.Text(
                                  "VÁLIDO ATÉ: ${formatadorData.format(dataValidade)}",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.red)),
                            ]),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 5),
                    pw.Text("INFORMAÇÕES DO SERVIÇO A SER EXECUTADO:",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: corDestaque)),
                    pw.Text(nomeObra.isEmpty ? "Não especificado" : nomeObra,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ]),
            ),

            pw.SizedBox(height: 30),

            // CORREÇÃO: Usando TableHelper para não dar erro de deprecated
            pw.TableHelper.fromTextArray(
              headers: ['Descrição', 'Qtd', 'Un', 'Valor Unit.', 'Total'],
              data: itens.map((item) {
                return [
                  item.descricao,
                  item.quantidade.toString(),
                  item.unidade,
                  formatadorMoeda.format(item.valorUnitario),
                  formatadorMoeda.format(item.total),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: corDestaque),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),

            pw.SizedBox(height: 20),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text("TOTAL GERAL: ",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(formatadorMoeda.format(totalGeral),
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: corDestaque)),
              ],
            ),

            if (observacoes.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("OBSERVAÇÕES / CONDIÇÕES:",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text(observacoes,
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 50),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
                child: pw.Text("Orçamento gerado via App Orça Sim.",
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey))),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  Future<Uint8List> gerarRelatorioFinanceiro({
    required String mesReferencia,
    required List<Map<String, dynamic>> orcamentos,
    required double totalFaturado,
  }) async {
    final pdf = pw.Document();
    final dadosEmpresa = await FirestoreService().pegarDadosEmpresa();

    pw.MemoryImage? logoImage;
    if (dadosEmpresa != null && dadosEmpresa['logo_local_path'] != null) {
      final file = File(dadosEmpresa['logo_local_path']);
      if (file.existsSync()) {
        logoImage = pw.MemoryImage(file.readAsBytesSync());
      }
    }

    final String nomeEmpresa = dadosEmpresa?['nome_empresa'] ?? "Minha Empresa";
    final String cnpjEmpresa = dadosEmpresa?['cnpj'] ?? "";
    final String corHex = dadosEmpresa?['cor_pdf'] ?? '0xFF448AFF';
    final PdfColor corDestaque = PdfColor.fromInt(int.parse(corHex));
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorData = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoImage != null)
                  pw.Container(
                      height: 70, width: 70, child: pw.Image(logoImage))
                else
                  pw.Text(nomeEmpresa,
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: corDestaque)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(nomeEmpresa,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text(cnpjEmpresa),
                    pw.Text(dadosEmpresa?['telefone'] ?? ""),
                    pw.Text(dadosEmpresa?['endereco'] ?? "",
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: corDestaque),
            pw.SizedBox(height: 10),

            pw.Center(
                child: pw.Column(children: [
              pw.Text("RELATÓRIO FINANCEIRO MENSAL",
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: corDestaque)),
              pw.SizedBox(height: 5),
              pw.Text("Referência: $mesReferencia",
                  style: const pw.TextStyle(fontSize: 12)),
            ])),
            pw.SizedBox(height: 20),

            pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("RECEITA BRUTA TOTAL:",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(formatadorMoeda.format(totalFaturado),
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green,
                              fontSize: 18)),
                    ])),
            pw.SizedBox(height: 30),

            pw.Text("Detalhamento das Receitas:",
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 10),

            // CORREÇÃO: Usando TableHelper aqui também
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Cliente', 'Status', 'Valor'],
              data: orcamentos.map((orc) {
                dynamic dataRaw = orc['data'];
                String dataFormatada = '-';
                if (dataRaw != null) {
                  if (dataRaw.runtimeType.toString().contains('Timestamp')) {
                    try {
                      dataFormatada = formatadorData.format(dataRaw.toDate());
                    } catch (e) {
                      dataFormatada = '-';
                    }
                  } else if (dataRaw is DateTime)
                    dataFormatada = formatadorData.format(dataRaw);
                }
                return [
                  dataFormatada,
                  orc['cliente_nome'] ?? 'Desconhecido',
                  (orc['status'] ?? '').toUpperCase(),
                  formatadorMoeda.format(orc['total'] ?? 0)
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: corDestaque),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight
              },
            ),
            pw.SizedBox(height: 40),

            pw.Divider(color: PdfColors.grey400, thickness: 0.5),

            pw.SizedBox(height: 10),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(width: 3, height: 35, color: PdfColors.grey500),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(
                    "DECLARAÇÃO DE CONTEÚDO: Este relatório destina-se ao controle gerencial e conferência de faturamento para fins de apuração mensal (Simples Nacional / MEI). Os valores aqui expressos devem ser conciliados com as Notas Fiscais emitidas e extratos bancários.\nDocumento gerado eletronicamente pelo app Orça Sim.",
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.justify),
              )
            ]),
          ];
        },
      ),
    );

    return await pdf.save();
  }
}
