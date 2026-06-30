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
