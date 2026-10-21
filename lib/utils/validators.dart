/// Validaciones de formularios. Cada función devuelve `null` si el valor es
/// válido o el mensaje de error que se muestra bajo el campo.
class Validators {
  Validators._();

  static final _username = RegExp(r'^[a-zA-Z0-9_.]+$');
  static final _email = RegExp(r'^[\w.+-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$');
  static final _personName = RegExp(r"^[\p{L} '.-]+$", unicode: true);
  static final _characterName =
      RegExp(r"^[\p{L}\p{N} '.,:()&-]+$", unicode: true);
  static final _species = RegExp(r"^[\p{L} '-]+$", unicode: true);
  static final _place = RegExp(r"^[\p{L}\p{N} '.,:()&/-]+$", unicode: true);
  static final _hasLetter = RegExp(r'[A-Za-z]');
  static final _hasDigit = RegExp(r'\d');
  static final _hasUpper = RegExp(r'[A-Z]');

  static String? _lengthCheck(String v, String field, int min, int max) {
    if (v.length < min) return '$field debe tener al menos $min caracteres';
    if (v.length > max) return '$field no puede superar $max caracteres';
    return null;
  }

  // ------------------------------------------------------------ Login

  /// Login: el usuario no puede quedar vacío.
  static String? loginUser(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu usuario';
    }
    return null;
  }

  /// Login: la contraseña no puede quedar vacía.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.trim().isEmpty) return 'La contraseña no puede ser solo espacios';
    return null;
  }

  // ------------------------------------------------------------ Registro

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre completo';
    if (!_personName.hasMatch(v)) return 'Solo se permiten letras y espacios';
    if (v.split(RegExp(r'\s+')).length < 2) {
      return 'Ingresa nombre y apellido';
    }
    return _lengthCheck(v, 'El nombre', 5, 50);
  }

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa un nombre de usuario';
    if (v.contains(' ')) return 'El usuario no puede contener espacios';
    if (!_username.hasMatch(v)) {
      return 'Solo letras, números, punto (.) y guion bajo (_)';
    }
    return _lengthCheck(v, 'El usuario', 4, 20);
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_email.hasMatch(v)) return 'Correo electrónico no válido';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa una contraseña';
    if (v.contains(' ')) return 'La contraseña no puede contener espacios';
    final len = _lengthCheck(v, 'La contraseña', 6, 30);
    if (len != null) return len;
    if (!_hasLetter.hasMatch(v) || !_hasDigit.hasMatch(v)) {
      return 'Debe combinar letras y números';
    }
    if (!_hasUpper.hasMatch(v)) return 'Debe incluir al menos una mayúscula';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  // ------------------------------------------------------------ Personaje

  static String? characterName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre es obligatorio';
    if (!_characterName.hasMatch(v)) {
      return 'Contiene caracteres no permitidos';
    }
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(v)) {
      return 'El nombre debe contener letras';
    }
    return _lengthCheck(v, 'El nombre', 2, 50);
  }

  static String? species(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'La especie es obligatoria';
    if (!_species.hasMatch(v)) return 'Solo se permiten letras';
    return _lengthCheck(v, 'La especie', 2, 30);
  }

  static String? type(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // opcional
    if (!_place.hasMatch(v)) return 'Contiene caracteres no permitidos';
    return _lengthCheck(v, 'El tipo', 2, 40);
  }

  static String? origin(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El origen es obligatorio';
    if (!_place.hasMatch(v)) return 'Contiene caracteres no permitidos';
    return _lengthCheck(v, 'El origen', 2, 60);
  }

  static String? location(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // opcional
    if (!_place.hasMatch(v)) return 'Contiene caracteres no permitidos';
    return _lengthCheck(v, 'La ubicación', 2, 60);
  }

  static String? dropdown(String? value, String field) =>
      value == null || value.isEmpty ? 'Selecciona $field' : null;

  static String? imageUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // opcional: se usa una imagen por defecto
    final uri = Uri.tryParse(v);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty ||
        !uri.host.contains('.')) {
      return 'Ingresa una URL válida (http:// o https://)';
    }
    if (v.length > 300) return 'La URL es demasiado larga';
    return null;
  }
}
