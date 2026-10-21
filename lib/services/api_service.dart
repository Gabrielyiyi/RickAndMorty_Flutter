import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/character.dart';

/// Error controlado de la API con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP de la API pública de Rick and Morty.
class RickAndMortyApi {
  static const baseUrl = 'https://rickandmortyapi.com/api/character';
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;

  RickAndMortyApi({http.Client? client}) : _client = client ?? http.Client();

  /// Obtiene una página del catálogo (20 personajes por página).
  /// Si la API responde 429 (demasiadas peticiones) espera y reintenta.
  Future<CharacterPage> fetchPage(int page, {int maxRetries = 4}) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {'page': '$page'});

    http.Response response;
    var attempt = 0;
    while (true) {
      try {
        response = await _client.get(uri).timeout(_timeout);
      } on TimeoutException {
        throw const ApiException(
            'El servidor tardó demasiado en responder. Intenta de nuevo.');
      } on http.ClientException {
        throw const ApiException(
            'No hay conexión a Internet o el servidor no está disponible.');
      }
      if (response.statusCode != 429 || attempt >= maxRetries) break;
      attempt++;
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      await Future<void>.delayed(
          Duration(seconds: retryAfter?.clamp(1, 30) ?? attempt * 2));
    }

    if (response.statusCode == 404) {
      throw const ApiException('No se encontraron personajes.');
    }
    if (response.statusCode == 429) {
      throw const ApiException(
          'Demasiadas solicitudes. Espera un momento e intenta otra vez.');
    }
    if (response.statusCode != 200) {
      throw ApiException('Error del servidor (${response.statusCode}).');
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final info = data['info'] as Map<String, dynamic>;
      final results = (data['results'] as List)
          .map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList();
      return CharacterPage(
        results: results,
        pages: info['pages'] as int,
        count: info['count'] as int,
      );
    } catch (_) {
      throw const ApiException('La respuesta del servidor no es válida.');
    }
  }
}
