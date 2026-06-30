import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orca_sim/domain/services/firestore_service.dart';

class FirestoreService implements IFirestoreService {
  FirestoreService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Map<String, Map<String, dynamic>> _produtosCache = {};
  String? _cachedUid;
  String? _cachedCnpjNormalizado;
  static const _maxOrcamentosNoStream = 120;

  static const _acentos = {
    'a': 'a',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'e': 'e',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'i': 'i',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'o': 'o',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'u': 'u',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'c': 'c',
    'ç': 'c',
  };

  String _normalizarCnpj(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _removerAcentos(String value) {
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_acentos[char] ?? char);
    }
    return buffer.toString();
  }

  String _normalizarNomeProduto(String nome) {
    var valor = _removerAcentos(nome.trim().toLowerCase());
    valor = valor.replaceAll(RegExp(r'\s+'), ' ');
    valor = valor.replaceAll(' ', '_');
    valor = valor.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return valor;
  }

  int _usageCountFrom(Map<String, dynamic> item) {
    final raw = item['usage_count'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return 0;
  }

  DateTime _updatedAtFrom(Map<String, dynamic> item) {
    final raw = item['updated_at'];
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<String?> _resolverCnpjNormalizado() async {
    final user = _auth.currentUser;
    if (user == null) {
      _cachedUid = null;
      _cachedCnpjNormalizado = null;
      return null;
    }

    if (_cachedUid == user.uid && _cachedCnpjNormalizado != null) {
      return _cachedCnpjNormalizado;
    }

    final userRef = _db.collection('usuarios').doc(user.uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      _cachedUid = user.uid;
      _cachedCnpjNormalizado = null;
      return null;
    }

    final data = userDoc.data();
    if (data == null) {
      return null;
    }

    final fromNormalized = (data['cnpj_normalizado'] ?? '').toString();
    final normalized = _normalizarCnpj(fromNormalized);
    if (normalized.length == 14) {
      _cachedUid = user.uid;
      _cachedCnpjNormalizado = normalized;
      return normalized;
    }

    final fromCnpj = (data['cnpj'] ?? '').toString();
    final normalizedFromCnpj = _normalizarCnpj(fromCnpj);
    if (normalizedFromCnpj.length == 14) {
      await userRef.set(
        {
          'cnpj_normalizado': normalizedFromCnpj,
        },
        SetOptions(merge: true),
      );
      _cachedUid = user.uid;
      _cachedCnpjNormalizado = normalizedFromCnpj;
      return normalizedFromCnpj;
    }

    _cachedUid = user.uid;
    _cachedCnpjNormalizado = null;

    return null;
  }

  Future<CollectionReference<Map<String, dynamic>>?>
      _colecaoProdutosEmpresa() async {
    final empresaDoc = await _documentoEmpresa();
    if (empresaDoc == null) {
      return null;
    }

    return empresaDoc.collection('produtos');
  }

  Future<DocumentReference<Map<String, dynamic>>?> _documentoEmpresa() async {
    final cnpjNormalizado = await _resolverCnpjNormalizado();
    if (cnpjNormalizado == null || cnpjNormalizado.length != 14) {
      return null;
    }

    return _db.collection('empresas').doc(cnpjNormalizado);
  }

  Future<CollectionReference<Map<String, dynamic>>?>
      _colecaoOrcamentosEmpresa() async {
    final empresaDoc = await _documentoEmpresa();
    if (empresaDoc == null) {
      return null;
    }

    return empresaDoc.collection('orcamentos');
  }

  @override
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
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final cnpjNormalizado = _normalizarCnpj(cnpj);

    await _db.collection('usuarios').doc(user.uid).set(
      {
        'email': user.email,
        'cnpj': cnpj,
        'cnpj_normalizado': cnpjNormalizado,
        'ultima_sessao': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (cnpjNormalizado.length != 14) {
      return;
    }

    await _db.collection('empresas').doc(cnpjNormalizado).set(
      {
        'cnpj': cnpj,
        'cnpj_normalizado': cnpjNormalizado,
        'nome_empresa': nome,
        'telefone': telefone,
        'endereco': endereco,
        'logo_local_path': logoPath,
        'validade_orcamento': validadeOrcamento,
        'tema_app': temaApp,
        'cor_pdf': corPdf,
        'dia_fechamento': diaFechamento,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<Map<String, dynamic>?> pegarDadosEmpresa() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final empresaDocRef = await _documentoEmpresa();
    if (empresaDocRef != null) {
      final empresaDoc = await empresaDocRef.get();
      if (empresaDoc.exists) {
        return empresaDoc.data();
      }
    }

    // Fallback para documentos legados enquanto houver usuarios antigos.
    final legado = await _db.collection('usuarios').doc(user.uid).get();
    if (legado.exists) {
      return legado.data();
    }

    return null;
  }

  @override
  Future<void> salvarOrcamento({
    String? docId,
    required String clienteNome,
    required String clienteCpfCnpj,
    required String nomeObra,
    required double total,
    required String observacoes,
    required List<Map<String, dynamic>> itens,
  }) async {
    final collection = await _colecaoOrcamentosEmpresa();
    if (collection == null) {
      return;
    }

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
      await sincronizarProdutosAoSalvarOrcamento(itens);
      return;
    }

    if (!dados.containsKey('status')) {
      dados['status'] = 'Pendente';
    }
    await collection.add(dados);
    await sincronizarProdutosAoSalvarOrcamento(itens);
  }

  @override
  Future<void> atualizarStatusOrcamento(String docId, String novoStatus) async {
    final collection = await _colecaoOrcamentosEmpresa();
    if (collection == null) {
      return;
    }

    await collection.doc(docId).update({'status': novoStatus});
  }

  @override
  Stream<QuerySnapshot> streamOrcamentos() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    final dataLimite = DateTime.now().subtract(const Duration(days: 90));
    return Stream.fromFuture(_colecaoOrcamentosEmpresa()).asyncExpand((ref) {
      if (ref == null) {
        return const Stream.empty();
      }

      return ref
          .where('data', isGreaterThanOrEqualTo: dataLimite)
          .orderBy('data', descending: true)
          .limit(_maxOrcamentosNoStream)
          .snapshots();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> pegarOrcamentosPorPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    final collection = await _colecaoOrcamentosEmpresa();
    if (collection == null) {
      return [];
    }

    final query = await collection
        .where('data', isGreaterThanOrEqualTo: inicio)
        .where('data', isLessThanOrEqualTo: fim)
        .where('status', isEqualTo: 'Aprovado')
        .orderBy('data', descending: true)
        .get();

    return query.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> deletarOrcamento(String docId) async {
    final collection = await _colecaoOrcamentosEmpresa();
    if (collection == null) {
      return;
    }

    await collection.doc(docId).delete();
  }

  @override
  Future<void> preloadProdutosEmpresa() async {
    final produtosRef = await _colecaoProdutosEmpresa();
    if (produtosRef == null) {
      _produtosCache.clear();
      return;
    }

    final snapshot = await produtosRef.get();
    _produtosCache.clear();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final key = (data['nome_normalizado'] ?? doc.id).toString();
      _produtosCache[key] = {
        ...data,
        'nome_normalizado': key,
      };
    }
  }

  @override
  List<Map<String, dynamic>> topProdutosEmpresa({
    String? query,
    int limit = 10,
  }) {
    final q = (query ?? '').trim();
    final qNormalizado = q.isEmpty ? '' : _normalizarNomeProduto(q);

    var lista = _produtosCache.values.toList();
    if (qNormalizado.isNotEmpty) {
      lista = lista.where((item) {
        final nome = (item['nome'] ?? '').toString().toLowerCase();
        final key = (item['nome_normalizado'] ?? '').toString();
        return nome.contains(q.toLowerCase()) || key.contains(qNormalizado);
      }).toList();
    }

    lista.sort((a, b) {
      final usageCmp = _usageCountFrom(b).compareTo(_usageCountFrom(a));
      if (usageCmp != 0) {
        return usageCmp;
      }
      return _updatedAtFrom(b).compareTo(_updatedAtFrom(a));
    });

    final safeLimit = limit <= 0 ? 10 : limit;
    return lista.take(safeLimit).map((item) => {...item}).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listarProdutosEmpresa({
    String? query,
  }) async {
    // Reuse local cache for query updates and frequent search input changes.
    if (_produtosCache.isNotEmpty) {
      return topProdutosEmpresa(query: query, limit: 10000);
    }

    final produtosRef = await _colecaoProdutosEmpresa();
    if (produtosRef == null) {
      _produtosCache.clear();
      return [];
    }

    final snapshot = await produtosRef.get();
    _produtosCache.clear();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final key = (data['nome_normalizado'] ?? doc.id).toString();
      _produtosCache[key] = {
        ...data,
        'nome_normalizado': key,
      };
    }

    return topProdutosEmpresa(query: query, limit: 10000);
  }

  @override
  Future<void> salvarProdutoEmpresa({
    required String nome,
    required String unidade,
    required double preco,
    String? produtoKey,
  }) async {
    final produtosRef = await _colecaoProdutosEmpresa();
    if (produtosRef == null) {
      return;
    }

    final nomeLimpo = nome.trim();
    if (nomeLimpo.isEmpty) {
      return;
    }

    final keyAtual = (produtoKey ?? '').trim();
    final keyFinal =
        keyAtual.isNotEmpty ? keyAtual : _normalizarNomeProduto(nomeLimpo);
    if (keyFinal.isEmpty) {
      return;
    }

    final precoCentavos = (preco * 100).round();
    await produtosRef.doc(keyFinal).set(
      {
        'nome': nomeLimpo,
        'nome_normalizado': keyFinal,
        'unidade': unidade,
        'preco_centavos': precoCentavos,
        'preco': preco,
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'usage_count': 0,
      },
      SetOptions(merge: true),
    );

    final existente = _produtosCache[keyFinal] ?? <String, dynamic>{};
    _produtosCache[keyFinal] = {
      ...existente,
      'nome': nomeLimpo,
      'nome_normalizado': keyFinal,
      'unidade': unidade,
      'preco_centavos': precoCentavos,
      'preco': preco,
      'usage_count': _usageCountFrom(existente),
      'updated_at': DateTime.now(),
      'created_at': existente['created_at'] is DateTime ||
              existente['created_at'] is Timestamp
          ? existente['created_at']
          : DateTime.now(),
    };
  }

  @override
  Future<void> deletarProdutoEmpresa(String produtoKey) async {
    final produtosRef = await _colecaoProdutosEmpresa();
    final key = produtoKey.trim();
    if (produtosRef == null || key.isEmpty) {
      return;
    }

    await produtosRef.doc(key).delete();
    _produtosCache.remove(key);
  }

  @override
  Future<void> sincronizarProdutosAoSalvarOrcamento(
    List<Map<String, dynamic>> itens,
  ) async {
    if (itens.isEmpty) {
      return;
    }

    final produtosRef = await _colecaoProdutosEmpresa();
    if (produtosRef == null) {
      return;
    }

    for (final item in itens) {
      final nome = (item['descricao'] ?? '').toString().trim();
      if (nome.isEmpty) {
        continue;
      }

      final nomeNormalizado = _normalizarNomeProduto(nome);
      if (nomeNormalizado.isEmpty) {
        continue;
      }

      final unidade = (item['unidade'] ?? 'un').toString();
      final valor = (item['valor'] is num)
          ? (item['valor'] as num).toDouble()
          : double.tryParse((item['valor'] ?? '0').toString()) ?? 0.0;
      final precoCentavos = (valor * 100).round();
      final produtoDoc = produtosRef.doc(nomeNormalizado);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(produtoDoc);
        if (snap.exists) {
          tx.update(produtoDoc, {
            'nome': nome,
            'nome_normalizado': nomeNormalizado,
            'unidade': unidade,
            'preco_centavos': precoCentavos,
            'preco': valor,
            'usage_count': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
          });
          return;
        }

        tx.set(produtoDoc, {
          'nome': nome,
          'nome_normalizado': nomeNormalizado,
          'unidade': unidade,
          'preco_centavos': precoCentavos,
          'preco': valor,
          'usage_count': 1,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });

      final existente = _produtosCache[nomeNormalizado] ?? <String, dynamic>{};
      _produtosCache[nomeNormalizado] = {
        ...existente,
        'nome': nome,
        'nome_normalizado': nomeNormalizado,
        'unidade': unidade,
        'preco_centavos': precoCentavos,
        'preco': valor,
        'usage_count': _usageCountFrom(existente) + 1,
        'updated_at': DateTime.now(),
        'created_at': existente['created_at'] is DateTime ||
                existente['created_at'] is Timestamp
            ? existente['created_at']
            : DateTime.now(),
      };
    }
  }
}
