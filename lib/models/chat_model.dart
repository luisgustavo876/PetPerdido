import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversa entre duas pessoas sobre um post (chats/{chatId}).
///
/// O chat só guarda os NOMES dos participantes: nada de e-mail, CPF ou
/// localização de ninguém.
class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String postId;
  final String postTitle;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unread;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.postId,
    required this.postTitle,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unread = const {},
  });

  /// Id determinístico: o mesmo post e as mesmas duas pessoas sempre caem
  /// na mesma conversa. Os uids vão em ordem alfabética. Função pura.
  static String idPara(String postId, String uidA, String uidB) {
    final uids = [uidA, uidB]..sort();
    return '${postId}_${uids[0]}_${uids[1]}';
  }

  /// Uid da outra pessoa da conversa.
  String outro(String meuUid) =>
      participants.firstWhere((p) => p != meuUid, orElse: () => meuUid);

  String nomeDoOutro(String meuUid) => participantNames[outro(meuUid)] ?? 'Usuário';

  int naoLidas(String meuUid) => unread[meuUid] ?? 0;

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    final ultima = map['lastMessageAt'];
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] as List? ?? const []),
      participantNames: Map<String, String>.from(
          (map['participantNames'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ??
              const {}),
      postId: map['postId'] as String? ?? '',
      postTitle: map['postTitle'] as String? ?? 'Conversa',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: ultima is Timestamp ? ultima.toDate() : null,
      unread: ((map['unread'] as Map?) ?? const {})
          .map((k, v) => MapEntry('$k', (v as num?)?.toInt() ?? 0)),
    );
  }
}

/// Mensagem do chat (chats/{chatId}/messages/{id}).
class MensagemModel {
  final String id;
  final String senderId;
  final String texto;
  final String? fotoUrl;
  final DateTime createdAt;

  const MensagemModel({
    required this.id,
    required this.senderId,
    required this.texto,
    this.fotoUrl,
    required this.createdAt,
  });

  factory MensagemModel.fromMap(String id, Map<String, dynamic> map) {
    final criada = map['createdAt'];
    return MensagemModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      texto: map['text'] as String? ?? '',
      fotoUrl: map['photoUrl'] as String?,
      // serverTimestamp ainda não confirmado chega nulo: usa "agora".
      createdAt: criada is Timestamp ? criada.toDate() : DateTime.now(),
    );
  }
}
