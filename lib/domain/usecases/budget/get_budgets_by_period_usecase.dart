import 'package:orca_sim/domain/repositories/budget_repository.dart';

class GetBudgetsByPeriodUseCase {
  GetBudgetsByPeriodUseCase(this._budgetRepository);

  final IBudgetRepository _budgetRepository;

  Future<List<Map<String, dynamic>>> call(DateTime inicio, DateTime fim) {
    return _budgetRepository.pegarOrcamentosPorPeriodo(inicio, fim);
  }
}
