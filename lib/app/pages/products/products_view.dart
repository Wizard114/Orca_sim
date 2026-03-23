import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orca_sim/app/pages/products/products_controller.dart';
import 'package:orca_sim/app/widgets/item_orcamento_modal.dart';
import 'package:orca_sim/injection.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final ProductsController _controller = getIt<ProductsController>();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle:
          TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
    );
  }

  Future<void> _carregarProdutos({String? query}) async {
    await _controller.carregarProdutosState(query: query);
  }

  Future<void> _abrirModalProduto({Map<String, dynamic>? produto}) async {
    final itemAtual =
        produto != null ? _controller.produtoParaItem(produto) : null;
    final resultado = await showItemOrcamentoModal(
      context: context,
      inputDecorationBuilder: _estiloInput,
      destaqueColor: _getCorDestaque(context),
      actionForegroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      itemAtual: itemAtual,
      produtoKeyAtual: produto?['nome_normalizado']?.toString(),
      buscarSugestoesProduto: (query) =>
          _controller.buscarSugestoesProduto(query),
      obterPrecoProduto: _controller.obterPrecoProduto,
      enableSuggestions: false,
    );

    if (resultado == null || resultado.isEmpty) {
      return;
    }

    for (final (item, produtoKey) in resultado) {
      await _controller.salvarProduto(
        nome: item.descricao,
        unidade: item.unidade,
        preco: item.valorUnitario,
        produtoKey: produtoKey,
      );
    }

    await _carregarProdutos(
      query: _controller.normalizarBusca(_controller.buscaController.text),
    );
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> produto) async {
    final nome = _controller.produtoNome(produto);
    final key = _controller.produtoKey(produto);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('Deseja remover "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmou != true || !_controller.podeExcluirProduto(key)) {
      return;
    }

    await _controller.deletarProduto(key);
    await _carregarProdutos(
      query: _controller.normalizarBusca(_controller.buscaController.text),
    );
  }

  Widget _buildListaProdutos(NumberFormat formatadorMoeda) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_controller.carregando.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.produtos.value.isEmpty) {
      return Center(
        child: Text(
          'Nenhum produto cadastrado.',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.produtos.value.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final produto = _controller.produtos.value[index];
        final nome = _controller.produtoNome(produto);
        final unidade = _controller.produtoUnidade(produto);
        final usageCount = _controller.produtoUsageCount(produto).toString();
        final preco = _controller.obterPrecoProduto(produto);

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
            onTap: () => _abrirModalProduto(produto: produto),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unidade,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            title: Text(
              nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Usado em $usageCount orcamentos'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatadorMoeda.format(preco),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getCorDestaque(context),
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmarExclusao(produto),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatadorMoeda =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AnimatedBuilder(
      animation:
          Listenable.merge([_controller.produtos, _controller.carregando]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Meus Produtos')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _controller.buscaController,
                  decoration:
                      _estiloInput('Buscar produto', Icons.search).copyWith(
                    suffixIcon: _controller.buscaController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.limparBusca(
                                  onSearch: _carregarProdutos,);
                            },
                          ),
                  ),
                  onChanged: (value) {
                    _controller.buscarComDebounce(
                      value: value,
                      onSearch: _carregarProdutos,
                    );
                  },
                ),
              ),
              Expanded(child: _buildListaProdutos(formatadorMoeda)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _abrirModalProduto,
            icon: const Icon(Icons.add),
            label: const Text('Novo Produto'),
          ),
        );
      },
    );
  }
}
