import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/character.dart';
import '../screens/character_form_screen.dart';
import '../theme/app_theme.dart';

/// Acciones compartidas entre la lista y el detalle de un personaje.
class CharacterActions {
  CharacterActions._();

  /// Abre el formulario para crear (sin [character]) o editar un personaje.
  static Future<void> openForm(BuildContext context, {Character? character}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<Character>(
      MaterialPageRoute(
        builder: (_) => CharacterFormScreen(character: character),
      ),
    );
    if (saved == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(character == null
            ? '"${saved.name}" fue agregado al catálogo'
            : 'Cambios de "${saved.name}" guardados'),
      ));
  }

  /// Pide confirmación, elimina y ofrece "Deshacer".
  /// Devuelve `true` si el personaje fue eliminado.
  static Future<bool> confirmDelete(BuildContext context, Character character) async {
    final repository = AppScope.of(context).repository;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded,
            color: AppColors.dead, size: 36),
        title: const Text('Eliminar personaje'),
        content: Text(
          '¿Seguro que deseas eliminar a "${character.name}" del catálogo?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dead,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final undo = repository.delete(character);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('"${character.name}" fue eliminado'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'DESHACER', onPressed: undo),
      ));
    return true;
  }
}
