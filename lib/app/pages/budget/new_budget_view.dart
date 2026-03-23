import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:orca_sim/app/pages/budget/new_budget_controller.dart';
import 'package:orca_sim/app/pages/pdf_preview/pdf_preview_view.dart';
import 'package:orca_sim/app/widgets/item_orcamento_modal.dart';
import 'package:orca_sim/injection.dart';

class NewBudgetView extends StatefulWidget {
  const NewBudgetView({
    super.key,
    this.orcamentoId,
    this.dadosExistentes,
  });

  final String? orcamentoId;
  final Map<String, dynamic>? dadosExistentes;

  @override
  State<NewBudgetView> createState() => _NewBudgetViewState();
}

class _NewBudgetViewState extends State<NewBudgetView> {
  final NewBudgetController _controller = getIt<NewBudgetController>();

  @override
  void initState() {
    super.initState();
    _controller.inicializarFormulario(widget.dadosExistentes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _totalGeral =>
      _controller.calcularTotalGeral(_controller.itens.value);

  Color _getCorDestaque(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _controller.corDestaque(isDark);
  }

  Color _getCorIcone(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _controller.corIcone(isDark);
  }

  InputDecoration _estiloInput(String label, IconData icone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: _getCorIcone(context)),
      filled: true,
      fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle:
          TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
    );
  }

