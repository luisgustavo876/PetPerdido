import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../models/notificacao_model.dart';
import '../models/post_model.dart';
import 'auth_service.dart';

/// Preferências de alerta do usuário (users/{uid}).
class PreferenciasAlerta {
  /// null = ainda não respondeu ao aviso de LGPD dos alertas.
  final bool? ativo;
  final int raioKm;

  const PreferenciasAlerta({this.ativo, this.raioKm = AppConstants.alertRadiusPadraoKm});
}

/// Dados do usuário logado em users/{uid} e subcoleções.
class UserService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>? get _meuDoc {
    final uid = AuthService.currentUser?.uid;
    return uid == null ? null : _db.collection('users').doc(uid);
  }

  // ---------------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------------

  /// IDs dos posts favoritados (leitura única).
  static Future<Set<String>> favoritos() async {
    final doc = _meuDoc;
    if (doc == null) return {};
    final snap = await doc.get();
    return Set<String>.from(snap.data()?['favorites'] as List? ?? const []);
  }

  /// Favorita ou desfavorita um post (arrayUnion / arrayRemove).
  static Future<void> definirFavorito(String postId, bool favorito) async {
    final doc = _meuDoc;
    if (doc == null) return;
    await doc.set({
      'favorites': favorito
          ? FieldValue.arrayUnion([postId])
          : FieldValue.arrayRemove([postId]),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Alertas por proximidade
  // ---------------------------------------------------------------------------

  static Future<PreferenciasAlerta> preferenciasAlerta() async {
    final doc = _meuDoc;
    if (doc == null) return const PreferenciasAlerta(ativo: false);
    final dados = (await doc.get()).data() ?? const {};
    return PreferenciasAlerta(
      ativo: dados['alertsEnabled'] as bool?,
      raioKm: (dados['alertRadiusKm'] as num?)?.toInt() ??
          AppConstants.alertRadiusPadraoKm,
    );
  }

  static Future<void> definirAlertas({bool? ativo, int? raioKm}) async {
    final doc = _meuDoc;
    if (doc == null) return;
    await doc.set({
      if (ativo != null) 'alertsEnabled': ativo,
      if (raioKm != null) 'alertRadiusKm': raioKm,
    }, SetOptions(merge: true));
  }

  /// Última localização conhecida, já arredondada, com geohash.
  /// Usada só pela Cloud Function dos alertas (não aparece para ninguém).
  static Future<void> salvarLocalizacao(double lat, double lng) async {
    final doc = _meuDoc;
    if (doc == null) return;
    await doc.set({
      'lastLocation': {
        'lat': lat,
        'lng': lng,
        'geohash': PostModel.calcularGeohash(lat, lng),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  /// Token do aparelho para o push (null apaga, ex.: ao sair da conta).
  static Future<void> salvarToken(String? token) async {
    final doc = _meuDoc;
    if (doc == null) return;
    await doc.set({
      'fcmToken': token ?? FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Notificações (users/{uid}/notifications)
  // ---------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>>? get _notificacoes =>
      _meuDoc?.collection('notifications');

  /// Últimas 50 notificações, mais recentes primeiro.
  static Stream<List<NotificacaoModel>> notificacoesStream() {
    final col = _notificacoes;
    if (col == null) return Stream.value(const []);
    return col
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs) NotificacaoModel.fromMap(d.id, d.data()),
            ]);
  }

  static Future<void> marcarLida(String id) async {
    await _notificacoes?.doc(id).update({'read': true});
  }

  static Future<void> marcarTodasLidas(Iterable<String> ids) async {
    final col = _notificacoes;
    if (col == null || ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(col.doc(id), {'read': true});
    }
    await batch.commit();
  }
}
