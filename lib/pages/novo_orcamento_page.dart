import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:brasil_fields/brasil_fields.dart'; // MÁSCARA
import 'package:flutter/services.dart'; // MÁSCARA
import '../services/pdf_service.dart';
import '../services/firestore_service.dart';
import 'pdf_preview_page.dart';

class ItemOrcamento {
  String descricao;
  int quantidade;
  String unidade;
  double valorUnitario;

  ItemOrcamento({
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
  });

  double get total => quantidade * valorUnitario;
}

class NovoOrcamentoPage extends StatefulWidget {
  final String? orcamentoId;
  final Map<String, dynamic>? dadosExistentes;

  const NovoOrcamentoPage({super.key, this.orcamentoId, this.dadosExistentes});

  @override
  State<NovoOrcamentoPage> createState() => _NovoOrcamentoPageState();
}

class _NovoOrcamentoPageState extends State<NovoOrcamentoPage> {
  final _clienteNomeController = TextEditingController();
  final _clienteCpfCnpjController = TextEditingController();
  final _nomeObraController = TextEditingController();
  final _obsController = TextEditingController();
  final List<ItemOrcamento> _itens = [];
  bool _gerandoPdf = false;

  @override
  void initState() {
    super.initState();
    if (widget.dadosExistentes != null) {
      _clienteNomeController.text =
          widget.dadosExistentes!['cliente_nome'] ?? '';
      _clienteCpfCnpjController.text =
          widget.dadosExistentes!['cliente_cpf_cnpj'] ??
              widget.dadosExistentes!['cliente_tel'] ??
              '';
      _nomeObraController.text = widget.dadosExistentes!['nome_obra'] ?? '';
      _obsController.text = widget.dadosExistentes!['observacoes'] ?? '';

      var itensSalvos = widget.dadosExistentes!['itens'] as List<dynamic>;
      for (var item in itensSalvos) {
        _itens.add(ItemOrcamento(
          descricao: item['descricao'],
          quantidade: item['quantidade'],
          unidade: item['unidade'] ?? 'un',
          valorUnitario: (item['valor'] as num).toDouble(),
        ));
      }
    }
  }

  double get _totalGeral => _itens.fold(0, (soma, item) => soma + item.total);

  Color _getCorDestaque(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.greenAccent
        : Colors.green[800]!;
  }

  Color _getCorIcone(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.orangeAccent
        : Colors.orange[800]!;
  }

