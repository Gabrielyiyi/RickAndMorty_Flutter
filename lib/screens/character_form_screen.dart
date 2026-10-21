import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/character.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/character_image.dart';
import '../widgets/decor.dart';
import '../widgets/status_badge.dart';

/// Formulario para agregar (sin [character]) o editar un personaje.
/// Devuelve el personaje guardado al cerrarse.
class CharacterFormScreen extends StatefulWidget {
  const CharacterFormScreen({super.key, this.character});

  final Character? character;

  @override
  State<CharacterFormScreen> createState() => _CharacterFormScreenState();
}

class _CharacterFormScreenState extends State<CharacterFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nameCtrl = TextEditingController(text: widget.character?.name);
  late final _speciesCtrl = TextEditingController(
    text: widget.character?.species,
  );
  late final _typeCtrl = TextEditingController(text: widget.character?.type);
  late final _originCtrl = TextEditingController(
    text: widget.character?.origin,
  );
  late final _locationCtrl = TextEditingController(
    text: widget.character?.location,
  );
  late final _imageCtrl = TextEditingController(text: widget.character?.image);

  late String? _status = widget.character?.status;
  late String? _gender = widget.character?.gender;

  bool _dirty = false;

  bool get _isEditing => widget.character != null;

  List<TextEditingController> get _controllers => [
    _nameCtrl,
    _speciesCtrl,
    _typeCtrl,
    _originCtrl,
    _locationCtrl,
    _imageCtrl,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Revisa los campos marcados en rojo'),
            backgroundColor: AppColors.dead,
          ),
        );
      return;
    }

    final repository = AppScope.of(context).repository;
    String clean(TextEditingController c) =>
        c.text.trim().replaceAll(RegExp(r'\s+'), ' ');

    final data = Character(
      id: widget.character?.id ?? 0,
      name: clean(_nameCtrl),
      status: _status!,
      species: clean(_speciesCtrl),
      type: clean(_typeCtrl),
      gender: _gender!,
      origin: clean(_originCtrl),
      location: clean(_locationCtrl),
      image: _imageCtrl.text.trim(),
      episodes: widget.character?.episodes ?? 0,
      created: widget.character?.created,
      isLocal: widget.character?.isLocal ?? true,
      isEdited: widget.character?.isEdited ?? false,
    );

    try {
      final Character saved;
      if (_isEditing) {
        repository.update(data);
        saved = data;
      } else {
        saved = repository.add(data);
      }
      _dirty = false;
      Navigator.of(context).pop(saved);
    } on StateError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.dead),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.amber,
          size: 32,
        ),
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Los datos que ingresaste se perderán.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context).repository;

    return PopScope<Character>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) {
          setState(() => _dirty = false);
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar personaje' : 'Nuevo personaje'),
          actions: [
            if (_dirty)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Sin guardar',
                    style: TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              onPressed: _save,
              icon: Icon(
                _isEditing ? Icons.save_rounded : Icons.add_circle_rounded,
              ),
              label: Text(_isEditing ? 'Guardar cambios' : 'Agregar personaje'),
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LivePreview(
                      listenable: Listenable.merge(_controllers),
                      name: () => _nameCtrl.text,
                      species: () => _speciesCtrl.text,
                      origin: () => _originCtrl.text,
                      image: () => _imageCtrl.text,
                      status: _status,
                      gender: _gender,
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      icon: Icons.badge_rounded,
                      title: 'Identidad',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 50,
                            decoration: const InputDecoration(
                              labelText: 'Nombre *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) {
                              final error = Validators.characterName(v);
                              if (error != null) return error;
                              if (repository.nameExists(
                                v!,
                                excludeId: widget.character?.id,
                              )) {
                                return 'Ya existe un personaje con ese nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _speciesCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 30,
                            decoration: const InputDecoration(
                              labelText: 'Especie *',
                              hintText: 'Ej: Human, Alien, Robot',
                              prefixIcon: Icon(Icons.pets),
                            ),
                            validator: Validators.species,
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _typeCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            maxLength: 40,
                            decoration: const InputDecoration(
                              labelText: 'Tipo / subespecie (opcional)',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            validator: Validators.type,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      icon: Icons.monitor_heart_rounded,
                      title: 'Estado y género',
                      color: const Color(0xFFE88BF0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Estado *'),
                          _ChipSelector(
                            initialValue: _status,
                            options: Character.statuses,
                            labelOf: Character.statusLabel,
                            colorOf: AppColors.status,
                            iconOf: (s) => switch (s) {
                              'Alive' => Icons.favorite_rounded,
                              'Dead' => Icons.heart_broken_rounded,
                              _ => Icons.help_rounded,
                            },
                            validator: (v) =>
                                Validators.dropdown(v, 'un estado'),
                            onChanged: (v) => setState(() {
                              _status = v;
                              _dirty = true;
                            }),
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('Género *'),
                          _ChipSelector(
                            initialValue: _gender,
                            options: Character.genders,
                            labelOf: Character.genderLabel,
                            colorOf: (_) => const Color(0xFFE88BF0),
                            iconOf: (g) => switch (g) {
                              'Female' => Icons.female_rounded,
                              'Male' => Icons.male_rounded,
                              'Genderless' => Icons.block_rounded,
                              _ => Icons.question_mark_rounded,
                            },
                            validator: (v) =>
                                Validators.dropdown(v, 'un género'),
                            onChanged: (v) => setState(() {
                              _gender = v;
                              _dirty = true;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      icon: Icons.travel_explore_rounded,
                      title: 'Ubicación',
                      color: AppColors.cyan,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _originCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'Origen *',
                              hintText: 'Ej: Earth (C-137)',
                              prefixIcon: Icon(Icons.public),
                            ),
                            validator: Validators.origin,
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _locationCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'Última ubicación (opcional)',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                            validator: Validators.location,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      icon: Icons.image_rounded,
                      title: 'Imagen',
                      color: Colors.amber,
                      child: TextFormField(
                        controller: _imageCtrl,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'URL de la imagen (opcional)',
                          hintText: 'https://...',
                          helperText: 'Si la dejas vacía se usará una imagen por defecto',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        validator: Validators.imageUrl,
                        onFieldSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '* Campos obligatorios',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Selector de una opción con chips de color, integrado en la validación del Form.
class _ChipSelector extends FormField<String> {
  _ChipSelector({
    required super.initialValue,
    required List<String> options,
    required String Function(String) labelOf,
    required Color Function(String) colorOf,
    required IconData Function(String) iconOf,
    required super.validator,
    required ValueChanged<String> onChanged,
  }) : super(
         builder: (field) {
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: [
                   for (final o in options)
                     ChoiceChip(
                       showCheckmark: false,
                       avatar: Icon(
                         iconOf(o),
                         size: 18,
                         color: field.value == o ? Colors.black : colorOf(o),
                       ),
                       label: Text(labelOf(o)),
                       selected: field.value == o,
                       selectedColor: colorOf(o),
                       labelStyle: TextStyle(
                         fontWeight: FontWeight.w700,
                         color: field.value == o ? Colors.black : Colors.white,
                       ),
                       side: BorderSide(
                         color: field.hasError
                             ? AppColors.dead
                             : colorOf(o).withValues(alpha: 0.45),
                       ),
                       onSelected: (_) {
                         field.didChange(o);
                         onChanged(o);
                       },
                     ),
                 ],
               ),
               if (field.hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 8, left: 4),
                   child: Text(
                     field.errorText!,
                     style: const TextStyle(
                       color: AppColors.dead,
                       fontSize: 12,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}

/// Vista previa en vivo de cómo se verá el personaje.
class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.listenable,
    required this.name,
    required this.species,
    required this.origin,
    required this.image,
    required this.status,
    required this.gender,
  });

  final Listenable listenable;
  final String Function() name;
  final String Function() species;
  final String Function() origin;
  final String Function() image;
  final String? status;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final url = image().trim();
        final validUrl = url.isNotEmpty && Validators.imageUrl(url) == null;
        final color = status == null
            ? AppColors.portal
            : AppColors.status(status!);
        String or(String v, String fallback) =>
            v.trim().isEmpty ? fallback : v.trim();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.18), AppColors.surface],
            ),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [color, AppColors.cyan, color],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: ClipOval(child: CharacterImage(validUrl ? url : '')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VISTA PREVIA',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      or(name(), 'Nombre del personaje'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${or(species(), 'Especie')} · '
                      '${gender == null ? 'Género' : Character.genderLabel(gender!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.portal,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (status != null) ...[
                          StatusBadge(status!, compact: true),
                          const SizedBox(width: 8),
                        ],
                        const Icon(
                          Icons.public,
                          size: 13,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            or(origin(), 'Origen'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
