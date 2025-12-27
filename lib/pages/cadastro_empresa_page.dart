import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../services/firestore_service.dart';
import '../main.dart';

class CadastroEmpresaPage extends StatefulWidget {
  const CadastroEmpresaPage({super.key});

  @override
  State<CadastroEmpresaPage> createState() => _CadastroEmpresaPageState();
}

class _CadastroEmpresaPageState extends State<CadastroEmpresaPage> {
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telController = TextEditingController();
  final _enderecoController = TextEditingController();

  File? _logoImage;
  String? _logoPathSalvo;

  int _validadeSelecionada = 15;
  String _temaSelecionado = 'Claro';
  String _corPdfSelecionada = '0xFF448AFF';
  int _diaFechamento = 1;

  bool _temAlteracoes = false;

  final Map<String, Color> _opcoesCores = {
    'Azul': const Color(0xFF448AFF),
    'Verde': Colors.green,
    'Vermelho': Colors.redAccent,
    'Laranja': Colors.orange,
    'Roxo': Colors.purple,
    'Preto': const Color(0xFF121212),
  };

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _marcarAlteracao() {
    if (!_temAlteracoes) {
      setState(() => _temAlteracoes = true);
    }
  }

  Future<void> _carregarDados() async {
    var dados = await FirestoreService().pegarDadosEmpresa();
    if (dados != null) {
      setState(() {
        _nomeController.text = dados['nome_empresa'] ?? '';
        _cnpjController.text = dados['cnpj'] ?? '';
        _telController.text = dados['telefone'] ?? '';
        _enderecoController.text = dados['endereco'] ?? '';
        _logoPathSalvo = dados['logo_local_path'];

        if (_logoPathSalvo != null) {
          final file = File(_logoPathSalvo!);
          if (file.existsSync()) {
            _logoImage = file;
          }
        }

        _validadeSelecionada = dados['validade_orcamento'] ?? 15;
        _temaSelecionado = dados['tema_app'] ?? 'Claro';
        _corPdfSelecionada = dados['cor_pdf'] ?? '0xFF448AFF';
        _diaFechamento = dados['dia_fechamento'] ?? 1;

        _temAlteracoes = false;
      });
    }
  }

