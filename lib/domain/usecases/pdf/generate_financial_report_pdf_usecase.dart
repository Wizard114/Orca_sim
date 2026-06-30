import 'dart:typed_data';

import 'package:orca_sim/domain/repositories/pdf_repository.dart';

class GenerateFinancialReportPdfUseCase {
  GenerateFinancialReportPdfUseCase(this._pdfRepository);

  final IPdfRepository _pdfRepository;

  Future<Uint8List> call({
    required String mesReferencia,
    required List<Map<String, dynamic>> orcamentos,
    required double totalFaturado,
  }) {
    return _pdfRepository.gerarRelatorioFinanceiro(
      mesReferencia: mesReferencia,
      orcamentos: orcamentos,
      totalFaturado: totalFaturado,
    );
  }
}
