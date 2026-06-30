import 'dart:typed_data';

import 'package:orca_sim/domain/entities/item_orcamento.dart';
import 'package:orca_sim/domain/repositories/pdf_repository.dart';
import 'package:orca_sim/domain/services/pdf_service.dart';

class PdfRepository implements IPdfRepository {
  PdfRepository(this._pdfService);

  final IPdfService _pdfService;

  @override
  Future<Uint8List> gerarPdfOrcamentoBytes({
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required String observacoes,
    required List<ItemOrcamento> itens,
  }) {
    return _pdfService.gerarPdfOrcamentoBytes(
      clienteNome: clienteNome,
      clienteCpfCnpj: clienteCpfCnpj,
      nomeObra: nomeObra,
      observacoes: observacoes,
      itens: itens,
    );
  }

  @override
  Future<Uint8List> gerarRelatorioFinanceiro({
    required String mesReferencia,
    required List<Map<String, dynamic>> orcamentos,
    required double totalFaturado,
  }) {
    return _pdfService.gerarRelatorioFinanceiro(
      mesReferencia: mesReferencia,
      orcamentos: orcamentos,
      totalFaturado: totalFaturado,
    );
  }
}
