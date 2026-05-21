import 'package:flutter/material.dart';
import 'post_model.dart';

/// Gerenciador de Estado Global Simulado para o PetPerdido.
/// Singleton reativo que propaga atualizações de dados instantaneamente para toda a interface.
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  AppState._internal() {
    // Inicialização do histórico de mensagens para os chats mockados
    _chats = {
      '1': [
        {
          'senderId': 'user1', // Tutor (Carol)
          'senderName': 'Carol Mendes',
          'message': 'Olá! Alguém viu a Laura perto da pracinha da Vila Barth?',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
          'photoUrl': null,
        },
        {
          'senderId': 'myUser', // Usuário Logado
          'senderName': 'Você',
          'message': 'Eu passei por lá mais cedo, vou ficar atento!',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 40)),
          'photoUrl': null,
        }
      ],
      '2': [
        {
          'senderId': 'user2', // Danilo
          'senderName': 'Danilo Ramos',
          'message': 'Oi! O Rex estava correndo assustado perto do Jardim Marabá.',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
          'photoUrl': null,
        }
      ],
      '3': []
    };
  }

  // Lista dinâmica de postagens
  final List<PostModel> _posts = List.from(mockPosts);
  List<PostModel> get posts => List.unmodifiable(_posts);

  // Saldo de pontos inicializado em 320
  int _userPoints = 320;
  int get userPoints => _userPoints;

  // Prêmios resgatados pelo usuário
  final List<String> _redeemedRewards = [];
  List<String> get redeemedRewards => List.unmodifiable(_redeemedRewards);

  // Histórico de chats estruturado por postId
  late final Map<String, List<Map<String, dynamic>>> _chats;
  Map<String, List<Map<String, dynamic>>> get chats => _chats;

  /// Adiciona uma nova postagem ao estado global
  void addPost(PostModel post) {
    _posts.insert(0, post);
    _chats[post.id] = [];
    notifyListeners();
  }

  /// Adiciona uma mensagem à conversa de um post específico
  void addMessage(String postId, String senderId, String senderName, String message, {String? photoUrl}) {
    if (!_chats.containsKey(postId)) {
      _chats[postId] = [];
    }
    _chats[postId]!.add({
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': DateTime.now(),
      'photoUrl': photoUrl,
    });
    notifyListeners();
  }

  /// Tenta resgatar uma recompensa deduzindo os pontos do saldo
  bool redeemReward(String rewardId, int cost) {
    if (_userPoints >= cost && !_redeemedRewards.contains(rewardId)) {
      _userPoints -= cost;
      _redeemedRewards.add(rewardId);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Adiciona um avistamento a uma postagem e bonifica o usuário com 15 pontos
  void addSighting(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        sightingsCount: post.sightingsCount + 1,
        helpersCount: post.helpersCount + 1,
      );
      _userPoints += 15; // Recompensa de 15 pontos
      notifyListeners();
    }
  }
}
