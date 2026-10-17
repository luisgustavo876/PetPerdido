import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_constants.dart';
import '../core/filtro_palavroes.dart';
import '../models/chat_model.dart';
import '../models/post_model.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Erro do chat com mensagem pronta para o usuário.
class ChatException implements Exception {
  final String mensagem;
  const ChatException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Chat em tempo real entre quem publicou e quem quer ajudar.
class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final _chats = _db.collection('chats');

  static String? get _meuUid => AuthService.currentUser?.uid;

  /// Título curto da conversa: "Pipoca · Perdi meu Pet".
  static String tituloDoPost(PostModel post) {
    final nome = post.petName.isNotEmpty && post.petName != 'Sem nome'
        ? post.petName
        : post.species;
    return '$nome · ${post.type.label}';
  }

  /// Abre a conversa com o autor do post, criando se ainda não existir.
  static Future<ChatModel> abrirOuCriar(PostModel post) async {
    final eu = _meuUid;
    if (eu == null) throw const ChatException('Entre na sua conta.');
    if (post.userId == eu) {
      throw const ChatException('Este post é seu: não dá para conversar com você mesmo.');
    }

    final id = ChatModel.idPara(post.id, eu, post.userId);
    final ref = _chats.doc(id);
    final existente = await ref.get();
    if (existente.exists) return ChatModel.fromMap(id, existente.data()!);

    final participantes = [eu, post.userId]..sort(); // mesma ordem do id
    final dados = {
      'participants': participantes,
      'participantNames': {
        eu: AuthService.currentUserName,
        post.userId: post.userName,
      },
      'postId': post.id,
      'postTitle': tituloDoPost(post),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unread': {eu: 0, post.userId: 0},
    };
    await ref.set(dados);
    return ChatModel.fromMap(id, {...dados, 'lastMessageAt': null});
  }

  /// Minhas conversas, da mais recente para a mais antiga.
  /// (Ordena no app para não precisar de índice composto.)
  static Stream<List<ChatModel>> minhasConversas() {
    final eu = _meuUid;
    if (eu == null) return Stream.value(const []);
    return _chats.where('participants', arrayContains: eu).snapshots().map((snap) {
      final lista = [for (final d in snap.docs) ChatModel.fromMap(d.id, d.data())];
      lista.sort((a, b) => (b.lastMessageAt ?? DateTime.now())
          .compareTo(a.lastMessageAt ?? DateTime.now()));
      return lista;
    });
  }

  /// Mensagens visíveis (até 15 dias), da mais antiga para a mais nova.
  static Stream<List<MensagemModel>> mensagens(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) {
      final agora = DateTime.now();
      return [
        for (final d in snap.docs.reversed)
          if (visivel(MensagemModel.fromMap(d.id, d.data()).createdAt, agora))
            MensagemModel.fromMap(d.id, d.data()),
      ];
    });
  }

  /// A mensagem ainda vale (tem até [AppConstants.chatValidade])? Função pura.
  static bool visivel(DateTime criadaEm, DateTime agora) =>
      agora.difference(criadaEm) <= AppConstants.chatValidade;

  /// Envia texto (já com o filtro de palavrões).
  static Future<void> enviarTexto(ChatModel chat, String texto) async {
    final limpo = FiltroPalavroes.filtrar(texto.trim());
    if (limpo.isEmpty) return;
    await _gravar(chat, texto: limpo, previa: limpo);
  }

  /// Envia uma foto (Storage chats/{chatId}/, imagem até 5 MB).
  static Future<void> enviarFoto(ChatModel chat, XFile foto) async {
    final eu = _meuUid;
    if (eu == null) throw const ChatException('Entre na sua conta.');
    final msgRef = _chats.doc(chat.id).collection('messages').doc();
    final ref = FirebaseStorage.instance.ref('chats/${chat.id}/${msgRef.id}.jpg');
    await ref.putData(await StorageService.bytesParaEnvio(foto),
        SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _gravar(chat, fotoUrl: url, previa: '📷 Foto', msgRef: msgRef);
  }

  static Future<void> _gravar(
    ChatModel chat, {
    String texto = '',
    String? fotoUrl,
    required String previa,
    DocumentReference<Map<String, dynamic>>? msgRef,
  }) async {
    final eu = _meuUid;
    if (eu == null) throw const ChatException('Entre na sua conta.');
    final outro = chat.outro(eu);
    final ref = msgRef ?? _chats.doc(chat.id).collection('messages').doc();
    final batch = _db.batch()
      ..set(ref, {
        'senderId': eu,
        'text': texto,
        if (fotoUrl != null) 'photoUrl': fotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        // Política TTL do Firestore apaga depois desta data.
        'expireAt': Timestamp.fromDate(DateTime.now().add(AppConstants.chatValidade)),
      })
      ..update(_chats.doc(chat.id), {
        'lastMessage': previa.length > 80 ? '${previa.substring(0, 80)}…' : previa,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unread.$outro': FieldValue.increment(1),
      });
    await batch.commit();
  }

  /// Zera as não lidas desta conversa para mim.
  static Future<void> marcarComoLida(String chatId) async {
    final eu = _meuUid;
    if (eu == null) return;
    await _chats.doc(chatId).update({'unread.$eu': 0});
  }
}
