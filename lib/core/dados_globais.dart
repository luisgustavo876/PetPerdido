class DadosGlobais {
  // Variável estática simples para armazenar os pontos do usuário na memória
  static int pontosUsuario = 320;

  // Lista simples para armazenar recompensas resgatadas
  static List<String> recompensasResgatadas = [];

  // Mapa simples para simular o armazenamento local de chats
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

  /// Tenta resgatar uma recompensa (deduz os pontos)
  static bool resgatarRecompensa(String rewardId, int custo) {
    if (pontosUsuario >= custo && !recompensasResgatadas.contains(rewardId)) {
      pontosUsuario -= custo;
      recompensasResgatadas.add(rewardId);
      return true;
    }
    return false;
  }
}
