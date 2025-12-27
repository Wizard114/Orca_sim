import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('usuarios').doc(user.uid).set({
      'nome_empresa': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'endereco': endereco,
      'logo_local_path': logoPath,
      'validade_orcamento': validadeOrcamento,
      'tema_app': temaApp,
      'cor_pdf': corPdf,
      'dia_fechamento': diaFechamento,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> pegarDadosEmpresa() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    DocumentSnapshot doc = await _db.collection('usuarios').doc(user.uid).get();
    if (doc.exists) return doc.data() as Map<String, dynamic>;
    return null;
  }

  Future<void> salvarOrcamento({
    String? docId,
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required double total,
    required String observacoes,
    required List<Map<String, dynamic>> itens,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final collection =
        _db.collection('usuarios').doc(user.uid).collection('orcamentos');

    final dados = {
      'cliente_nome': clienteNome,
      'cliente_cpf_cnpj': clienteCpfCnpj,
      'nome_obra': nomeObra,
      'observacoes': observacoes,
      'data': DateTime.now(),
      'total': total,
      'itens': itens,
      'status': docId == null ? 'Pendente' : null,
    };
    dados.removeWhere((key, value) => value == null);

    if (docId != null) {
      await collection.doc(docId).update(dados);
    } else {
      if (!dados.containsKey('status')) dados['status'] = 'Pendente';
      await collection.add(dados);
    }
  }

  Future<void> atualizarStatusOrcamento(String docId, String novoStatus) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('orcamentos')
        .doc(docId)
        .update({'status': novoStatus});
  }

  Stream<QuerySnapshot> streamOrcamentos() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    DateTime dataLimite = DateTime.now().subtract(const Duration(days: 90));
    return _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('orcamentos')
        .where('data', isGreaterThanOrEqualTo: dataLimite)
        .orderBy('data', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> pegarOrcamentosPorPeriodo(
      DateTime inicio, DateTime fim) async {
    User? user = _auth.currentUser;
    if (user == null) return [];
    QuerySnapshot query = await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('orcamentos')
        .where('data', isGreaterThanOrEqualTo: inicio)
        .where('data', isLessThanOrEqualTo: fim)
        .where('status', isEqualTo: 'Aprovado')
        .orderBy('data', descending: true)
        .get();
    return query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> deletarOrcamento(String docId) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('orcamentos')
        .doc(docId)
        .delete();
  }
}