  Future<void> _selecionarLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _logoImage = File(pickedFile.path));
      _marcarAlteracao();
    }
  }

  Future<String?> _salvarImagemLocalmente(File imagem) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final nomeArquivo = path.basename(imagem.path);
      final imagemSalva = await imagem.copy('${appDir.path}/$nomeArquivo');
      return imagemSalva.path;
    } catch (e) {
      print("Erro ao salvar imagem: $e");
      return imagem.path;
    }
  }

  Future<void> _salvar() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("O nome da empresa é obrigatório!")));
      return;
    }

    themeNotifier.value =
        (_temaSelecionado == 'Escuro') ? ThemeMode.dark : ThemeMode.light;

    String? caminhoFinalLogo = _logoPathSalvo;
    if (_logoImage != null && _logoImage!.path != _logoPathSalvo) {
      caminhoFinalLogo = await _salvarImagemLocalmente(_logoImage!);
    }

    await FirestoreService().salvarDadosEmpresa(
      nome: _nomeController.text,
      cnpj: _cnpjController.text,
      telefone: _telController.text,
      endereco: _enderecoController.text,
      logoPath: caminhoFinalLogo,
      validadeOrcamento: _validadeSelecionada,
      temaApp: _temaSelecionado,
      corPdf: _corPdfSelecionada,
      diaFechamento: _diaFechamento,
    );

    _temAlteracoes = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Configurações salvas!"),
          backgroundColor: Colors.green));
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  // --- NOVA LÓGICA DO POP-UP COM CORES E ORDEM ---
  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deveSair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alterações não salvas"),
        content:
            const Text("Você tem alterações pendentes. O que deseja fazer?"),
        // Alinhamento vertical dos botões
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // 1. SALVAR E SAIR (Verde - Destaque)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, false);
                await _salvar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.greenAccent : Colors.green[800],
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("SALVAR E SAIR"),
            ),
          ),

          const SizedBox(height: 8),

          // 2. SAIR SEM SALVAR (Amarelo/Âmbar - Atenção)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                    color: isDark ? Colors.amberAccent : Colors.amber[800]!),
                foregroundColor:
                    isDark ? Colors.amberAccent : Colors.amber[900],
              ),
              child: const Text("SAIR SEM SALVAR"),
            ),
          ),

          const SizedBox(height: 8),

          // 3. CANCELAR (Vermelho - Texto simples)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              child: const Text("CANCELAR"),
            ),
          ),
        ],
      ),
    );

    if (deveSair == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  InputDecoration _estiloInput(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon:
          Icon(icon, color: isDark ? Colors.orangeAccent : Colors.orange[800]),
      filled: true,
      fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      labelStyle:
          TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[800]),
    );
  }

  Widget _buildCorLed(Color cor, String valorHex) {
    bool isSelected = _corPdfSelecionada == valorHex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color borderColor;
    if (isSelected) {
      borderColor = Colors.white;
    } else {
      borderColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _corPdfSelecionada = valorHex);
        _marcarAlteracao();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSelected ? 4 : 1.5),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: cor.withOpacity(0.7),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 28)
            : null,
      ),
    );
  }

  Widget _buildTemaCard(
      String titulo, IconData icon, String valor, Color corAtiva) {
    bool isSelected = _temaSelecionado == valor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _temaSelecionado = valor);
          _marcarAlteracao();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 80,
          decoration: BoxDecoration(
              color: isSelected
                  ? corAtiva.withOpacity(0.2)
                  : (isDark ? Colors.grey[900] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: isSelected ? corAtiva : Colors.transparent, width: 2),
              boxShadow: isSelected
                  ? [BoxShadow(color: corAtiva.withOpacity(0.3), blurRadius: 8)]
                  : []),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: isSelected ? corAtiva : Colors.grey),
              const SizedBox(height: 5),
              Text(titulo,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? corAtiva : Colors.grey))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      canPop: !_temAlteracoes,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(title: const Text("Minha Empresa")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _selecionarLogo,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[300],
                        backgroundImage:
                            _logoImage != null ? FileImage(_logoImage!) : null,
                        child: _logoImage == null
                            ? Icon(Icons.add_a_photo,
                                size: 40,
                                color: isDark ? Colors.grey : Colors.grey[600])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.orange[800],
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text("DADOS GERAIS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                  controller: _nomeController,
                  onChanged: (_) => _marcarAlteracao(),
                  decoration: _estiloInput('Nome da Empresa', Icons.business)),
              const SizedBox(height: 10),
              TextField(
                  controller: _cnpjController,
                  onChanged: (_) => _marcarAlteracao(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CpfOuCnpjFormatter(),
                  ],
                  keyboardType: TextInputType.number,
                  decoration: _estiloInput('CNPJ / CPF', Icons.badge)),
              const SizedBox(height: 10),
              TextField(
                  controller: _telController,
                  onChanged: (_) => _marcarAlteracao(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TelefoneInputFormatter(),
                  ],
                  keyboardType: TextInputType.phone,
                  decoration: _estiloInput('Telefone', Icons.phone)),
              const SizedBox(height: 10),
              TextField(
                  controller: _enderecoController,
                  onChanged: (_) => _marcarAlteracao(),
                  decoration:
                      _estiloInput('Endereço Completo', Icons.location_on)),
              const SizedBox(height: 30),
              Divider(color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 10),
              Text("FINANCEIRO",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _diaFechamento,
                      decoration:
                          _estiloInput('Dia Fechamento', Icons.calendar_today),
                      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                      items: List.generate(31, (index) => index + 1).map((dia) {
                        return DropdownMenuItem(
                            value: dia, child: Text("Dia $dia"));
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _diaFechamento = v!);
                        _marcarAlteracao();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _validadeSelecionada,
                      decoration: _estiloInput('Validade (Dias)', Icons.timer),
                      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 7, child: Text("7 Dias")),
                        DropdownMenuItem(value: 15, child: Text("15 Dias")),
                        DropdownMenuItem(value: 30, child: Text("30 Dias")),
                        DropdownMenuItem(value: 60, child: Text("60 Dias")),
                      ],
                      onChanged: (v) {
                        setState(() => _validadeSelecionada = v!);
                        _marcarAlteracao();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                "O ciclo financeiro começa no dia selecionado.",
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 10),
              Text("APARÊNCIA DO APP E PDF",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontSize: 12)),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildTemaCard('Modo Claro', Icons.wb_sunny_rounded, 'Claro',
                      Colors.orange),
                  const SizedBox(width: 15),
                  _buildTemaCard('Modo Escuro', Icons.nightlight_round,
                      'Escuro', Colors.purpleAccent),
                ],
              ),
              const SizedBox(height: 25),
              Text("Cor Destaque do PDF",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: headerColor)),
              const SizedBox(height: 15),
              Center(
                child: Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: _opcoesCores.entries.map((entry) {
                    return _buildCorLed(
                        entry.value, entry.value.value.toString());
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.orangeAccent : Colors.orange[800],
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 5),
                  child: const Text("SALVAR CONFIGURAÇÕES",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
