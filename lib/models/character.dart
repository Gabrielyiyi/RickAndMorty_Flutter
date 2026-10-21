/// Modelo de un personaje de Rick and Morty.
///
/// Los personajes provienen de la API (https://rickandmortyapi.com/api/character)
/// o son creados localmente por el usuario ([isLocal] = true).
class Character {
  final int id;
  final String name;
  final String status; // Alive | Dead | unknown
  final String species;
  final String type;
  final String gender; // Female | Male | Genderless | unknown
  final String origin;
  final String location;
  final String image;
  final int episodes;
  final DateTime? created;

  /// Creado por el usuario dentro de la app (no existe en la API).
  final bool isLocal;

  /// Personaje de la API que el usuario modificó.
  final bool isEdited;

  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    this.type = '',
    required this.gender,
    required this.origin,
    this.location = '',
    this.image = '',
    this.episodes = 0,
    this.created,
    this.isLocal = false,
    this.isEdited = false,
  });

  /// Valores válidos según la API.
  static const statuses = ['Alive', 'Dead', 'unknown'];
  static const genders = ['Female', 'Male', 'Genderless', 'unknown'];

  static const _statusLabels = {
    'Alive': 'Vivo',
    'Dead': 'Muerto',
    'unknown': 'Desconocido',
  };
  static const _genderLabels = {
    'Female': 'Femenino',
    'Male': 'Masculino',
    'Genderless': 'Sin género',
    'unknown': 'Desconocido',
  };

  static String statusLabel(String status) => _statusLabels[status] ?? status;
  static String genderLabel(String gender) => _genderLabels[gender] ?? gender;

  String get statusText => statusLabel(status);
  String get genderText => genderLabel(gender);

  factory Character.fromJson(Map<String, dynamic> json) {
    String nested(String key) {
      final value = json[key];
      if (value is Map && value['name'] is String) return value['name'] as String;
      return 'unknown';
    }

    final status = json['status'] as String? ?? 'unknown';
    final gender = json['gender'] as String? ?? 'unknown';

    return Character(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
      // Normaliza valores inesperados para que siempre coincidan con los
      // permitidos por los formularios y filtros.
      status: statuses.contains(status) ? status : 'unknown',
      species: json['species'] as String? ?? 'unknown',
      type: json['type'] as String? ?? '',
      gender: genders.contains(gender) ? gender : 'unknown',
      origin: nested('origin'),
      location: nested('location'),
      image: json['image'] as String? ?? '',
      episodes: (json['episode'] as List?)?.length ?? 0,
      created: DateTime.tryParse(json['created'] as String? ?? ''),
    );
  }

  Character copyWith({
    int? id,
    String? name,
    String? status,
    String? species,
    String? type,
    String? gender,
    String? origin,
    String? location,
    String? image,
    int? episodes,
    DateTime? created,
    bool? isLocal,
    bool? isEdited,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      species: species ?? this.species,
      type: type ?? this.type,
      gender: gender ?? this.gender,
      origin: origin ?? this.origin,
      location: location ?? this.location,
      image: image ?? this.image,
      episodes: episodes ?? this.episodes,
      created: created ?? this.created,
      isLocal: isLocal ?? this.isLocal,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}

/// Página de resultados devuelta por la API.
class CharacterPage {
  final List<Character> results;
  final int pages;
  final int count;

  const CharacterPage({
    required this.results,
    required this.pages,
    required this.count,
  });
}
