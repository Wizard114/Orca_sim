import 'package:orca_sim/domain/repositories/company_repository.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';

class CompanyRepository implements ICompanyRepository {
  CompanyRepository(this._firestoreService);

  final IFirestoreService _firestoreService;

  @override
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
  }) {
    return _firestoreService.salvarDadosEmpresa(
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

  @override
  Future<Map<String, dynamic>?> pegarDadosEmpresa() =>
      _firestoreService.pegarDadosEmpresa();
}
