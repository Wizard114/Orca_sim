import 'package:flutter/foundation.dart';
import 'package:orca_sim/domain/usecases/budget/get_budgets_by_period_usecase.dart';
import 'package:orca_sim/domain/usecases/company/get_company_data_usecase.dart';
import 'package:orca_sim/domain/usecases/pdf/generate_financial_report_pdf_usecase.dart';

class ReportController {
  ReportController(
    this._getCompanyDataUseCase,
    this._getBudgetsByPeriodUseCase,
    this._generateFinancialReportPdfUseCase,
  );

  final GetCompanyDataUseCase _getCompanyDataUseCase;
  final GetBudgetsByPeriodUseCase _getBudgetsByPeriodUseCase;
  final GenerateFinancialReportPdfUseCase _generateFinancialReportPdfUseCase;

  final ValueNotifier<DateTime> mesSelecionado =
      ValueNotifier<DateTime>(DateTime.now());
  final ValueNotifier<bool> carregando = ValueNotifier<bool>(true);
  final ValueNotifier<List<Map<String, dynamic>>> listaOrcamentos =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<double> totalFaturado = ValueNotifier<double>(0.0);
  final ValueNotifier<List<Map<String, dynamic>>> produtosMaisUsados =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  int diaFechamento = 1;

  Future<void> carregarDiaFechamento() async {
    final dados = await _getCompanyDataUseCase();
    if (dados != null) {
      diaFechamento = dados['dia_fechamento'] ?? 1;
    }
  }

  (DateTime, DateTime) calcularDatasCiclo(DateTime mesReferencia) {
    final dataInicio =
        DateTime(mesReferencia.year, mesReferencia.month, diaFechamento);
    final dataFim =
        DateTime(mesReferencia.year, mesReferencia.month + 1, diaFechamento)
            .subtract(const Duration(seconds: 1));
    return (dataInicio, dataFim);
  }

  List<DateTime> gerarUltimos6Meses() {
    final hoje = DateTime.now();
    return List.generate(6, (i) => DateTime(hoje.year, hoje.month - i));
  }

  String textoMesAno(DateTime data) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Marco',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${meses[data.month - 1]}/${data.year}';
  }

  bool podeGerar({required bool carregando}) => !carregando;

  void selecionarMes(DateTime novoMes) {
    mesSelecionado.value = novoMes;
  }

  Future<void> inicializar() async {
    await carregarDiaFechamento();
    final hoje = DateTime.now();
    mesSelecionado.value = DateTime(hoje.year, hoje.month);
    await buscarDadosDoMesSelecionado();
  }

  int usageCountProduto(Map<String, dynamic> produto) {
    final raw = produto['uso_mes'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return 0;
  }

  String nomeProduto(Map<String, dynamic> produto) {
    return (produto['nome'] ?? 'Produto').toString();
  }

  List<Map<String, dynamic>> calcularProdutosMaisUsadosDoMes(
    List<Map<String, dynamic>> orcamentos, {
    int limit = 5,
  }) {
    final agregados = <String, ({String nome, int usoMes})>{};

    for (final orcamento in orcamentos) {
      final itens = (orcamento['itens'] as List<dynamic>? ?? const []);
      for (final itemRaw in itens) {
        if (itemRaw is! Map<String, dynamic>) {
          continue;
        }

        final nome = (itemRaw['descricao'] ?? '').toString().trim();
        if (nome.isEmpty) {
          continue;
        }

        final quantidadeRaw = itemRaw['quantidade'];
        final quantidade = quantidadeRaw is num ? quantidadeRaw.toInt() : 1;
        final uso = quantidade <= 0 ? 1 : quantidade;

        final atual = agregados[nome];
        if (atual == null) {
          agregados[nome] = (nome: nome, usoMes: uso);
        } else {
          agregados[nome] = (nome: atual.nome, usoMes: atual.usoMes + uso);
        }
      }
    }

    final lista = agregados.values
        .map((e) => {'nome': e.nome, 'uso_mes': e.usoMes})
        .toList();

    lista.sort((a, b) {
      final usoCmp = usageCountProduto(b).compareTo(usageCountProduto(a));
      if (usoCmp != 0) {
        return usoCmp;
      }
      return nomeProduto(a)
          .toLowerCase()
          .compareTo(nomeProduto(b).toLowerCase());
    });

    final safeLimit = limit <= 0 ? 5 : limit;
    return lista.take(safeLimit).toList();
  }

  Future<(List<Map<String, dynamic>>, double)> buscarDadosDoMes(
    DateTime mesSelecionado,
  ) async {
    final (dataInicio, dataFim) = calcularDatasCiclo(mesSelecionado);
    final resultados = await _getBudgetsByPeriodUseCase(dataInicio, dataFim);

    var total = 0.0;
    for (final item in resultados) {
      total += (item['total'] ?? 0.0);
    }

    return (resultados, total);
  }

  Future<void> buscarDadosDoMesSelecionado() async {
    carregando.value = true;
    final (lista, total) = await buscarDadosDoMes(mesSelecionado.value);
    final produtos = calcularProdutosMaisUsadosDoMes(lista);

    listaOrcamentos.value = lista;
    totalFaturado.value = total;
    produtosMaisUsados.value = produtos;
    carregando.value = false;
  }

  void dispose() {
    mesSelecionado.dispose();
    carregando.dispose();
    listaOrcamentos.dispose();
    totalFaturado.dispose();
    produtosMaisUsados.dispose();
  }

  Future<Uint8List> gerarPdfRelatorio({
    required String mesReferencia,
    required List<Map<String, dynamic>> orcamentos,
    required double totalFaturado,
  }) {
    return _generateFinancialReportPdfUseCase(
      mesReferencia: mesReferencia,
      orcamentos: orcamentos,
      totalFaturado: totalFaturado,
    );
  }
}
