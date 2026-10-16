/// Chats em memória (provisório). Os pontos e os resgates já vêm do
/// Firestore (PontosService). Este arquivo some quando o chat real existir.
class DadosGlobais {
  // Formato: { "postId": [ {"senderName": "...", "message": "..."} ] }
  static final Map<String, List<Map<String, dynamic>>> chats = {};

  /// Adiciona uma nova mensagem em um chat
  static void adicionarMensagem(String postId, String senderId, String senderName, String message) {
    if (!chats.containsKey(postId)) {
      chats[postId] = [];
    }
    chats[postId]!.add({
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': DateTime.now(),
      'photoUrl': null,
    });
  }
}
