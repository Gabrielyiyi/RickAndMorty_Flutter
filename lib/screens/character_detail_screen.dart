import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/character.dart';
import '../theme/app_theme.dart';
import '../widgets/character_actions.dart';
import '../widgets/character_image.dart';
import '../widgets/decor.dart';
import '../widgets/status_badge.dart';

/// Total de episodios de la serie según la API (para la barra de apariciones).
const _totalEpisodes = 51;

/// UI "Detalles" de un personaje. Se actualiza sola si el personaje se edita.
class CharacterDetailScreen extends StatelessWidget {
  const CharacterDetailScreen({super.key, required this.characterId});

  final int characterId;

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context).repository;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final c = repository.byId(characterId);
        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Este personaje ya no existe.')),
          );
        }
        return _DetailView(character: c);
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.character});

  final Character character;

  static const _expandedHeight = 330.0;

  Future<void> _delete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final deleted = await CharacterActions.confirmDelete(context, character);
    if (deleted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = character;
    final statusColor = AppColors.status(c.status);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: _expandedHeight,
            backgroundColor: AppColors.background,
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => CharacterActions.openForm(context, character: c),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_rounded, color: AppColors.dead),
                onPressed: () => _delete(context),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = MediaQuery.paddingOf(context).top;
                // 1 = expandido, 0 = colapsado.
                final t = ((constraints.maxHeight - kToolbarHeight - top) /
                        (_expandedHeight - kToolbarHeight))
                    .clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _BlurredBackdrop(c.image, statusColor),
                    Opacity(
                      opacity: t,
                      child: Padding(
                        padding: EdgeInsets.only(top: top + 24),
                        child: Center(child: _Avatar(c, statusColor, size: 150 * (0.6 + 0.4 * t))),
                      ),
                    ),
                    Positioned(
                      left: 56,
                      right: 110,
                      top: top,
                      height: kToolbarHeight,
                      child: Opacity(
                        opacity: (1 - t * 2).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(child: _Title(c)),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: _QuickStats(c, statusColor),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: SectionCard(
                          icon: Icons.fingerprint_rounded,
                          title: 'Datos personales',
                          child: _TileGrid([
                            _InfoTile(Icons.pets_rounded, 'Especie', c.species, AppColors.portal),
                            _InfoTile(Icons.category_rounded, 'Tipo',
                                c.type.isEmpty ? 'Sin especificar' : c.type, AppColors.cyan),
                            _InfoTile(Icons.wc_rounded, 'Género', c.genderText,
                                const Color(0xFFE88BF0)),
                            _InfoTile(Icons.monitor_heart_rounded, 'Estado', c.statusText,
                                statusColor),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: SectionCard(
                          icon: Icons.travel_explore_rounded,
                          title: 'Ubicación',
                          color: AppColors.cyan,
                          child: Column(
                            children: [
                              _PlaceRow(Icons.public_rounded, 'Origen', c.origin),
                              const Padding(
                                padding: EdgeInsets.only(left: 19),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    height: 18,
                                    child: VerticalDivider(color: Colors.white24, width: 2),
                                  ),
                                ),
                              ),
                              _PlaceRow(Icons.place_rounded, 'Última ubicación',
                                  c.location.isEmpty ? 'Desconocida' : c.location),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
                        child: SectionCard(
                          icon: Icons.movie_filter_rounded,
                          title: 'Apariciones',
                          color: Colors.amber,
                          child: _Episodes(c),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: SectionCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Registro',
                          color: const Color(0xFFB39DDB),
                          child: _TileGrid([
                            _InfoTile(Icons.event_rounded, 'Fecha', _formatDate(c.created),
                                const Color(0xFFB39DDB)),
                            _InfoTile(
                                Icons.tag_rounded,
                                'Fuente',
                                c.isLocal
                                    ? 'Local #${c.id}'
                                    : 'API #${c.id}${c.isEdited ? ' (editado)' : ''}',
                                const Color(0xFFB39DDB)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  CharacterActions.openForm(context, character: c),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Editar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.dead,
                                side: const BorderSide(color: AppColors.dead),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _delete(context),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Eliminar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return 'Desconocida';
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final local = d.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

/// Imagen del personaje desenfocada y oscurecida como fondo de cabecera.
class _BlurredBackdrop extends StatelessWidget {
  const _BlurredBackdrop(this.url, this.tint);

  final String url;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: CharacterImage(url),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                tint.withValues(alpha: 0.12),
                AppColors.background,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// Foto circular con anillo de color según el estado.
class _Avatar extends StatelessWidget {
  const _Avatar(this.character, this.color, {required this.size});

  final Character character;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [color, AppColors.cyan, color]),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 36, spreadRadius: 2),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: Hero(
          tag: 'character-${character.id}',
          child: ClipOval(child: CharacterImage(character.image)),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.c);

  final Character c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          c.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge(c.status),
            if (c.isLocal) const _Pill(Icons.fiber_new_rounded, 'Creado por ti'),
            if (c.isEdited) const _Pill(Icons.edit_note_rounded, 'Editado'),
          ],
        ),
      ],
    );
  }
}

/// Resumen rápido en tres columnas.
class _QuickStats extends StatelessWidget {
  const _QuickStats(this.c, this.statusColor);

  final Character c;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    Widget item(String value, String label, Color color) => Expanded(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900, color: color)),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        );

    Widget divider() => Container(width: 1, height: 34, color: Colors.white12);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          statusColor.withValues(alpha: 0.12),
          AppColors.surface,
          AppColors.cyan.withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          item(c.species, 'Especie', AppColors.portal),
          divider(),
          item(c.genderText, 'Género', const Color(0xFFE88BF0)),
          divider(),
          item(c.isLocal ? '—' : '${c.episodes}', 'Episodios', Colors.amber),
        ],
      ),
    );
  }
}

/// Cuadrícula de 2 columnas que se adapta al ancho disponible.
class _TileGrid extends StatelessWidget {
  const _TileGrid(this.tiles);

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 10.0;
      final columns = constraints.maxWidth > 520 ? 4 : 2;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final t in tiles) SizedBox(width: width, child: t)],
      );
    });
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.icon, this.label, this.value, this.color);

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBox(icon, color: AppColors.cyan, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra con la proporción de episodios en los que aparece.
class _Episodes extends StatelessWidget {
  const _Episodes(this.c);

  final Character c;

  @override
  Widget build(BuildContext context) {
    if (c.isLocal) {
      return const Text(
        'Personaje creado por ti: no tiene episodios registrados en la serie.',
        style: TextStyle(color: Colors.white60),
      );
    }
    final ratio = (c.episodes / _totalEpisodes).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${c.episodes}',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Colors.amber)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                c.episodes == 1 ? 'episodio de $_totalEpisodes' : 'episodios de $_totalEpisodes',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('${(ratio * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              color: Colors.amber,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.cyan),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
