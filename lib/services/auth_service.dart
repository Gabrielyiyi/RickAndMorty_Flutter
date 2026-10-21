import 'package:flutter/foundation.dart';

class AppUser {
  final String fullName;
  final String username;
  final String email;
  final String password;

  const AppUser({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
  });
}

/// Módulo de autenticación (login / registro / cierre de sesión).
///
/// Las credenciales se guardan en variables en memoria; al pulsar "Ingresar"
/// se comparan los datos escritos con los almacenados.
class AuthService extends ChangeNotifier {
  /// Credenciales del usuario predefinido.
  static const String defaultUser = 'admin';
  static const String defaultPassword = 'Admin123';

  /// Intentos fallidos permitidos antes de bloquear temporalmente el login.
  static const int maxAttempts = 3;
  static const Duration lockDuration = Duration(seconds: 30);

  final Map<String, AppUser> _users = {
    defaultUser: const AppUser(
      fullName: 'Rick Sanchez',
      username: defaultUser,
      email: 'rick@citadel.com',
      password: defaultPassword,
    ),
  };

  AppUser? _currentUser;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  int get remainingAttempts => maxAttempts - _failedAttempts;

  /// Segundos restantes de bloqueo, o 0 si se puede intentar.
  int get lockSecondsLeft {
    final until = _lockedUntil;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      _lockedUntil = null;
      _failedAttempts = 0;
      return 0;
    }
    return left + 1;
  }

  /// Compara el usuario y la contraseña con los registrados.
  /// Devuelve `null` si el acceso es correcto, o un mensaje de error.
  String? login(String username, String password) {
    final wait = lockSecondsLeft;
    if (wait > 0) {
      return 'Demasiados intentos fallidos. Espera $wait s.';
    }

    final key = username.trim().toLowerCase();
    final user = _users[key];

    // El usuario no distingue mayúsculas; la contraseña sí.
    if (user == null || user.password != password) {
      _failedAttempts++;
      if (_failedAttempts >= maxAttempts) {
        _lockedUntil = DateTime.now().add(lockDuration);
        return 'Usuario o contraseña incorrectos. Acceso bloqueado por '
            '${lockDuration.inSeconds} s.';
      }
      return 'Usuario o contraseña incorrectos. '
          'Te quedan $remainingAttempts intento(s).';
    }

    _failedAttempts = 0;
    _currentUser = user;
    notifyListeners();
    return null;
  }

  bool usernameTaken(String username) =>
      _users.containsKey(username.trim().toLowerCase());

  bool emailTaken(String email) {
    final e = email.trim().toLowerCase();
    return _users.values.any((u) => u.email.toLowerCase() == e);
  }

  /// Registra un nuevo usuario. Devuelve `null` si se registró correctamente.
  String? register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) {
    if (usernameTaken(username)) return 'El usuario "$username" ya existe.';
    if (emailTaken(email)) return 'El correo ya está registrado.';

    final key = username.trim().toLowerCase();
    _users[key] = AppUser(
      fullName: fullName.trim(),
      username: key,
      email: email.trim().toLowerCase(),
      password: password,
    );
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
