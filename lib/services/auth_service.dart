import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../core/formatters.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Cria a conta no Firebase Auth e o documento users/{uid} no Firestore.
  /// Se a gravação do documento falhar, apaga a conta recém-criada e relança
  /// o erro — assim nunca fica um usuário no Auth sem os dados no Firestore.
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    try {
      await user.updateDisplayName(name.trim());

      await _db.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        // Só os 11 dígitos, sem máscara. Protegido pelas regras: só o
        // próprio usuário lê.
        'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
        'birthDate': Timestamp.fromDate(birthDate),
        'points': AppConstants.initialPoints,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {
        // Se nem a exclusão funcionar, o erro original é o que importa.
      }
      rethrow;
    }
  }

  /// Valida o CPF pelos dois dígitos verificadores (cálculo do módulo 11).
  /// Aceita com ou sem máscara (000.000.000-00).
  static bool validarCpf(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'\D'), '');
    if (numeros.length != AppConstants.cpfLength) return false;

    // CPFs com todos os dígitos iguais passam no cálculo, mas são inválidos.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(numeros)) return false;

    final d = numeros.split('').map(int.parse).toList();

    // j = 9 confere o 1º dígito verificador (pesos 10..2);
    // j = 10 confere o 2º (pesos 11..2).
    for (var j = 9; j < 11; j++) {
      var soma = 0;
      for (var i = 0; i < j; i++) {
        soma += d[i] * (j + 1 - i);
      }
      final digito = (soma * 10) % 11 % 10; // resto 10 vira 0
      if (digito != d[j]) return false;
    }
    return true;
  }

  /// Idade completa em anos na data [hoje]. Ignora o horário.
  /// Quem nasceu em 29/02 completa ano em 01/03 nos anos não bissextos.
  static int idadeEmAnos(DateTime nascimento, DateTime hoje) {
    var idade = hoje.year - nascimento.year;
    final aindaNaoFezAniversario = hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day);
    if (aindaNaoFezAniversario) idade--;
    return idade;
  }

  /// Validação da data de nascimento usada no cadastro.
  /// Retorna a mensagem de erro, ou null se estiver tudo certo.
  static String? validarNascimento(DateTime? nascimento, DateTime hoje) {
    if (nascimento == null) return 'Informe a data de nascimento';
    if (nascimento.isAfter(hoje)) {
      return 'A data de nascimento não pode ser no futuro';
    }
    if (idadeEmAnos(nascimento, hoje) < AppConstants.minAge) {
      return 'Você precisa ter pelo menos ${AppConstants.minAge} anos';
    }
    return null;
  }

  /// Mesma validação, a partir do texto digitado no campo (DD/MM/AAAA).
  static String? validarNascimentoTexto(String texto, DateTime hoje) {
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return 'Informe a data de nascimento';
    if (digitos.length < 8) return 'Data incompleta. Use DD/MM/AAAA';
    final data = Formatters.lerData(texto);
    if (data == null) return 'Data inválida. Confira o dia, o mês e o ano';
    return validarNascimento(data, hoje);
  }

  /// Envia o e-mail de redefinição de senha.
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Nome do usuário logado para gravar em posts, avistamentos e chats
  /// (dados públicos). Sem nome, usa "Usuário" — nunca o e-mail.
  static String get currentUserName =>
      Formatters.nomeUsuario(currentUser?.displayName);
}
