import 'dart:typed_data';

import 'package:orca_sim/domain/entities/item_orcamento.dart';

abstract class IPdfRepository {
  Future<Uint8List> gerarPdfOrcamentoBytes({
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required String observacoes,
    required List<ItemOrcamento> itens,
  });

  Future<Uint8List> gerarRelatorioFinanceiro({
    required String mesReferencia,
    required List<Map<String, dynamic>> orcamentos,
    required double totalFaturado,
  });
}
