import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../core/formatters.dart';
import '../../services/alerta_service.dart';
import '../../services/auth_service.dart';
import '../../services/conta_service.dart';
import '../../services/user_service.dart';
import '../legal/legal_screens.dart';
import 'meus_posts_screen.dart';

/// Configurações e perfil com dados reais (users/{uid}): nome (editável),
/// e-mail, CPF mascarado, pontos, alertas, privacidade e conta.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Stream único da tela, criado no initState.
  late Stream<Perfil?> _perfilStream;
  bool _salvandoAlertas = false;

  @override
  void initState() {
    super.initState();
    _perfilStream = UserService.perfilStream();
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(texto)));

  void _abrir(Widget tela) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => tela));

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------

  Future<void> _editarNome(String atual) async {
    final controller = TextEditingController(text: atual);
    final novo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome completo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (novo == null) return;
    if (novo.trim().length < 3) {
      _aviso('O nome precisa ter pelo menos 3 letras.');
      return;
    }
    if (novo.contains('@')) {
      _aviso('Use o seu nome, não o e-mail (ele aparece para outras pessoas).');
      return;
    }
    try {
      await UserService.atualizarNome(novo);
      _aviso('Nome atualizado.');
    } catch (_) {
      _aviso('Não foi possível salvar. Tente novamente.');
    }
  }

  Future<void> _alterarSenha(String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Text('Vamos enviar um link para redefinir a senha em $email.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar link')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.sendPasswordReset(email);
      _aviso('E-mail enviado! Confira também a caixa de spam.');
    } catch (_) {
      _aviso('Não foi possível enviar o e-mail. Tente novamente.');
    }
  }

  Future<void> _alternarAlertas(bool ligar) async {
    setState(() => _salvandoAlertas = true);
    try {
      if (ligar) {
        // Pede as permissões já no toque (o navegador exige um toque recente).
        final permissoes = AlertaService.atualizar(pedirPermissao: true);
        await UserService.definirAlertas(ativo: true);
        await permissoes;
      } else {
        await UserService.desligarAlertas();
      }
    } catch (_) {
      _aviso('Não foi possível atualizar os alertas.');
    } finally {
      if (mounted) setState(() => _salvandoAlertas = false);
    }
  }

  Future<void> _mudarRaio(int km) async {
    try {
      await UserService.definirAlertas(raioKm: km);
    } catch (_) {
      _aviso('Não foi possível salvar o raio.');
    }
  }

  Future<void> _sair() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await AlertaService.sair(); // tira o token do push; o AuthGate volta ao login
  }

  Future<void> _excluirConta() async {
    final excluiu = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DialogoExcluirConta(),
    );
    if (excluiu == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(const SnackBar(
          content: Text('Sua conta e seus dados foram excluídos.')));
    }
  }

  // ---------------------------------------------------------------------------
  // Tela
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Configurações e perfil')),
      body: StreamBuilder<Perfil?>(
        stream: _perfilStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _perfilStream = UserService.perfilStream()),
                child: const Text('Não foi possível carregar. Tentar de novo'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data ??
              Perfil(
                nome: AuthService.currentUserName,
                email: AuthService.currentUser?.email ?? '',
                cpf: '',
                pontos: 0,
                alertasAtivos: false,
                raioKm: AppConstants.alertRadiusPadraoKm,
              );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _cartaoPerfil(p),
              const SizedBox(height: 24),
              _titulo('MINHA CONTA'),
              _grupo([
                _item(Icons.edit_outlined, 'Editar nome', onTap: () => _editarNome(p.nome)),
                _item(Icons.lock_reset, 'Alterar senha',
                    subtitulo: 'Enviamos um link por e-mail',
                    onTap: () => _alterarSenha(p.email)),
                _item(Icons.article_outlined, 'Meus posts',
                    onTap: () => _abrir(const MeusPostsScreen())),
              ]),
              const SizedBox(height: 24),
              _titulo('ALERTAS DE PETS POR PERTO'),
              _alertas(p),
              const SizedBox(height: 24),
              _titulo('PRIVACIDADE'),
              _grupo([
                _item(Icons.description_outlined, 'Termos de Uso',
                    onTap: () => _abrir(const TermosScreen())),
                _item(Icons.privacy_tip_outlined, 'Política de Privacidade',
                    onTap: () => _abrir(const PrivacidadeScreen())),
              ]),
              const SizedBox(height: 24),
              _titulo('SOBRE'),
              _grupo([
                _item(Icons.info_outline, 'Versão', subtitulo: '1.0.0 (protótipo de TCC)'),
                _item(Icons.location_city, 'Região piloto', subtitulo: 'Itapetininga, SP'),
              ]),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _sair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _excluirConta,
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Excluir minha conta'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// Cartão do perfil: nome, CPF mascarado e pontos (sem e-mail).
  Widget _cartaoPerfil(Perfil p) {
    final nome = Formatters.nomeUsuario(p.nome);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              nome[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('CPF ${Perfil.mascararCpf(p.cpf)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${p.pontos} pontos',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertas(Perfil p) {
    return _grupo([
      SwitchListTile(
        title: const Text('Receber alertas'),
        subtitle: Text(kIsWeb
            ? 'Notificação no navegador quando um pet some, é achado ou visto '
                'perto de você (no iPhone, só com o site na tela de início).'
            : 'Aviso quando um pet some, é achado ou visto perto de você.'),
        value: p.alertasAtivos,
        activeThumbColor: AppColors.primary,
        onChanged: _salvandoAlertas ? null : _alternarAlertas,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distância máxima dos alertas',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final km in AppConstants.alertRadiosKm)
                  ChoiceChip(
                    label: Text('$km km'),
                    selected: p.raioKm == km,
                    onSelected: p.alertasAtivos ? (_) => _mudarRaio(km) : null,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: p.raioKm == km && p.alertasAtivos
                          ? Colors.white
                          : AppColors.onSurface,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Guardamos só a sua localização aproximada (~100 m), atualizada quando '
              'você abre o app. Ao desligar, ela é apagada.',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text(texto,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8)),
      );

  Widget _grupo(List<Widget> itens) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: itens),
      );

  Widget _item(IconData icone, String titulo, {String? subtitulo, VoidCallback? onTap}) =>
      ListTile(
        leading: Icon(icone, color: AppColors.primary),
        title: Text(titulo),
        subtitle: subtitulo == null ? null : Text(subtitulo),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
      );
}

/// Pede a senha de novo e exclui a conta, mostrando o andamento.
class _DialogoExcluirConta extends StatefulWidget {
  const _DialogoExcluirConta();

  @override
  State<_DialogoExcluirConta> createState() => _DialogoExcluirContaState();
}

class _DialogoExcluirContaState extends State<_DialogoExcluirConta> {
  final _senha = TextEditingController();
  bool _excluindo = false;
  String? _etapa;
  String? _erro;

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_senha.text.isEmpty) {
      setState(() => _erro = 'Digite sua senha.');
      return;
    }
    setState(() {
      _excluindo = true;
      _erro = null;
    });
    try {
      await ContaService.excluirConta(_senha.text,
          etapa: (e) => mounted ? setState(() => _etapa = e) : null);
      if (mounted) Navigator.pop(context, true);
    } on ContaException catch (e) {
      if (mounted) {
        setState(() {
          _excluindo = false;
          _erro = e.mensagem;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 40),
      title: const Text('Excluir minha conta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Isso apaga para sempre seus posts e fotos, avistamentos, mensagens, '
              'pontos, resgates e o seu cadastro. Não dá para desfazer.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senha,
              obscureText: true,
              enabled: !_excluindo,
              decoration: const InputDecoration(labelText: 'Confirme sua senha'),
            ),
            if (_excluindo) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_etapa ?? 'Confirmando a senha...')),
                ],
              ),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 16),
              Text(_erro!,
                  style: const TextStyle(
                      color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _excluindo ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _excluindo ? null : _confirmar,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Excluir tudo'),
        ),
      ],
    );
  }
}
