import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- DADOS DA EMPRESA + CONFIGS ---
  Future<void> salvarDadosEmpresa({
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    String? logoPath,
    required int validadeOrcamento,
    required String temaApp,
    required String corPdf,
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
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> pegarDadosEmpresa() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    DocumentSnapshot doc = await _db.collection('usuarios').doc(user.uid).get();
    if (doc.exists) return doc.data() as Map<String, dynamic>;
    return null;
  }

  // --- ORÇAMENTOS ---
  Future<void> salvarOrcamento({
    String? docId,
    required String clienteNome,
    required String clienteTel,
    required double total,
    required String observacoes,
    required List<Map<String, dynamic>> itens,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final collection = _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('orcamentos');

    final dados = {
      'cliente_nome': clienteNome,
      'cliente_tel': clienteTel,
      'observacoes': observacoes,
      'data': DateTime.now(),
      'total': total,
      'itens': itens,
      // Se for novo, nasce como Pendente. Se for atualização, não mexe no status aqui (usa o atual ou mantem a lógica)
      'status': docId == null ? 'Pendente' : null,
    };

    // Remove campos nulos para não sobrescrever status existente com null na edição
    dados.removeWhere((key, value) => value == null);

    if (docId != null) {
      await collection.doc(docId).update(dados);
    } else {
      // Garante que novos tenham status
      if (!dados.containsKey('status')) dados['status'] = 'Pendente';
      await collection.add(dados);
    }
  }

  // NOVA FUNÇÃO: Mudar apenas o status (Aprovado/Recusado)
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

    DateTime dataLimite = DateTime.now().subtract(const Duration(days: 60));

    return _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('orcamentos')
        .where('data', isGreaterThanOrEqualTo: dataLimite)
        .orderBy('data', descending: true)
        .snapshots();
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
