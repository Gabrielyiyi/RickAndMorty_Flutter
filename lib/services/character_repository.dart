import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/character.dart';
import 'api_service.dart';

enum CharacterSort { api, nameAsc, nameDesc }

/// Criterios de búsqueda/filtro del catálogo. `null` significa "todos".
class CharacterFilter {
  final String query;
  final String? status;
  final String? gender;
  final String? species;
  final bool onlyMine;
  final CharacterSort sort;

  const CharacterFilter({
    this.query = '',
    this.status,
    this.gender,
    this.species,
    this.onlyMine = false,
    this.sort = CharacterSort.api,
  });

  /// Cantidad de filtros activos (sin contar el texto de búsqueda).
  int get activeCount =>
      (status != null ? 1 : 0) +
      (gender != null ? 1 : 0) +
      (species != null ? 1 : 0) +
      (onlyMine ? 1 : 0) +
      (sort != CharacterSort.api ? 1 : 0);

  bool matches(Character c) {
    if (status != null && c.status != status) return false;
    if (gender != null && c.gender != gender) return false;
    if (species != null && c.species.toLowerCase() != species!.toLowerCase()) {
      return false;
    }
    if (onlyMine && !c.isLocal && !c.isEdited) return false;

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    // Busca por nombre, especie, tipo, origen y ubicación.
    return c.name.toLowerCase().contains(q) ||
        c.species.toLowerCase().contains(q) ||
        c.type.toLowerCase().contains(q) ||
        c.origin.toLowerCase().contains(q) ||
        c.location.toLowerCase().contains(q);
  }
}

/// Fuente única de verdad de los personajes.
///
/// Descarga el catálogo de la API y mantiene, por separado, los cambios del
/// usuario (creados, editados y eliminados). Así, al refrescar desde la API
/// los cambios locales no se pierden.
class CharacterRepository extends ChangeNotifier {
  CharacterRepository(this._api);

  final RickAndMortyApi _api;

  /// Páginas que se descargan en paralelo. Es bajo a propósito: la API limita
  /// las peticiones por segundo y las imágenes también consumen ese límite.
  static const _batchSize = 2;

  final List<Character> _remote = [];
  final List<Character> _created = [];
  final Map<int, Character> _edited = {};
  final Set<int> _deleted = {};

  int _nextLocalId = 100000;
  int _loadToken = 0;

  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;
  int loadedPages = 0;
  int totalPages = 0;
  int remoteCount = 0;

  bool get hasData => _remote.isNotEmpty || _created.isNotEmpty;
  bool get isComplete => totalPages > 0 && loadedPages >= totalPages;

  /// Catálogo visible: creados primero, luego los de la API con sus ediciones.
  List<Character> get all => [
        ..._created,
        for (final c in _remote)
          if (!_deleted.contains(c.id)) _edited[c.id] ?? c,
      ];

  List<Character> search(CharacterFilter filter) {
    final result = all.where(filter.matches).toList();
    switch (filter.sort) {
      case CharacterSort.nameAsc:
        result.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case CharacterSort.nameDesc:
        result.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case CharacterSort.api:
        break;
    }
    return result;
  }

  /// Especies existentes (para el filtro), ordenadas alfabéticamente.
  List<String> get speciesList {
    final set = <String>{for (final c in all) c.species.trim()}
      ..removeWhere((s) => s.isEmpty);
    return set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Character? byId(int id) {
    for (final c in _created) {
      if (c.id == id) return c;
    }
    if (_deleted.contains(id)) return null;
    if (_edited.containsKey(id)) return _edited[id];
    for (final c in _remote) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Comprueba si ya existe un personaje con el mismo nombre (sin distinguir
  /// mayúsculas), ignorando el personaje [excludeId] al editar.
  bool nameExists(String name, {int? excludeId}) {
    final n = name.trim().toLowerCase();
    return all.any((c) => c.id != excludeId && c.name.toLowerCase() == n);
  }

  // ---------------------------------------------------------------- Carga

  /// Carga la primera página y muestra resultados de inmediato; el resto del
  /// catálogo se descarga en segundo plano.
  Future<void> load() async {
    final token = ++_loadToken;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final first = await _api.fetchPage(1);
      if (token != _loadToken) return;
      _remote
        ..clear()
        ..addAll(first.results);
      loadedPages = 1;
      totalPages = first.pages;
      remoteCount = first.count;
    } on ApiException catch (e) {
      if (token == _loadToken) error = e.message;
      return;
    } finally {
      if (token == _loadToken) {
        isLoading = false;
        notifyListeners();
      }
    }

    await _loadRemaining(token);
  }

  /// Reintenta descargar las páginas que faltan tras un error.
  Future<void> resumeLoading() => _loadRemaining(_loadToken);

  Future<void> _loadRemaining(int token) async {
    if (isLoadingMore || isComplete) return;
    isLoadingMore = true;
    error = null;
    notifyListeners();

    try {
      while (loadedPages < totalPages) {
        final start = loadedPages + 1;
        final end = min(loadedPages + _batchSize, totalPages);
        final pages = await Future.wait([
          for (var p = start; p <= end; p++) _api.fetchPage(p),
        ]);
        if (token != _loadToken) return;
        for (final page in pages) {
          _remote.addAll(page.results);
        }
        loadedPages = end;
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (token == _loadToken) error = e.message;
    } finally {
      if (token == _loadToken) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------- CRUD

  Character add(Character data) {
    final character = data.copyWith(
      id: _nextLocalId++,
      isLocal: true,
      created: DateTime.now(),
    );
    _created.insert(0, character);
    notifyListeners();
    return character;
  }

  void update(Character character) {
    if (character.isLocal) {
      final i = _created.indexWhere((c) => c.id == character.id);
      if (i == -1) throw StateError('El personaje ya no existe.');
      _created[i] = character;
    } else {
      if (_deleted.contains(character.id)) {
        throw StateError('El personaje ya no existe.');
      }
      _edited[character.id] = character.copyWith(isEdited: true);
    }
    notifyListeners();
  }

  /// Elimina el personaje y devuelve una función para deshacer la acción.
  VoidCallback delete(Character character) {
    if (character.isLocal) {
      final index = _created.indexWhere((c) => c.id == character.id);
      if (index == -1) return () {};
      final removed = _created.removeAt(index);
      notifyListeners();
      return () {
        _created.insert(min(index, _created.length), removed);
        notifyListeners();
      };
    }

    _deleted.add(character.id);
    notifyListeners();
    return () {
      _deleted.remove(character.id);
      notifyListeners();
    };
  }
}