  InputDecoration _estiloInput(String label, IconData icone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: _getCorIcone(context)),
      filled: true,
      fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle:
          TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
    );
  }

  // DIALOGO DE CONFIRMAÇÃO DE EXCLUSÃO DE ITEM
  void _confirmarExclusaoItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover item?"),
        content: const Text("Deseja realmente remover este item da lista?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              setState(() {
                _itens.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("REMOVER", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _abrirModalItem({int? index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ItemOrcamento? itemAtual = (index != null) ? _itens[index] : null;

    TextEditingController descController =
        TextEditingController(text: itemAtual?.descricao ?? '');
    TextEditingController qtdController =
        TextEditingController(text: itemAtual?.quantidade.toString() ?? '1');
    TextEditingController valorController = TextEditingController(
        text: itemAtual?.valorUnitario.toStringAsFixed(2) ?? '0.00');

    List<String> unidades = [
      'un',
      'm',
      'm²',
      'm³',
      'kg',
      'L',
      'g',
      'sc',
      'dia',
      'h',
      'sem'
    ];
    String unidadeSelecionada = itemAtual?.unidade ?? 'un';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => StatefulBuilder(builder: (context, setStateModal) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              Text(index != null ? 'Editar Item' : 'Adicionar Item',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                  controller: descController,
                  decoration: _estiloInput('Descrição', Icons.description),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                        controller: qtdController,
                        decoration: _estiloInput('Qtd', Icons.numbers),
                        keyboardType: TextInputType.number,
                        onTap: () => qtdController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: qtdController.text.length)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                        value: unidadeSelecionada,
                        decoration: _estiloInput('Un.', Icons.scale),
                        dropdownColor:
                            isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        items: unidades
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) =>
                            setStateModal(() => unidadeSelecionada = v!)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                        controller: valorController,
                        decoration:
                            _estiloInput('Valor (R\$)', Icons.attach_money),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onTap: () => valorController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: valorController.text.length)),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 55,
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        String desc = descController.text;
                        int qtd = int.tryParse(qtdController.text) ?? 1;
                        double valor = double.tryParse(
                                valorController.text.replaceAll(',', '.')) ??
                            0.0;

                        if (desc.isNotEmpty) {
                          setState(() {
                            final novoItem = ItemOrcamento(
                                descricao: desc,
                                quantidade: qtd,
                                unidade: unidadeSelecionada,
                                valorUnitario: valor);
                            if (index != null)
                              _itens[index] = novoItem;
                            else
                              _itens.add(novoItem);
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: _getCorDestaque(context),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2),
                      child: Icon(index != null ? Icons.check : Icons.add,
                          size: 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _salvarEVisualizar() async {
    if (_clienteNomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha o nome do cliente!")));
      return;
    }
    setState(() => _gerandoPdf = true);

    List<Map<String, dynamic>> listaParaSalvar = _itens.map((item) {
      return {
        'descricao': item.descricao,
        'quantidade': item.quantidade,
        'unidade': item.unidade,
        'valor': item.valorUnitario
      };
    }).toList();

    await FirestoreService().salvarOrcamento(
      docId: widget.orcamentoId,
      clienteNome: _clienteNomeController.text,
      clienteCpfCnpj: _clienteCpfCnpjController.text,
      nomeObra: _nomeObraController.text,
      observacoes: _obsController.text,
      total: _totalGeral,
      itens: listaParaSalvar,
    );

    final bytes = await PdfService().gerarPdfOrcamentoBytes(
      clienteNome: _clienteNomeController.text,
      clienteCpfCnpj: _clienteCpfCnpjController.text,
      nomeObra: _nomeObraController.text,
      observacoes: _obsController.text,
      itens: _itens,
    );

    setState(() => _gerandoPdf = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfBytes: bytes,
            nomeArquivo: "Orcamento_${_clienteNomeController.text}.pdf",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final corBotaoDestaque = _getCorDestaque(context);
    final corTextoBotao = isDark ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.orcamentoId != null
              ? "Editar Orçamento"
              : "Novo Orçamento")),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. DADOS DO CLIENTE",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _clienteNomeController,
                      decoration:
                          _estiloInput('Nome do Cliente', Icons.person)),
                  const SizedBox(height: 15),
                  TextField(
                      controller: _clienteCpfCnpjController,
                      // MÁSCARA APLICADA AQUI (CPF ou CNPJ)
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CpfOuCnpjFormatter(),
                      ],
                      keyboardType: TextInputType.number,
                      decoration: _estiloInput('CPF ou CNPJ', Icons.badge)),
                  const SizedBox(height: 25),
                  const Text("2. DADOS DA OBRA / PROJETO",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _nomeObraController,
                      decoration: _estiloInput(
                          'Nome da Obra (Ex: Reforma Cozinha)',
                          Icons.construction),
                      textCapitalization: TextCapitalization.sentences),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("3. ITENS DO SERVIÇO",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey)),
                      TextButton.icon(
                          onPressed: () => _abrirModalItem(),
                          icon: Icon(Icons.add_circle_outline,
                              color: _getCorIcone(context)),
                          label: Text("Adicionar Item",
                              style: TextStyle(color: _getCorIcone(context))))
                    ],
                  ),
                  _itens.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Theme.of(context).cardColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3))),
                          child: const Text("Nenhum item adicionado ainda.",
                              style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _itens.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _itens[index];
                            return Container(
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? Theme.of(context).cardColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2))
                                  ],
                                  border: isDark
                                      ? null
                                      : Border.all(color: Colors.grey[300]!)),
                              child: ListTile(
                                onTap: () => _abrirModalItem(index: index),
                                leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.withOpacity(0.1)
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(item.unidade,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87))),
                                title: Text(item.descricao,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    "${item.quantidade} x ${formatadorMoeda.format(item.valorUnitario)}"),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(formatadorMoeda.format(item.total),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _getCorDestaque(context))),
                                      const SizedBox(width: 5),
                                      IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.redAccent,
                                              size: 20),
                                          // CHAMA O DIALOGO AQUI
                                          onPressed: () =>
                                              _confirmarExclusaoItem(index))
                                    ]),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 25),
                  const Text("4. OBSERVAÇÕES",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _obsController,
                      maxLines: 3,
                      decoration: _estiloInput(
                              'Condições de Pagamento, Prazos, etc.',
                              Icons.notes)
                          .copyWith(alignLabelWithHint: true)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ]),
            child: Column(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL ESTIMADO:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(formatadorMoeda.format(_totalGeral),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getCorDestaque(context)))
                    ]),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _itens.isEmpty || _gerandoPdf
                        ? null
                        : _salvarEVisualizar,
                    icon: _gerandoPdf
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: corTextoBotao, strokeWidth: 2))
                        : Icon(Icons.picture_as_pdf, color: corTextoBotao),
                    label: Text(
                        _gerandoPdf ? "PROCESSANDO..." : "SALVAR E VISUALIZAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: corTextoBotao)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: corBotaoDestaque,
                        foregroundColor: corTextoBotao,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
