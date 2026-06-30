import 'package:orca_sim/domain/repositories/company_repository.dart';

class GetCompanyDataUseCase {
  GetCompanyDataUseCase(this._companyRepository);

  final ICompanyRepository _companyRepository;

  Future<Map<String, dynamic>?> call() {
    return _companyRepository.pegarDadosEmpresa();
  }
}
