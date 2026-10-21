import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/decor.dart';

/// Registro de nuevos usuarios. Al terminar devuelve el nombre de usuario.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _acceptTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _userCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final auth = AppScope.of(context).auth;
    final error = auth.register(
      fullName: _nameCtrl.text,
      username: _userCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.dead),
      );
      return;
    }
    Navigator.of(context).pop(_userCtrl.text.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: PortalBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FadeSlideIn(child: Center(child: PortalLogo(size: 72))),
                    const SizedBox(height: 14),
                    GradientText(
                      'Únete a la Ciudadela',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crea tu cuenta para gestionar personajes',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: GlassCard(
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _fields(auth),
                          ),
                        ),
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

  List<Widget> _fields(AuthService auth) => [
        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nombre completo *',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: Validators.fullName,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _userCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Usuario *',
            helperText: '4-20 caracteres: letras, números, . y _',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          validator: (v) {
            final error = Validators.username(v);
            if (error != null) return error;
            if (auth.usernameTaken(v!)) return 'Este usuario ya existe';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico *',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: (v) {
            final error = Validators.email(v);
            if (error != null) return error;
            if (auth.emailTaken(v!)) return 'Este correo ya está registrado';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Contraseña *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: Validators.password,
          // Revalida la confirmación cuando cambia la contraseña.
          onChanged: (_) {
            if (_confirmCtrl.text.isNotEmpty) _formKey.currentState!.validate();
          },
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder(
          valueListenable: _passCtrl,
          builder: (context, value, _) => _PasswordStrength(value.text),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Confirmar contraseña *',
            prefixIcon: Icon(Icons.lock_reset),
          ),
          validator: (v) => Validators.confirmPassword(v, _passCtrl.text),
          onFieldSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        FormField<bool>(
          initialValue: _acceptTerms,
          validator: (_) =>
              _acceptTerms ? null : 'Debes aceptar los términos para continuar',
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material propio: el ListTile está sobre una tarjeta con fondo.
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  value: _acceptTerms,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Acepto los términos y condiciones de la Ciudadela'),
                  onChanged: (v) {
                    setState(() => _acceptTerms = v ?? false);
                    field.didChange(v);
                  },
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.person_add_alt_1),
          label: const Text('Crear cuenta'),
        ),
      ];
}

/// Barra que indica qué tan segura es la contraseña y qué requisitos cumple.
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength(this.password);

  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = <String, bool>{
      '6+ caracteres': password.length >= 6,
      'Mayúscula': password.contains(RegExp(r'[A-Z]')),
      'Número': password.contains(RegExp(r'\d')),
      'Símbolo': password.contains(RegExp(r'[^A-Za-z0-9\s]')),
    };
    final score = checks.values.where((ok) => ok).length +
        (password.length >= 10 ? 1 : 0);

    final (label, color) = switch (score) {
      0 => ('', AppColors.unknown),
      1 || 2 => ('Débil', AppColors.dead),
      3 => ('Aceptable', Colors.amber),
      4 => ('Fuerte', AppColors.alive),
      _ => ('Muy fuerte', AppColors.cyan),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < score ? color : Colors.white12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (label.isNotEmpty)
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            for (final e in checks.entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    e.value ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 13,
                    color: e.value ? AppColors.alive : Colors.white38,
                  ),
                  const SizedBox(width: 3),
                  Text(e.key,
                      style: TextStyle(
                          fontSize: 11,
                          color: e.value ? Colors.white70 : Colors.white38)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
