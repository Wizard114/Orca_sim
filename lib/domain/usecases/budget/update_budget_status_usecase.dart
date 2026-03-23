import 'package:orca_sim/domain/repositories/budget_repository.dart';

class UpdateBudgetStatusUseCase {
  UpdateBudgetStatusUseCase(this._budgetRepository);

  final IBudgetRepository _budgetRepository;

  Future<void> call(String docId, String novoStatus) {
    return _budgetRepository.atualizarStatusOrcamento(docId, novoStatus);
  }
}
