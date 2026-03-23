import 'dart:typed_data';

import 'package:orca_sim/domain/entities/item_orcamento.dart';
import 'package:orca_sim/domain/repositories/pdf_repository.dart';

class GenerateBudgetPdfUseCase {
  GenerateBudgetPdfUseCase(this._pdfRepository);

  final IPdfRepository _pdfRepository;

  Future<Uint8List> call({
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required String observacoes,
    required List<ItemOrcamento> itens,
  }) {
    return _pdfRepository.gerarPdfOrcamentoBytes(
      clienteNome: clienteNome,
      clienteCpfCnpj: clienteCpfCnpj,
      nomeObra: nomeObra,
      observacoes: observacoes,
      itens: itens,
    );
  }
}