  void _confirmarExclusaoItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover item?'),
        content: const Text('Deseja realmente remover este item da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final (itensAtualizados, produtoKeysAtualizados) =
                  _controller.removerItemPorIndice(
                itens: _controller.itens.value,
                produtoKeys: _controller.produtoKeys.value,
                index: index,
              );
              _controller.itens.value = itensAtualizados;
              _controller.produtoKeys.value = produtoKeysAtualizados;
              Navigator.pop(context);
            },
            child: const Text('REMOVER', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirModalItem({int? index}) async {
    final itemAtual = (index != null) ? _controller.itens.value[index] : null;
    final produtoKeyAtual =
        index != null ? _controller.produtoKeys.value[index] : null;

    final resultado = await showItemOrcamentoModal(
      context: context,
      inputDecorationBuilder: _estiloInput,
      destaqueColor: _getCorDestaque(context),
      actionForegroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      itemAtual: itemAtual,
      produtoKeyAtual: produtoKeyAtual,
      buscarSugestoesProduto: (query) =>
          _controller.buscarSugestoesProduto(query),
      obterPrecoProduto: _controller.obterPrecoProduto,
    );

    if (resultado == null || resultado.isEmpty) {
      return;
    }

    var itensAtuais = _controller.itens.value;
    var produtoKeysAtuais = _controller.produtoKeys.value;

    if (index != null) {
      final (item, produtoKey) = resultado.first;
      final (itensAtualizados, produtoKeysAtualizados) =
          _controller.aplicarResultadoModal(
        itens: itensAtuais,
        produtoKeys: produtoKeysAtuais,
        item: item,
        produtoKey: produtoKey,
        index: index,
      );
      _controller.itens.value = itensAtualizados;
      _controller.produtoKeys.value = produtoKeysAtualizados;
      return;
    }

    for (final (item, produtoKey) in resultado) {
      final (itensAtualizados, produtoKeysAtualizados) =
          _controller.aplicarResultadoModal(
        itens: itensAtuais,
        produtoKeys: produtoKeysAtuais,
        item: item,
        produtoKey: produtoKey,
      );
      itensAtuais = itensAtualizados;
      produtoKeysAtuais = produtoKeysAtualizados;
    }

    _controller.itens.value = itensAtuais;
    _controller.produtoKeys.value = produtoKeysAtuais;
  }

  Future<void> _salvarEVisualizar() async {
    if (!_controller
        .validarClienteNome(_controller.clienteNomeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o nome do cliente!')),
      );
      return;
    }

    _controller.gerandoPdf.value = true;

    final itensAtuais = _controller.itens.value;
    final produtoKeysAtuais = _controller.produtoKeys.value;
    final listaParaSalvar = _controller.montarListaParaSalvar(
      itens: itensAtuais,
      produtoKeys: produtoKeysAtuais,
    );

    await _controller.salvarOrcamento(
      docId: widget.orcamentoId,
      clienteNome: _controller.clienteNomeController.text,
      clienteCpfCnpj: _controller.clienteCpfCnpjController.text,
      nomeObra: _controller.nomeObraController.text,
      observacoes: _controller.obsController.text,
      total: _totalGeral,
      itens: listaParaSalvar,
    );

    final bytes = await _controller.gerarPdfOrcamento(
      clienteNome: _controller.clienteNomeController.text,
      clienteCpfCnpj: _controller.clienteCpfCnpjController.text,
      nomeObra: _controller.nomeObraController.text,
      observacoes: _controller.obsController.text,
      itens: itensAtuais,
    );

    if (!mounted) {
      return;
    }
    _controller.gerandoPdf.value = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewView(
          pdfBytes: bytes,
          nomeArquivo:
              'Orcamento_${_controller.clienteNomeController.text}.pdf',
        ),
      ),
    );
  }

  Widget _buildFormularioPrincipal(NumberFormat formatadorMoeda) {
    final corIcone = _getCorIcone(context);
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsetsBottom),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. DADOS DO CLIENTE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller.clienteNomeController,
            decoration: _estiloInput('Nome do Cliente', Icons.person),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _controller.clienteCpfCnpjController,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CpfOuCnpjFormatter(),
            ],
            keyboardType: TextInputType.number,
            decoration: _estiloInput('CPF ou CNPJ', Icons.badge),
          ),
          const SizedBox(height: 25),
          const Text(
            '2. DADOS DA OBRA / PROJETO',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller.nomeObraController,
            decoration: _estiloInput(
              'Nome da Obra (Ex: Reforma Cozinha)',
              Icons.construction,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '3. ITENS DO SERVICO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              TextButton.icon(
                onPressed: () => _abrirModalItem(),
                icon: Icon(Icons.add_circle_outline, color: corIcone),
                label:
                    Text('Adicionar Item', style: TextStyle(color: corIcone)),
              ),
            ],
          ),
          _buildListaItens(formatadorMoeda),
          const SizedBox(height: 25),
          const Text(
            '4. OBSERVACOES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller.obsController,
            maxLines: 3,
            decoration: _estiloInput(
              'Condicoes de Pagamento, Prazos, etc.',
              Icons.notes,
            ).copyWith(alignLabelWithHint: true),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildListaItens(NumberFormat formatadorMoeda) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_controller.itens.value.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'Nenhum item adicionado ainda.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _controller.itens.value.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _controller.itens.value[index];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
            border: isDark ? null : Border.all(color: Colors.grey[300]!),
          ),
          child: ListTile(
            onTap: () => _abrirModalItem(index: index),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.unidade,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            title: Text(
              item.descricao,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.quantidade} x ${formatadorMoeda.format(item.valorUnitario)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatadorMoeda.format(item.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getCorDestaque(context),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: () => _confirmarExclusaoItem(index),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRodape(NumberFormat formatadorMoeda) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corBotaoDestaque = _getCorDestaque(context);
    final corTextoBotao = isDark ? Colors.black : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL ESTIMADO:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                formatadorMoeda.format(_totalGeral),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getCorDestaque(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _controller.itens.value.isEmpty ||
                      _controller.gerandoPdf.value
                  ? null
                  : _salvarEVisualizar,
              icon: _controller.gerandoPdf.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: corTextoBotao,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.picture_as_pdf, color: corTextoBotao),
              label: Text(
                _controller.gerandoPdf.value
                    ? 'PROCESSANDO...'
                    : 'SALVAR E VISUALIZAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: corTextoBotao,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: corBotaoDestaque,
                foregroundColor: corTextoBotao,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller.itens,
        _controller.produtoKeys,
        _controller.gerandoPdf,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.orcamentoId != null
                  ? 'Editar Orcamento'
                  : 'Novo Orcamento',
            ),
          ),
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              Expanded(
                child: _buildFormularioPrincipal(formatadorMoeda),
              ),
              _buildRodape(formatadorMoeda),
            ],
          ),
        );
      },
    );
  }
}
