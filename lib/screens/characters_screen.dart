import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/character.dart';
import '../services/character_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/character_actions.dart';
import '../widgets/character_card.dart';
import '../widgets/decor.dart';
import 'character_detail_screen.dart';
import 'login_screen.dart';

/// UI "Personajes": catálogo con búsqueda, filtros y CRUD.
class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  CharacterFilter _filter = const CharacterFilter();
  late final CharacterRepository _repo;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _repo = AppScope.of(context).repository;
    if (!_repo.hasData && !_repo.isLoading) _repo.load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    // Espera a que el usuario deje de escribir para filtrar.
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _filter = _copy(query: text));
    });
  }

  /// Copia el filtro actual cambiando solo lo indicado.
  CharacterFilter _copy({
    String? query,
    String? status,
    bool clearStatus = false,
    bool clearGender = false,
    bool clearSpecies = false,
    bool clearMine = false,
    bool clearSort = false,
  }) {
    final f = _filter;
    return CharacterFilter(
      query: query ?? f.query,
      status: clearStatus ? null : (status ?? f.status),
      gender: clearGender ? null : f.gender,
      species: clearSpecies ? null : f.species,
      onlyMine: clearMine ? false : f.onlyMine,
      sort: clearSort ? CharacterSort.api : f.sort,
    );
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() => _filter = const CharacterFilter());
  }

  /// Al tocar una ficha de estadística se filtra por ese estado (o se quita).
  void _toggleStatus(String? status) {
    setState(() {
      _filter = status == null || _filter.status == status
          ? _copy(clearStatus: true)
          : _copy(status: status);
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<CharacterFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _FilterSheet(
        initial: _filter,
        speciesOptions: _repo.speciesList,
      ),
    );
    if (result != null) setState(() => _filter = result);
  }

  void _openDetail(Character c) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CharacterDetailScreen(characterId: c.id),
    ));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.portal, size: 32),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    AppScope.of(context).auth.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CharacterActions.openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          final all = _repo.all;
          final results = _repo.search(_filter);
          return RefreshIndicator(
            onRefresh: _repo.load,
            edgeOffset: 120,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildHeader(all)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedDelegate(height: 72, child: _buildSearchBar()),
                ),
                if (_filter.activeCount > 0)
                  SliverToBoxAdapter(child: _buildActiveFilters()),
                SliverToBoxAdapter(child: _buildStatusLine(results.length, all.length)),
                ..._buildContent(results),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    final user = AppScope.of(context).auth.currentUser;
    final initial =
        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : '?';

    return SliverAppBar(
      floating: true,
      titleSpacing: 16,
      title: const Row(
        children: [
          Icon(Icons.cyclone_rounded, color: AppColors.portal, size: 28),
          SizedBox(width: 8),
          Flexible(child: Text('Personajes', overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Recargar desde la API',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => _repo.load(),
        ),
        PopupMenuButton<String>(
          tooltip: 'Cuenta',
          offset: const Offset(0, 48),
          icon: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.portal, AppColors.cyan]),
            ),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.background,
              child: Text(initial,
                  style: const TextStyle(
                      color: AppColors.portal, fontWeight: FontWeight.w900)),
            ),
          ),
          onSelected: (_) => _logout(),
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(user?.fullName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('@${user?.username ?? ''}'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Cerrar sesión'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(List<Character> all) {
    final user = AppScope.of(context).auth.currentUser;
    final firstName = (user?.fullName ?? '').split(' ').first;
    int count(String s) => all.where((c) => c.status == s).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName.isEmpty ? '¡Hola!' : '¡Hola, $firstName!',
            style: const TextStyle(color: Colors.white60, fontSize: 15),
          ),
          const SizedBox(height: 2),
          const GradientText(
            'Explora el multiverso',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatTile(
                label: 'Total',
                value: all.length,
                icon: Icons.groups_rounded,
                color: AppColors.portal,
                selected: _filter.status == null,
                onTap: () => _toggleStatus(null),
              ),
              const SizedBox(width: 8),
              for (final (i, s) in Character.statuses.indexed) ...[
                _StatTile(
                  label: Character.statusLabel(s),
                  value: count(s),
                  icon: switch (s) {
                    'Alive' => Icons.favorite_rounded,
                    'Dead' => Icons.heart_broken_rounded,
                    _ => Icons.help_rounded,
                  },
                  color: AppColors.status(s),
                  selected: _filter.status == s,
                  onTap: () => _toggleStatus(s),
                ),
                if (i < Character.statuses.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _searchCtrl,
              builder: (context, value, _) => TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, especie, origen...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.portal),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Badge.count(
            count: _filter.activeCount,
            isLabelVisible: _filter.activeCount > 0,
            backgroundColor: AppColors.cyan,
            textColor: Colors.black,
            child: IconButton.filled(
              tooltip: 'Filtros',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceHigh,
                foregroundColor: AppColors.portal,
                fixedSize: const Size(54, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openFilters,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final f = _filter;

    Widget chip(String label, IconData icon, CharacterFilter next) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            avatar: Icon(icon, size: 16, color: AppColors.portal),
            label: Text(label),
            backgroundColor: AppColors.portal.withValues(alpha: 0.1),
            side: BorderSide(color: AppColors.portal.withValues(alpha: 0.35)),
            onDeleted: () => setState(() => _filter = next),
          ),
        );

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (f.status != null)
            chip(Character.statusLabel(f.status!), Icons.favorite_outline,
                _copy(clearStatus: true)),
          if (f.gender != null)
            chip(Character.genderLabel(f.gender!), Icons.wc, _copy(clearGender: true)),
          if (f.species != null)
            chip(f.species!, Icons.pets, _copy(clearSpecies: true)),
          if (f.onlyMine) chip('Mis cambios', Icons.edit_note, _copy(clearMine: true)),
          if (f.sort != CharacterSort.api)
            chip(f.sort == CharacterSort.nameAsc ? 'A → Z' : 'Z → A',
                Icons.sort_by_alpha, _copy(clearSort: true)),
          TextButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Limpiar todo'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine(int shown, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Mostrando '),
              TextSpan(
                text: '$shown',
                style: const TextStyle(color: AppColors.portal, fontWeight: FontWeight.w800),
              ),
              TextSpan(text: ' de $total personajes'),
            ]),
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          if (_repo.isLoadingMore) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 5,
                backgroundColor: AppColors.surfaceHigh,
                value: _repo.totalPages == 0
                    ? null
                    : _repo.loadedPages / _repo.totalPages,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Descargando catálogo · página ${_repo.loadedPages} de ${_repo.totalPages}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          if (_repo.error != null && _repo.hasData)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catálogo incompleto: ${_repo.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                  TextButton(
                    onPressed: _repo.resumeLoading,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(List<Character> results) {
    if (_repo.isLoading && !_repo.hasData) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PortalLogo(size: 80),
                SizedBox(height: 18),
                Text('Abriendo portal...', style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ),
      ];
    }

    if (_repo.error != null && !_repo.hasData) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageView(
            icon: Icons.wifi_off_rounded,
            title: 'No se pudo cargar el catálogo',
            message: _repo.error!,
            actionLabel: 'Reintentar',
            onAction: _repo.load,
          ),
        ),
      ];
    }

    if (results.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageView(
            icon: Icons.travel_explore_rounded,
            title: 'Sin resultados',
            message: _filter.query.isEmpty && _filter.activeCount == 0
                ? 'Aún no hay personajes. ¡Agrega el primero!'
                : 'Ningún personaje de este universo coincide con tu búsqueda.',
            actionLabel: 'Limpiar filtros',
            onAction: _clearAll,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisExtent: 280,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final c = results[i];
            return FadeSlideIn(
              key: ValueKey(c.id),
              child: CharacterCard(
                character: c,
                onTap: () => _openDetail(c),
                onEdit: () => CharacterActions.openForm(context, character: c),
                onDelete: () => CharacterActions.confirmDelete(context, c),
              ),
            );
          },
        ),
      ),
    ];
  }
}

