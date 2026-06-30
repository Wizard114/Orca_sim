import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orca_sim/domain/entities/item_orcamento.dart';
import 'package:orca_sim/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:orca_sim/domain/usecases/auth/logout_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/delete_budget_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/stream_budgets_usecase.dart';
import 'package:orca_sim/domain/usecases/budget/update_budget_status_usecase.dart';
import 'package:orca_sim/domain/usecases/company/get_company_data_usecase.dart';
import 'package:orca_sim/domain/usecases/pdf/generate_budget_pdf_usecase.dart';

class HomeController {
  HomeController(
    this._getCurrentUserUseCase,
    this._logoutUseCase,
    this._getCompanyDataUseCase,
    this._streamBudgetsUseCase,
    this._updateBudgetStatusUseCase,
    this._deleteBudgetUseCase,
    this._generateBudgetPdfUseCase,
  );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCompanyDataUseCase _getCompanyDataUseCase;
  final StreamBudgetsUseCase _streamBudgetsUseCase;
  final UpdateBudgetStatusUseCase _updateBudgetStatusUseCase;
  final DeleteBudgetUseCase _deleteBudgetUseCase;
  final GenerateBudgetPdfUseCase _generateBudgetPdfUseCase;

  final ValueNotifier<int> uiTick = ValueNotifier<int>(0);

  bool valoresVisiveis = true;
  int diaFechamento = 1;
  String? logoPath;
  String nomeEmpresa = 'Minha Empresa';

  bool get possuiLogoLocalValido {
    final path = logoPath;
    return path != null && path.trim().isNotEmpty;
  }

  bool possuiArquivoLogo() {
    if (!possuiLogoLocalValido) {
      return false;
    }
    return File(logoPath!).existsSync();
  }

  User? get currentUser => _getCurrentUserUseCase();

  void notificarUi() {
    uiTick.value++;
  }

  void dispose() {
    uiTick.dispose();
  }

  void toggleValoresVisiveis() {
    valoresVisiveis = !valoresVisiveis;
  }

  Future<void> carregarConfigs() async {
    final dados = await _getCompanyDataUseCase();
    if (dados == null) {
      return;
    }

    diaFechamento = dados['dia_fechamento'] ?? 1;
    logoPath = dados['logo_local_path'];
    nomeEmpresa = (dados['nome_empresa'] != null &&
            dados['nome_empresa'].toString().isNotEmpty)
        ? dados['nome_empresa']
        : 'Minha Empresa';
  }

  Stream<QuerySnapshot> streamOrcamentos() => _streamBudgetsUseCase();

  List<ItemOrcamento> converterItens(List<dynamic> listaDoBanco) {
    return listaDoBanco.map((itemJson) {
      return ItemOrcamento(
        descricao: itemJson['descricao'] ?? '',
        quantidade: itemJson['quantidade'] ?? 1,
        unidade: itemJson['unidade'] ?? 'un',
        valorUnitario: (itemJson['valor'] ?? 0.0).toDouble(),
      );
    }).toList();
  }

  Future<void> atualizarStatusOrcamento(String docId, String status) {
    return _updateBudgetStatusUseCase(docId, status);
  }

  Future<void> deletarOrcamento(String docId) => _deleteBudgetUseCase(docId);

  Future<Uint8List> gerarPdfOrcamento({
    required String cliente,
    required Map<String, dynamic> orcamento,
  }) {
    final listaItens = converterItens(orcamento['itens'] ?? []);

    return _generateBudgetPdfUseCase(
      clienteNome: cliente,
      clienteCpfCnpj: orcamento['cliente_cpf_cnpj'] ?? '',
      nomeObra: orcamento['nome_obra'] ?? '',
      observacoes: orcamento['observacoes'] ?? '',
      itens: listaItens,
    );
  }

  Future<void> sair() => _logoutUseCase();

  Map<String, dynamic> getStatusInfo({
    required String status,
    required Color colorGreen,
    required Color colorOrange,
  }) {
    switch (status) {
      case 'Aprovado':
        return {'color': colorGreen, 'icon': Icons.check_circle};
      case 'Recusado':
        return {'color': Colors.redAccent, 'icon': Icons.cancel};
      default:
        return {'color': colorOrange, 'icon': Icons.access_time_filled};
    }
  }

  (double faturamento, int aprovados) calcularResumoCiclo(
    List<QueryDocumentSnapshot<Object?>> documentos,
  ) {
    var faturamentoMesAtual = 0.0;
    var qtdAprovados = 0;

    final hoje = DateTime.now();
    DateTime inicioCiclo;
    if (hoje.day >= diaFechamento) {
      inicioCiclo = DateTime(hoje.year, hoje.month, diaFechamento);
    } else {
      inicioCiclo = DateTime(hoje.year, hoje.month - 1, diaFechamento);
    }
    final fimCiclo =
        DateTime(inicioCiclo.year, inicioCiclo.month + 1, diaFechamento);

    for (final doc in documentos) {
      final dados = doc.data() as Map<String, dynamic>;
      final dataTs = dados['data'];

      if (dados['status'] == 'Aprovado' && dataTs is Timestamp) {
        final dataOrc = dataTs.toDate();
        if (dataOrc.isAfter(inicioCiclo.subtract(const Duration(seconds: 1))) &&
            dataOrc.isBefore(fimCiclo)) {
          faturamentoMesAtual += (dados['total'] ?? 0.0).toDouble();
          qtdAprovados++;
        }
      }
    }

    return (faturamentoMesAtual, qtdAprovados);
  }
}
