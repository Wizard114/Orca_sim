import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:orca_sim/domain/repositories/budget_repository.dart';

class StreamBudgetsUseCase {
  StreamBudgetsUseCase(this._budgetRepository);

  final IBudgetRepository _budgetRepository;

  Stream<QuerySnapshot> call() {
    return _budgetRepository.streamOrcamentos();
  }
}
