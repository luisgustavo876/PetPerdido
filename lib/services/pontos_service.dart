import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../core/app_constants.dart';
import '../core/recompensas.dart';
import '../models/post_model.dart';
import 'auth_service.dart';

/// Lançamento do histórico de pontos (users/{uid}/pointsLog).
class LancamentoPontos {
  final String motivo;
  final int delta;
  final String? postId;
  final DateTime createdAt;

  const LancamentoPontos(
      {required this.motivo, required this.delta, this.postId, required this.createdAt});
}

/// Resgate feito (users/{uid}/redemptions).
class Resgate {
  final String id;
  final String rewardId;
  final String titulo;
  final int custo;
  final String codigo;
  final DateTime createdAt;

  const Resgate({
    required this.id,
    required this.rewardId,
    required this.titulo,
    required this.custo,
    required this.codigo,
    required this.createdAt,
  });
}

/// Saldo insuficiente ou outro problema no resgate (mensagem pronta).
class ResgateException implements Exception {
  final String mensagem;
  const ResgateException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Pontos e recompensas (users/{uid}.points + subcoleções).
///
/// Limitação conhecida: os pontos são gravados pelo próprio app. Num produto
/// real isso ficaria numa Cloud Function, para o usuário não conseguir se
/// dar pontos.
class PontosService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>? get _meuDoc {
    final uid = AuthService.currentUser?.uid;
    return uid == null ? null : _db.collection('users').doc(uid);
  }

  static DateTime _data(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();

  /// Saldo em tempo real.
  static Stream<int> saldoStream() {
    final doc = _meuDoc;
    if (doc == null) return Stream.value(0);
    return doc
        .snapshots()
        .map((s) => (s.data()?['points'] as num?)?.toInt() ?? 0);
  }

  /// Histórico (últimos 50 lançamentos).
  static Stream<List<LancamentoPontos>> historicoStream() {
    final doc = _meuDoc;
    if (doc == null) return Stream.value(const []);
    return doc
        .collection('pointsLog')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs)
                LancamentoPontos(
                  motivo: d.data()['reason'] as String? ?? '',
                  delta: (d.data()['delta'] as num?)?.toInt() ?? 0,
                  postId: d.data()['postId'] as String?,
                  createdAt: _data(d.data()['createdAt']),
                ),
            ]);
  }

  /// Meus resgates, mais recentes primeiro.
  static Stream<List<Resgate>> resgatesStream() {
    final doc = _meuDoc;
    if (doc == null) return Stream.value(const []);
    return doc
        .collection('redemptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs)
                Resgate(
                  id: d.id,
                  rewardId: d.data()['rewardId'] as String? ?? '',
                  titulo: d.data()['title'] as String? ?? '',
                  custo: (d.data()['cost'] as num?)?.toInt() ?? 0,
                  codigo: d.data()['code'] as String? ?? '',
                  createdAt: _data(d.data()['createdAt']),
                ),
            ]);
  }

  /// Pontos por publicar um post (Achei +30, Avistei +10, Perdi 0).
  static int pontosPorPost(PostType tipo) => switch (tipo) {
        PostType.found => AppConstants.pontosAchei,
        PostType.sighted => AppConstants.pontosAvistei,
        PostType.lost => 0,
      };

  /// Soma pontos em transação: atualiza o saldo e grava o lançamento.
  /// [chave] identifica o ganho (ex.: "euvi_" + id do post): se já existir, não
  /// soma de novo. Não lança erro (pontos não podem travar a ação principal).
  static Future<void> ganhar({
    required int delta,
    required String motivo,
    required String chave,
    String? postId,
  }) async {
    final doc = _meuDoc;
    if (doc == null || delta == 0) return;
    try {
      await _db.runTransaction((t) async {
        final log = doc.collection('pointsLog').doc(chave);
        if ((await t.get(log)).exists) return; // já ganhou por isso
        t.set(doc, {'points': FieldValue.increment(delta)}, SetOptions(merge: true));
        t.set(log, {
          'reason': motivo,
          'delta': delta,
          if (postId != null) 'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('PontosService: não somou pontos ($chave): $e');
    }
  }

  /// Ganho por publicar um post.
  static Future<void> ganharPorPost(PostModel post) => ganhar(
        delta: pontosPorPost(post.type),
        motivo: 'Publicou "${post.type.label}"',
        chave: 'post_${post.id}',
        postId: post.id,
      );

  /// Ganho por registrar "Eu vi este pet" (uma vez por post).
  static Future<void> ganharPorAvistamento(String postId) => ganhar(
        delta: AppConstants.pontosEuVi,
        motivo: 'Registrou um avistamento',
        chave: 'euvi_$postId',
        postId: postId,
      );

  /// Resgata uma recompensa: confere o saldo, debita e gera o código do
  /// voucher, tudo numa transação. Lança [ResgateException] se não der.
  static Future<Resgate> resgatar(Recompensa r) async {
    final doc = _meuDoc;
    if (doc == null) throw const ResgateException('Entre na sua conta.');
    final codigo = gerarCodigo(Random.secure());
    final resgateRef = doc.collection('redemptions').doc();

    try {
      await _db.runTransaction((t) async {
        final saldo =
            ((await t.get(doc)).data()?['points'] as num?)?.toInt() ?? 0;
        if (saldo < r.custo) {
          throw ResgateException(
              'Pontos insuficientes: faltam ${r.custo - saldo} pts.');
        }
        t.update(doc, {'points': FieldValue.increment(-r.custo)});
        t.set(resgateRef, {
          'rewardId': r.id,
          'title': r.titulo,
          'cost': r.custo,
          'code': codigo,
          'createdAt': FieldValue.serverTimestamp(),
        });
        t.set(doc.collection('pointsLog').doc('resgate_${resgateRef.id}'), {
          'reason': 'Resgatou "${r.titulo}"',
          'delta': -r.custo,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on ResgateException {
      rethrow;
    } catch (e) {
      debugPrint('PontosService: falha no resgate: $e');
      throw const ResgateException(
          'Não foi possível resgatar agora. Confira a internet e tente de novo.');
    }
    return Resgate(
      id: resgateRef.id,
      rewardId: r.id,
      titulo: r.titulo,
      custo: r.custo,
      codigo: codigo,
      createdAt: DateTime.now(),
    );
  }

  /// Código do voucher, ex.: "PET-7KQ2-M9XA" (sem letras que confundem,
  /// como O/0 e I/1). Função pura (recebe o gerador aleatório).
  static String gerarCodigo(Random aleatorio) {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String bloco() => List.generate(
        4, (_) => letras[aleatorio.nextInt(letras.length)]).join();
    return 'PET-${bloco()}-${bloco()}';
  }

  /// Nível pelo total de pontos: nome, início e fim da faixa. Função pura.
  static ({String nome, int minimo, int? proximo}) nivel(int pontos) {
    const niveis = [
      (nome: 'Vizinho atento', minimo: 0),
      (nome: 'Ajudante da rua', minimo: 50),
      (nome: 'Protetor do bairro', minimo: 150),
      (nome: 'Herói dos pets', minimo: 300),
    ];
    for (var i = niveis.length - 1; i >= 0; i--) {
      if (pontos >= niveis[i].minimo) {
        return (
          nome: niveis[i].nome,
          minimo: niveis[i].minimo,
          proximo: i + 1 < niveis.length ? niveis[i + 1].minimo : null,
        );
      }
    }
    return (nome: niveis.first.nome, minimo: 0, proximo: niveis[1].minimo);
  }
}
