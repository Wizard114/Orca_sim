import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orca_sim/app/pages/company/company_controller.dart';
import 'package:orca_sim/injection.dart';
import 'package:orca_sim/main.dart';

class CompanyView extends StatefulWidget {
  const CompanyView({super.key});

  @override
  State<CompanyView> createState() => _CompanyViewState();
}

class _CompanyViewState extends State<CompanyView> {
  final CompanyController _controller = getIt<CompanyController>();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final dados = await _controller.carregarDados();
    if (dados == null || !mounted) {
      return;
    }

    _controller.inicializarFormulario(dados);
    _controller.notificarUi();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selecionarLogo() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _controller.logoImage = _controller.logoValido(pickedFile.path);
      _controller.notificarUi();
    }
  }

  Future<void> _salvar() async {
    if (!_controller.nomeEmpresaValido(_controller.nomeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da empresa e obrigatorio!')),
      );
      return;
    }

    themeNotifier.value =
        _controller.themeModeFromTema(_controller.temaSelecionado);

    var caminhoFinalLogo = _controller.logoPathSalvo;
    if (_controller.logoImage != null &&
        _controller.logoImage!.path != _controller.logoPathSalvo) {
      caminhoFinalLogo =
          await _controller.salvarImagemLocalmente(_controller.logoImage!);
    }

    await _controller.salvarDadosEmpresa(
      nome: _controller.nomeController.text,
      cnpj: _controller.cnpjController.text,
      telefone: _controller.telController.text,
      endereco: _controller.enderecoController.text,
      logoPath: caminhoFinalLogo,
      validadeOrcamento: _controller.validadeSelecionada,
      temaApp: _controller.temaSelecionado,
      corPdf: _controller.corPdfSelecionada,
      diaFechamento: _controller.diaFechamento,
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuracoes salvas!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildLogoPicker(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _selecionarLogo,
        child: CircleAvatar(
          radius: 55,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          backgroundImage: _controller.logoImage != null
              ? FileImage(_controller.logoImage!)
              : null,
          child: _controller.logoImage == null
              ? Icon(
                  Icons.add_a_photo,
                  size: 40,
                  color: isDark ? Colors.grey : Colors.grey[600],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCampos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller.nomeController,
          decoration: _estiloInput('Nome da Empresa', Icons.business),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller.cnpjController,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CpfOuCnpjFormatter(),
          ],
          keyboardType: TextInputType.number,
          decoration: _estiloInput('CNPJ / CPF', Icons.badge),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller.telController,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            TelefoneInputFormatter(),
          ],
          keyboardType: TextInputType.phone,
          decoration: _estiloInput('Telefone', Icons.phone),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller.enderecoController,
          decoration: _estiloInput('Endereco Completo', Icons.location_on),
        ),
      ],
    );
  }

  Widget _buildConfiguracoes() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          initialValue: _controller.diaFechamento,
          decoration: _estiloInput('Dia Fechamento', Icons.calendar_today),
          items: List.generate(31, (index) => index + 1)
              .map(
                (dia) => DropdownMenuItem(value: dia, child: Text('Dia $dia')),
              )
              .toList(),
          onChanged: (v) {
            _controller.diaFechamento = v ?? 1;
            _controller.notificarUi();
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: _controller.validadeSelecionada,
          decoration: _estiloInput('Validade (Dias)', Icons.timer),
          items: const [
            DropdownMenuItem(value: 7, child: Text('7 Dias')),
            DropdownMenuItem(value: 15, child: Text('15 Dias')),
            DropdownMenuItem(value: 30, child: Text('30 Dias')),
            DropdownMenuItem(value: 60, child: Text('60 Dias')),
          ],
          onChanged: (v) {
            _controller.validadeSelecionada = v ?? 15;
            _controller.notificarUi();
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _controller.temaSelecionado,
          decoration: _estiloInput('Tema', Icons.palette),
          items: const [
            DropdownMenuItem(value: 'Claro', child: Text('Modo Claro')),
            DropdownMenuItem(value: 'Escuro', child: Text('Modo Escuro')),
            DropdownMenuItem(value: 'Sistema', child: Text('Usar Sistema')),
          ],
          onChanged: (v) {
            _controller.temaSelecionado = _controller.temaComFallback(v);
            _controller.notificarUi();
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _controller.corPdfSelecionada,
          decoration: _estiloInput('Cor PDF', Icons.picture_as_pdf),
          items: const [
            DropdownMenuItem(value: '0xFF448AFF', child: Text('Azul')),
            DropdownMenuItem(value: '4278255360', child: Text('Verde')),
            DropdownMenuItem(value: '4294198070', child: Text('Vermelho')),
            DropdownMenuItem(value: '4294944000', child: Text('Laranja')),
            DropdownMenuItem(value: '4288423856', child: Text('Roxo')),
          ],
          onChanged: (v) {
            _controller.corPdfSelecionada = v ?? '0xFF448AFF';
            _controller.notificarUi();
          },
        ),
      ],
    );
  }

  Widget _buildSalvarButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _salvar,
        child: const Text('SALVAR CONFIGURACOES'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _controller.uiTick,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(title: const Text('Minha Empresa')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoPicker(isDark),
                const SizedBox(height: 24),
                _buildCampos(),
                const SizedBox(height: 16),
                _buildConfiguracoes(),
                const SizedBox(height: 24),
                _buildSalvarButton(),
              ],
            ),
          ),
        );
      },
    );
  }
}
