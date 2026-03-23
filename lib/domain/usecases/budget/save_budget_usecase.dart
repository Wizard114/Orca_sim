import 'package:orca_sim/domain/repositories/budget_repository.dart';

class SaveBudgetUseCase {
  SaveBudgetUseCase(this._budgetRepository);

  final IBudgetRepository _budgetRepository;

  Future<void> call({
    String? docId,
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required double total,
    required String observacoes,
    required List<Map<String, dynamic>> itens,
  }) {
    return _budgetRepository.salvarOrcamento(
      docId: docId,
      clienteNome: clienteNome,
      clienteCpfCnpj: clienteCpfCnpj,
      nomeObra: nomeObra,
      total: total,
      observacoes: observacoes,
      itens: itens,
    );
  }
}
