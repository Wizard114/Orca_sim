import 'package:orca_sim/domain/repositories/budget_repository.dart';

class DeleteBudgetUseCase {
  DeleteBudgetUseCase(this._budgetRepository);

  final IBudgetRepository _budgetRepository;

  Future<void> call(String docId) {
    return _budgetRepository.deletarOrcamento(docId);
  }
}
