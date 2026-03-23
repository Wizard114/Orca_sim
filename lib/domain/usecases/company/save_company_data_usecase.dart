import 'package:orca_sim/domain/repositories/company_repository.dart';

class SaveCompanyDataUseCase {
  SaveCompanyDataUseCase(this._companyRepository);

  final ICompanyRepository _companyRepository;

  Future<void> call({
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    String? logoPath,
    required int validadeOrcamento,
    required String temaApp,
    required String corPdf,
    required int diaFechamento,
  }) {
    return _companyRepository.salvarDadosEmpresa(
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      logoPath: logoPath,
      validadeOrcamento: validadeOrcamento,
      temaApp: temaApp,
      corPdf: corPdf,
      diaFechamento: diaFechamento,
    );
  }
}
