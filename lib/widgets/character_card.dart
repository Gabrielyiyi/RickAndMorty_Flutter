import 'package:flutter/material.dart';

import '../models/character.dart';
import '../theme/app_theme.dart';
import 'character_image.dart';
import 'status_badge.dart';

enum _CardAction { edit, delete }

/// Card del catálogo con la información esencial del personaje.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.character,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Character character;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = character;
    final statusColor = AppColors.status(c.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shadowColor: statusColor.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: 'character-${c.id}', child: CharacterImage(c.image)),
                  // Degradado inferior para que el texto sea legible.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent, Color(0xE6000000)],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(left: 8, top: 8, child: StatusBadge(c.status, compact: true)),
                  Positioned(right: 4, top: 4, child: _menu()),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c.isLocal || c.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _Tag(c.isLocal ? 'NUEVO' : 'EDITADO'),
                          ),
                        Text(
                          c.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.species} · ${c.genderText}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.portal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              color: AppColors.surfaceHigh.withValues(alpha: 0.6),
              child: Row(
                children: [
                  const Icon(Icons.public, size: 14, color: AppColors.cyan),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      c.origin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  if (c.episodes > 0) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.movie_outlined, size: 14, color: Colors.white54),
                    const SizedBox(width: 3),
                    Text(
                      '${c.episodes}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu() {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: PopupMenuButton<_CardAction>(
        tooltip: 'Opciones',
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        onSelected: (action) => action == _CardAction.edit ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _CardAction.edit,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _CardAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.dead),
              title: Text('Eliminar', style: TextStyle(color: AppColors.dead)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.cyan, Color(0xFF7BE0F5)]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
