import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/decor.dart';
import 'characters_screen.dart';
import 'register_screen.dart';

/// UI "Inicio de sesión".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  /// Botón "Ingresar": valida campos vacíos y compara con las credenciales.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    // 1. Validación: los campos no pueden quedar vacíos.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    // Simula la latencia de un servidor para dar feedback visual.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // 2. Comparación de los datos ingresados con los registrados.
    final auth = AppScope.of(context).auth;
    final error = auth.login(_userCtrl.text, _passCtrl.text);

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      _passCtrl.clear();
      return;
    }

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => const CharactersScreen(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  void _fillDemo() {
    setState(() {
      _userCtrl.text = AuthService.defaultUser;
      _passCtrl.text = AuthService.defaultPassword;
      _error = null;
    });
  }

  Future<void> _goToRegister() async {
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (username == null || !mounted) return;
    setState(() {
      _userCtrl.text = username;
      _passCtrl.clear();
      _error = null;
    });
    _passFocus.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cuenta "$username" creada. Ya puedes ingresar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: PortalBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FadeSlideIn(child: Center(child: PortalLogo(size: 116))),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        children: [
                          GradientText(
                            'Rick and Morty',
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'EXPLORADOR DEL MULTIVERSO',
                            textAlign: TextAlign.center,
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.white60,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: GlassCard(child: _buildForm(textTheme)),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?',
                              style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: _loading ? null : _goToRegister,
                            child: const Text('Regístrate',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(TextTheme textTheme) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bienvenido de vuelta',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Inicia sesión para acceder al catálogo',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white60)),
          const SizedBox(height: 22),
          TextFormField(
            controller: _userCtrl,
            enabled: !_loading,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: Validators.loginUser,
            onFieldSubmitted: (_) => _passFocus.requestFocus(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passCtrl,
            focusNode: _passFocus,
            enabled: !_loading,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: Validators.loginPassword,
            onFieldSubmitted: (_) => _submit(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _error == null
                ? const SizedBox(height: 22, width: double.infinity)
                : _ErrorBox(_error!),
          ),
          _GlowButton(
            loading: _loading,
            onPressed: _submit,
            label: 'Ingresar',
            icon: Icons.rocket_launch_rounded,
          ),
          const SizedBox(height: 14),
          Center(
            child: ActionChip(
              avatar: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.portal),
              label: const Text('Usar cuenta de prueba'),
              side: BorderSide(color: AppColors.portal.withValues(alpha: 0.4)),
              backgroundColor: AppColors.portal.withValues(alpha: 0.08),
              onPressed: _loading ? null : _fillDemo,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón principal con degradado y resplandor.
class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.loading,
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  final bool loading;
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFFB8F36B), AppColors.portal, Color(0xFF5FB33A)]),
        boxShadow: [
          BoxShadow(
            color: AppColors.portal.withValues(alpha: loading ? 0.1 : 0.4),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF10210A),
          disabledForegroundColor: const Color(0xFF10210A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size.fromHeight(56),
        ),
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Color(0xFF10210A)),
              )
            : Icon(icon),
        label: Text(loading ? 'Abriendo portal...' : label),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dead.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dead.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_bad_outlined, color: AppColors.dead),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
