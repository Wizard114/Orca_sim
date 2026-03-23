abstract class ICompanyRepository {
  Future<void> salvarDadosEmpresa({
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    String? logoPath,
    required int validadeOrcamento,
    required String temaApp,
    required String corPdf,
    required int diaFechamento,
  });

  Future<Map<String, dynamic>?> pegarDadosEmpresa();
}
