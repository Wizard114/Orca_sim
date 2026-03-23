import 'package:flutter/material.dart';
import 'package:orca_sim/domain/entities/item_orcamento.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';

class ProductsController {
  ProductsController(this._firestoreService);

  final IFirestoreService _firestoreService;
  final TextEditingController buscaController = TextEditingController();

  final ValueNotifier<List<Map<String, dynamic>>> produtos =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<bool> carregando = ValueNotifier<bool>(true);

  Future<void> carregarProdutosState({String? query}) async {
    carregando.value = true;
    produtos.value = await carregarProdutos(query: query);
    carregando.value = false;
  }

  void dispose() {
    buscaController.dispose();
    produtos.dispose();
    carregando.dispose();
  }

  Future<List<Map<String, dynamic>>> carregarProdutos({String? query}) {
    return _firestoreService.listarProdutosEmpresa(query: query);
  }

  Future<void> salvarProduto({
    required String nome,
    required String unidade,
    required double preco,
    String? produtoKey,
  }) {
    return _firestoreService.salvarProdutoEmpresa(
      nome: nome,
      unidade: unidade,
      preco: preco,
      produtoKey: produtoKey,
    );
  }

  Future<void> deletarProduto(String produtoKey) {
    return _firestoreService.deletarProdutoEmpresa(produtoKey);
  }

  List<Map<String, dynamic>> buscarSugestoesProduto(
    String query, {
    int limit = 10,
  }) {
    return _firestoreService.topProdutosEmpresa(query: query, limit: limit);
  }

  double obterPrecoProduto(Map<String, dynamic> produto) {
    final precoCentavos = produto['preco_centavos'];
    if (precoCentavos is int) {
      return precoCentavos / 100.0;
    }
    if (precoCentavos is num) {
      return precoCentavos.toDouble() / 100.0;
    }

    final preco = produto['preco'];
    if (preco is num) {
      return preco.toDouble();
    }

    return 0.0;
  }

  ItemOrcamento produtoParaItem(Map<String, dynamic> produto) {
    return ItemOrcamento(
      descricao: (produto['nome'] ?? '').toString(),
      quantidade: 1,
      unidade: (produto['unidade'] ?? 'un').toString(),
      valorUnitario: obterPrecoProduto(produto),
    );
  }

  String produtoNome(Map<String, dynamic> produto) {
    return (produto['nome'] ?? 'Produto').toString();
  }

  String produtoUnidade(Map<String, dynamic> produto) {
    return (produto['unidade'] ?? 'un').toString();
  }

  int produtoUsageCount(Map<String, dynamic> produto) {
    final raw = produto['usage_count'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return 0;
  }

  String produtoKey(Map<String, dynamic> produto) {
    return (produto['nome_normalizado'] ?? '').toString();
  }

  bool podeExcluirProduto(String key) => key.trim().isNotEmpty;

  String normalizarBusca(String value) => value.trim();
}