/// Ficha de estadística (total / vivos / muertos / desconocidos).
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.18) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : Colors.white.withValues(alpha: 0.06),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$value',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mantiene el buscador fijo arriba al hacer scroll.
class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  _PinnedDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_PinnedDelegate oldDelegate) => true;
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.portal.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.portal.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 52, color: AppColors.portal),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

/// Hoja inferior para elegir filtros y orden.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.speciesOptions});

  final CharacterFilter initial;
  final List<String> speciesOptions;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _status = widget.initial.status;
  late String? _gender = widget.initial.gender;
  late String? _species = widget.initial.species;
  late bool _onlyMine = widget.initial.onlyMine;
  late CharacterSort _sort = widget.initial.sort;

  Widget _section(IconData icon, String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(
          children: [
            IconBox(icon, size: 16),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      );

  Widget _choices(List<String> values, String? selected,
      String Function(String) label, ValueChanged<String?> onChanged,
      {Color Function(String)? colorOf}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final v in values)
          ChoiceChip(
            avatar: colorOf == null
                ? null
                : Icon(Icons.circle, size: 12, color: colorOf(v)),
            label: Text(label(v)),
            selected: selected == v,
            onSelected: (_) => onChanged(v),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si la especie seleccionada ya no existe en el catálogo, se ignora.
    final species = widget.speciesOptions.contains(_species) ? _species : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrar personajes',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            _section(Icons.favorite_outline, 'Estado'),
            _choices(Character.statuses, _status, Character.statusLabel,
                (v) => setState(() => _status = v),
                colorOf: AppColors.status),
            _section(Icons.wc, 'Género'),
            _choices(Character.genders, _gender, Character.genderLabel,
                (v) => setState(() => _gender = v)),
            _section(Icons.pets, 'Especie'),
            DropdownButtonFormField<String?>(
              initialValue: species,
              isExpanded: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.pets)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final s in widget.speciesOptions)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _species = v),
            ),
            _section(Icons.sort_by_alpha, 'Ordenar por nombre'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<CharacterSort>(
                segments: const [
                  ButtonSegment(value: CharacterSort.api, label: Text('Original')),
                  ButtonSegment(value: CharacterSort.nameAsc, label: Text('A → Z')),
                  ButtonSegment(value: CharacterSort.nameDesc, label: Text('Z → A')),
                ],
                selected: {_sort},
                onSelectionChanged: (s) => setState(() => _sort = s.first),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo personajes creados o editados por mí'),
              value: _onlyMine,
              onChanged: (v) => setState(() => _onlyMine = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => Navigator.pop(
                      context,
                      CharacterFilter(query: widget.initial.query),
                    ),
                    child: const Text('Restablecer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      CharacterFilter(
                        query: widget.initial.query,
                        status: _status,
                        gender: _gender,
                        species: species,
                        onlyMine: _onlyMine,
                        sort: _sort,
                      ),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
