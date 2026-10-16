import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../legal/legal_screens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _birthController = TextEditingController(); // só exibe dd/mm/aaaa
  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  /// Formata a data como dd/mm/aaaa.
  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickBirthDate() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(hoje.year - 18, hoje.month, hoje.day),
      firstDate: DateTime(1900),
      lastDate: hoje,
      helpText: 'Data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      fieldLabelText: 'Data de nascimento',
      fieldHintText: 'dd/mm/aaaa',
      errorFormatText: 'Use o formato dd/mm/aaaa',
      errorInvalidText: 'Data fora do intervalo permitido',
    );
    if (escolhida == null) return;
    setState(() {
      _birthDate = escolhida;
      _birthController.text = _formatarData(escolhida);
    });
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        cpf: _cpfController.text,
        birthDate: _birthDate!,
      );
      // Conta e documento users/{uid} gravados. A RegisterScreen está
      // empilhada sobre o _AuthGate (que já mostra a MainScreen): volta até ele.
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = switch (e.code) {
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'weak-password' => 'Senha muito fraca.',
        'invalid-email' => 'E-mail inválido.',
        'network-request-failed' => 'Sem conexão com a internet. Tente novamente.',
        'too-many-requests' => 'Muitas tentativas. Tente mais tarde.',
        _ => 'Erro ao cadastrar. Tente novamente.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } on FirebaseException catch (_) {
      // Falha ao gravar users/{uid}: o AuthService já desfez a conta.
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar seus dados. Tente novamente.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: AppColors.onSurface, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Criar conta',
          style: GoogleFonts.inter(
            color: AppColors.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seus dados',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Você precisa ter ao menos ${AppConstants.minAge} anos para se cadastrar.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),

                CustomTextField(
                  label: 'Nome completo',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? 'Nome inválido' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'E-mail',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o e-mail';
                    if (!v.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'CPF',
                  hint: '000.000.000-00',
                  controller: _cpfController,
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(AppConstants.cpfLength),
                  ],
                  validator: (v) {
                    if (v == null || v.length != AppConstants.cpfLength) {
                      return 'CPF deve ter ${AppConstants.cpfLength} dígitos';
                    }
                    if (!AuthService.validarCpf(v)) return 'CPF inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Campo só de leitura: abre o calendário ao tocar.
                TextFormField(
                  controller: _birthController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  decoration: const InputDecoration(
                    labelText: 'Data de nascimento',
                    hintText: 'dd/mm/aaaa',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.cake_outlined,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  validator: (_) =>
                      AuthService.validarNascimento(_birthDate, DateTime.now()),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Senha',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < AppConstants.minPasswordLength) {
                      return 'Mínimo de ${AppConstants.minPasswordLength} caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Confirmar senha',
                  controller: _confirmController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) => v != _passwordController.text
                      ? 'As senhas não coincidem'
                      : null,
                ),

                const SizedBox(height: 36),

                CustomButton(
                  label: 'Criar Conta',
                  onPressed: _onRegister,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    'Ao criar sua conta, você concorda com nossos',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TermosScreen())),
                      child: const Text('Termos de Uso'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PrivacidadeScreen())),
                      child: const Text('Política de Privacidade'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
