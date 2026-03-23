import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:orca_sim/domain/entities/item_orcamento.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';
import 'package:orca_sim/domain/usecases/budget/save_budget_usecase.dart';
import 'package:orca_sim/domain/usecases/pdf/generate_budget_pdf_usecase.dart';

typedef BudgetInitData = ({
  String clienteNome,
  String clienteCpfCnpj,
  String nomeObra,
  String observacoes,
  List<ItemOrcamento> itens,
  List<String?> produtoKeys,
});

class NewBudgetController {
  NewBudgetController(
    this._saveBudgetUseCase,
    this._generateBudgetPdfUseCase,
    this._firestoreService,
  );

  final SaveBudgetUseCase _saveBudgetUseCase;
  final GenerateBudgetPdfUseCase _generateBudgetPdfUseCase;
  final IFirestoreService _firestoreService;

  final TextEditingController clienteNomeController = TextEditingController();
  final TextEditingController clienteCpfCnpjController =
      TextEditingController();
  final TextEditingController nomeObraController = TextEditingController();
  final TextEditingController obsController = TextEditingController();

  final ValueNotifier<List<ItemOrcamento>> itens =
      ValueNotifier<List<ItemOrcamento>>([]);
  final ValueNotifier<List<String?>> produtoKeys =
      ValueNotifier<List<String?>>([]);
  final ValueNotifier<bool> gerandoPdf = ValueNotifier<bool>(false);

  void inicializarFormulario(Map<String, dynamic>? dadosExistentes) {
    final data = fromDadosExistentes(dadosExistentes);
    clienteNomeController.text = data.clienteNome;
    clienteCpfCnpjController.text = data.clienteCpfCnpj;
    nomeObraController.text = data.nomeObra;
    obsController.text = data.observacoes;
    itens.value = data.itens;
    produtoKeys.value = data.produtoKeys;
  }

  Future<void> preloadProdutosSugestoes() {
    return _firestoreService.preloadProdutosEmpresa();
  }

  void dispose() {
    clienteNomeController.dispose();
    clienteCpfCnpjController.dispose();
    nomeObraController.dispose();
    obsController.dispose();
    itens.dispose();
    produtoKeys.dispose();
    gerandoPdf.dispose();
  }

  BudgetInitData fromDadosExistentes(Map<String, dynamic>? dadosExistentes) {
    if (dadosExistentes == null) {
      return (
        clienteNome: '',
        clienteCpfCnpj: '',
        nomeObra: '',
        observacoes: '',
        itens: <ItemOrcamento>[],
        produtoKeys: <String?>[],
      );
    }

    final itensSalvos = dadosExistentes['itens'] as List<dynamic>? ?? const [];
    final itensIniciais = <ItemOrcamento>[];
    final produtoKeysIniciais = <String?>[];

    for (final item in itensSalvos) {
      final itemMap = item as Map<String, dynamic>;
      itensIniciais.add(
        ItemOrcamento(
          descricao: itemMap['descricao'] ?? '',
          quantidade: itemMap['quantidade'] ?? 1,
          unidade: itemMap['unidade'] ?? 'un',
          valorUnitario: ((itemMap['valor'] ?? 0) as num).toDouble(),
        ),
      );
      produtoKeysIniciais.add(itemMap['produto_key']?.toString());
    }

    return (
      clienteNome: (dadosExistentes['cliente_nome'] ?? '').toString(),
      clienteCpfCnpj: (dadosExistentes['cliente_cpf_cnpj'] ??
              dadosExistentes['cliente_tel'] ??
              '')
          .toString(),
      nomeObra: (dadosExistentes['nome_obra'] ?? '').toString(),
      observacoes: (dadosExistentes['observacoes'] ?? '').toString(),
      itens: itensIniciais,
      produtoKeys: produtoKeysIniciais,
    );
  }

  double calcularTotalGeral(List<ItemOrcamento> itens) {
    return itens.fold(0, (soma, item) => soma + item.total);
  }

  Color corDestaque(bool isDark) {
    return isDark ? Colors.greenAccent : Colors.green[800]!;
  }

  Color corIcone(bool isDark) {
    return isDark ? Colors.orangeAccent : Colors.orange[800]!;
  }

  (List<ItemOrcamento> itens, List<String?> produtoKeys) removerItemPorIndice({
    required List<ItemOrcamento> itens,
    required List<String?> produtoKeys,
    required int index,
  }) {
    final itensAtualizados = List<ItemOrcamento>.from(itens)..removeAt(index);
    final produtoKeysAtualizados = List<String?>.from(produtoKeys);
    if (produtoKeysAtualizados.length > index) {
      produtoKeysAtualizados.removeAt(index);
    }
    return (itensAtualizados, produtoKeysAtualizados);
  }

  (List<ItemOrcamento> itens, List<String?> produtoKeys) aplicarResultadoModal({
    required List<ItemOrcamento> itens,
    required List<String?> produtoKeys,
    required ItemOrcamento item,
    required String? produtoKey,
    int? index,
  }) {
    final itensAtualizados = List<ItemOrcamento>.from(itens);
    final produtoKeysAtualizados = List<String?>.from(produtoKeys);

    if (index != null) {
      itensAtualizados[index] = item;
      produtoKeysAtualizados[index] = produtoKey;
    } else {
      itensAtualizados.add(item);
      produtoKeysAtualizados.add(produtoKey);
    }

    return (itensAtualizados, produtoKeysAtualizados);
  }

  List<Map<String, dynamic>> montarListaParaSalvar({
    required List<ItemOrcamento> itens,
    required List<String?> produtoKeys,
  }) {
    return itens.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final payload = {
        'descricao': item.descricao,
        'quantidade': item.quantidade,
        'unidade': item.unidade,
        'valor': item.valorUnitario,
      };
      final produtoKey = produtoKeys.length > index ? produtoKeys[index] : null;
      if (produtoKey != null && produtoKey.isNotEmpty) {
        payload['produto_key'] = produtoKey;
      }
      return payload;
    }).toList();
  }

  bool validarClienteNome(String clienteNome) {
    return clienteNome.trim().isNotEmpty;
  }

  Future<void> salvarOrcamento({
    String? docId,
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required String observacoes,
    required double total,
    required List<Map<String, dynamic>> itens,
  }) {
    return _saveBudgetUseCase(
      docId: docId,
      clienteNome: clienteNome,
      clienteCpfCnpj: clienteCpfCnpj,
      nomeObra: nomeObra,
      observacoes: observacoes,
      total: total,
      itens: itens,
    );
  }

  Future<Uint8List> gerarPdfOrcamento({
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required String observacoes,
    required List<ItemOrcamento> itens,
  }) {
    return _generateBudgetPdfUseCase(
      clienteNome: clienteNome,
      clienteCpfCnpj: clienteCpfCnpj,
      nomeObra: nomeObra,
      observacoes: observacoes,
      itens: itens,
    );
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
}
