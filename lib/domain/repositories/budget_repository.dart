import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IBudgetRepository {
  Future<void> salvarOrcamento({
    String? docId,
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required double total,
    required String observacoes,
    required List<Map<String, dynamic>> itens,
  });

  Future<void> atualizarStatusOrcamento(String docId, String novoStatus);
  Stream<QuerySnapshot> streamOrcamentos();

  Future<List<Map<String, dynamic>>> pegarOrcamentosPorPeriodo(
    DateTime inicio,
    DateTime fim,
  );

  Future<void> deletarOrcamento(String docId);
}
