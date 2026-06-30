import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IFirestoreService {
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
  });

  Future<Map<String, dynamic>?> pegarDadosEmpresa();

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

  Future<void> preloadProdutosEmpresa();

  List<Map<String, dynamic>> topProdutosEmpresa({
    String? query,
    int limit = 10,
  });

  Future<List<Map<String, dynamic>>> listarProdutosEmpresa({String? query});

  Future<void> salvarProdutoEmpresa({
    required String nome,
    required String unidade,
    required double preco,
    String? produtoKey,
  });

  Future<void> deletarProdutoEmpresa(String produtoKey);

  Future<void> sincronizarProdutosAoSalvarOrcamento(
    List<Map<String, dynamic>> itens,
  );
}
