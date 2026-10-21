import 'package:flutter/widgets.dart';

import 'services/auth_service.dart';
import 'services/character_repository.dart';

/// Expone los servicios de la app a todo el árbol de widgets.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.repository,
    required super.child,
  });

  final AuthService auth;
  final CharacterRepository repository;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró AppScope en el contexto');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth || repository != oldWidget.repository;
}
