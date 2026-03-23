import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orca_sim/domain/entities/item_orcamento.dart';

typedef BuscarSugestoesProduto = List<Map<String, dynamic>> Function(
  String query,
);
typedef ObterPrecoProduto = double Function(Map<String, dynamic> produto);
typedef ItemOrcamentoResultado = (ItemOrcamento item, String? produtoKey);

Future<List<ItemOrcamentoResultado>?> showItemOrcamentoModal({
  required BuildContext context,
  required InputDecoration Function(String label, IconData icon)
      inputDecorationBuilder,
  required Color destaqueColor,
  required Color actionForegroundColor,
  ItemOrcamento? itemAtual,
  String? produtoKeyAtual,
  required BuscarSugestoesProduto buscarSugestoesProduto,
  required ObterPrecoProduto obterPrecoProduto,
  bool enableSuggestions = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final descController =
      TextEditingController(text: itemAtual?.descricao ?? '');
  final qtdController = TextEditingController(
    text: itemAtual?.quantidade.toString() ?? '1',
  );
  final valorController = TextEditingController(
    text: itemAtual?.valorUnitario.toStringAsFixed(2) ?? '0.00',
  );

  final unidades = [
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
    'sem',
  ];

  var unidadeSelecionada = itemAtual?.unidade ?? 'un';
  String? produtoKeySelecionado = produtoKeyAtual;
  final itensAdicionados = <ItemOrcamentoResultado>[];
  var sugestoes = enableSuggestions
      ? buscarSugestoesProduto(descController.text)
      : <Map<String, dynamic>>[];

  return showModalBottomSheet<List<ItemOrcamentoResultado>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setStateModal) {
        ItemOrcamentoResultado? montarResultado() {
          final desc = descController.text.trim();
          final qtd = int.tryParse(qtdController.text) ?? 1;
          final valor =
              double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;

          if (desc.isEmpty) {
            return null;
          }

          return (
            ItemOrcamento(
              descricao: desc,
              quantidade: qtd,
              unidade: unidadeSelecionada,
              valorUnitario: valor,
            ),
            produtoKeySelecionado,
          );
        }

        void limparCamposParaProximoItem() {
          setStateModal(() {
            descController.clear();
            qtdController.text = '1';
            valorController.text = '0.00';
            unidadeSelecionada = 'un';
            produtoKeySelecionado = null;
            sugestoes = const [];
          });
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 15,
          ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                itemAtual != null ? 'Editar Item' : 'Adicionar Item',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration:
                    inputDecorationBuilder('Descricao', Icons.description),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  if (!enableSuggestions) {
                    return;
                  }
                  setStateModal(() {
                    produtoKeySelecionado = null;
                    sugestoes = buscarSugestoesProduto(value);
                  });
                },
              ),
              enableSuggestions && sugestoes.isNotEmpty
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: Card(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: sugestoes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, sugIndex) {
                            final produto = sugestoes[sugIndex];
                            final nome = (produto['nome'] ?? '').toString();
                            final unidade =
                                (produto['unidade'] ?? 'un').toString();
                            final preco = obterPrecoProduto(produto);
                            return ListTile(
                              dense: true,
                              title: Text(nome),
                              subtitle: Text(
                                'Unidade: $unidade',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                NumberFormat.currency(
                                  locale: 'pt_BR',
                                  symbol: 'R\$',
                                ).format(preco),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              onTap: () {
                                setStateModal(() {
                                  descController.text = nome;
                                  unidadeSelecionada =
                                      unidades.contains(unidade)
                                          ? unidade
                                          : 'un';
                                  valorController.text =
                                      preco.toStringAsFixed(2);
                                  produtoKeySelecionado =
                                      produto['nome_normalizado']?.toString();
                                  sugestoes = const [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtdController,
                      keyboardType: TextInputType.number,
                      decoration: inputDecorationBuilder('Qtd', Icons.numbers),
                      onTap: () {
                        qtdController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: qtdController.text.length,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: unidadeSelecionada,
                      decoration: inputDecorationBuilder('Un.', Icons.scale),
                      dropdownColor:
                          isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      items: unidades
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setStateModal(() => unidadeSelecionada = v ?? 'un'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    inputDecorationBuilder('Valor (R\$)', Icons.attach_money),
                onTap: () {
                  valorController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: valorController.text.length,
                  );
                },
              ),
              const SizedBox(height: 12),
              itemAtual != null
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final resultado = montarResultado();
                          if (resultado == null) {
                            return;
                          }
                          Navigator.pop(context, [resultado]);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Salvar Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: destaqueColor,
                          foregroundColor: actionForegroundColor,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(context, itensAdicionados),
                            child: const Text('Finalizar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final resultado = montarResultado();
                                if (resultado == null) {
                                  return;
                                }

                                itensAdicionados.add(resultado);
                                limparCamposParaProximoItem();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: destaqueColor,
                                foregroundColor: actionForegroundColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ),
  );
}
