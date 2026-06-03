import 'dart:async';
import 'package:flutter/material.dart';
import 'post_model.dart';
import '../services/post_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  StreamSubscription<List<PostModel>>? _postsSub;

  AppState._internal() {
    _chats = {
      '1': [
        {
          'senderId': 'user1',
          'senderName': 'Carol Mendes',
          'message': 'Alguém viu a Laura perto da pracinha da Vila Barth?',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
          'photoUrl': null,
        },
        {
          'senderId': 'myUser',
          'senderName': 'Você',
          'message': 'Eu passei por lá mais cedo, vou ficar atento!',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 40)),
          'photoUrl': null,
        }
      ],
      '2': [
        {
          'senderId': 'user2',
          'senderName': 'Danilo Ramos',
          'message': 'O Rex estava correndo assustado perto do Jardim Marabá.',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 10)),
          'photoUrl': null,
        }
      ],
      '3': []
    };
  }

  List<PostModel> _posts = List.from(mockPosts);
  List<PostModel> get posts => List.unmodifiable(_posts);

  bool _loadingPosts = false;
  bool get loadingPosts => _loadingPosts;

  int _userPoints = 320;
  int get userPoints => _userPoints;

  final List<String> _redeemedRewards = [];
  List<String> get redeemedRewards => List.unmodifiable(_redeemedRewards);

  late final Map<String, List<Map<String, dynamic>>> _chats;
  Map<String, List<Map<String, dynamic>>> get chats => _chats;

  // Conecta ao Firestore e substitui os posts em tempo real
  void initPostsStream() {
    if (_postsSub != null) return; // já está ouvindo
    _loadingPosts = true;
    notifyListeners();

    _postsSub = PostService.postsStream().listen(
      (firestorePosts) {
        _posts = firestorePosts;
        _loadingPosts = false;
        for (final post in firestorePosts) {
          _chats.putIfAbsent(post.id, () => []);
        }
        notifyListeners();
      },
      onError: (_) {
        // Mantém mockPosts se Firestore falhar
        _loadingPosts = false;
        notifyListeners();
      },
    );
  }

  void cancelPostsStream() {
    _postsSub?.cancel();
    _postsSub = null;
  }

  Future<void> addPost(PostModel post) async {
    await PostService.createPost(post);
    // Stream atualiza _posts automaticamente
  }

  void addMessage(String postId, String senderId, String senderName,
      String message, {String? photoUrl}) {
    _chats.putIfAbsent(postId, () => []);
    _chats[postId]!.add({
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': DateTime.now(),
      'photoUrl': photoUrl,
    });
    notifyListeners();
  }

  bool redeemReward(String rewardId, int cost) {
    if (_userPoints >= cost && !_redeemedRewards.contains(rewardId)) {
      _userPoints -= cost;
      _redeemedRewards.add(rewardId);
      notifyListeners();
      return true;
    }
    return false;
  }

  void addSighting(String postId) {
    // Atualização otimista local
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        sightingsCount: post.sightingsCount + 1,
        helpersCount: post.helpersCount + 1,
      );
      _userPoints += 15;
      notifyListeners();
    }
    // Persiste no Firestore em background
    PostService.incrementSighting(postId);
  }
}
