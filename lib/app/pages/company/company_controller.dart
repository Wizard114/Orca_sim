import 'dart:io';

import 'package:flutter/material.dart';
import 'package:orca_sim/domain/usecases/company/get_company_data_usecase.dart';
import 'package:orca_sim/domain/usecases/company/save_company_data_usecase.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

typedef CompanyFormData = ({
  String nome,
  String cnpj,
  String telefone,
  String endereco,
  String? logoPath,
  int validadeOrcamento,
  String temaApp,
  String corPdf,
  int diaFechamento,
});

class CompanyController {
  CompanyController(this._getCompanyDataUseCase, this._saveCompanyDataUseCase);

  final GetCompanyDataUseCase _getCompanyDataUseCase;
  final SaveCompanyDataUseCase _saveCompanyDataUseCase;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cnpjController = TextEditingController();
  final TextEditingController telController = TextEditingController();
  final TextEditingController enderecoController = TextEditingController();

  File? logoImage;
  String? logoPathSalvo;
  int validadeSelecionada = 15;
  String temaSelecionado = 'Sistema';
  String corPdfSelecionada = '0xFF448AFF';
  int diaFechamento = 1;

  final ValueNotifier<int> uiTick = ValueNotifier<int>(0);

  void notificarUi() {
    uiTick.value++;
  }

  void dispose() {
    nomeController.dispose();
    cnpjController.dispose();
    telController.dispose();
    enderecoController.dispose();
    uiTick.dispose();
  }

  void inicializarFormulario(Map<String, dynamic> dados) {
    final formData = fromCompanyData(dados);

    nomeController.text = formData.nome;
    cnpjController.text = formData.cnpj;
    telController.text = formData.telefone;
    enderecoController.text = formData.endereco;
    logoPathSalvo = formData.logoPath;

    logoImage = logoValido(logoPathSalvo);

    validadeSelecionada = formData.validadeOrcamento;
    temaSelecionado = temaComFallback(formData.temaApp);
    corPdfSelecionada = formData.corPdf;
    diaFechamento = formData.diaFechamento;
  }

  CompanyFormData fromCompanyData(Map<String, dynamic>? data) {
    return (
      nome: (data?['nome_empresa'] ?? '').toString(),
      cnpj: (data?['cnpj'] ?? '').toString(),
      telefone: (data?['telefone'] ?? '').toString(),
      endereco: (data?['endereco'] ?? '').toString(),
      logoPath: data?['logo_local_path']?.toString(),
      validadeOrcamento: data?['validade_orcamento'] ?? 15,
      temaApp: (data?['tema_app'] ?? 'Claro').toString(),
      corPdf: (data?['cor_pdf'] ?? '0xFF448AFF').toString(),
      diaFechamento: data?['dia_fechamento'] ?? 1,
    );
  }

  bool nomeEmpresaValido(String nome) => nome.trim().isNotEmpty;

  String temaComFallback(String? tema) {
    switch (tema) {
      case 'Claro':
      case 'Escuro':
      case 'Sistema':
        return tema!;
      default:
        return 'Sistema';
    }
  }

  ThemeMode themeModeFromTema(String tema) {
    switch (temaComFallback(tema)) {
      case 'Escuro':
        return ThemeMode.dark;
      case 'Claro':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  File? logoValido(String? logoPath) {
    if (logoPath == null || logoPath.trim().isEmpty) {
      return null;
    }

    final file = File(logoPath);
    if (!file.existsSync()) {
      return null;
    }

    return file;
  }

  Future<String?> salvarImagemLocalmente(File imagem) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final nomeArquivo = path.basename(imagem.path);
      final imagemSalva = await imagem.copy('${appDir.path}/$nomeArquivo');
      return imagemSalva.path;
    } catch (_) {
      return imagem.path;
    }
  }

  Future<Map<String, dynamic>?> carregarDados() => _getCompanyDataUseCase();

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
  }) {
    return _saveCompanyDataUseCase(
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      logoPath: logoPath,
      validadeOrcamento: validadeOrcamento,
      temaApp: temaApp,
      corPdf: corPdf,
      diaFechamento: diaFechamento,
    );
  }
}
