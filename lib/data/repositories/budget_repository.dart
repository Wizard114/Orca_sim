import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:orca_sim/domain/repositories/budget_repository.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';

class BudgetRepository implements IBudgetRepository {
  BudgetRepository(this._firestoreService);

  final IFirestoreService _firestoreService;

  @override
  Future<void> salvarOrcamento({
    String? docId,
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required double total,
    required String observacoes,
    required List<Map<String, dynamic>> itens,
  }) {
    return _firestoreService.salvarOrcamento(
      docId: docId,
      clienteNome: clienteNome,
      clienteCpfCnpj: clienteCpfCnpj,
      nomeObra: nomeObra,
      total: total,
      observacoes: observacoes,
      itens: itens,
    );
  }

  @override
  Future<void> atualizarStatusOrcamento(String docId, String novoStatus) {
    return _firestoreService.atualizarStatusOrcamento(docId, novoStatus);
  }

  @override
  Stream<QuerySnapshot> streamOrcamentos() =>
      _firestoreService.streamOrcamentos();

  @override
  Future<List<Map<String, dynamic>>> pegarOrcamentosPorPeriodo(
    DateTime inicio,
    DateTime fim,
  ) {
    return _firestoreService.pegarOrcamentosPorPeriodo(inicio, fim);
  }

  @override
  Future<void> deletarOrcamento(String docId) =>
      _firestoreService.deletarOrcamento(docId);
}
