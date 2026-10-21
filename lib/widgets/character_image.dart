import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/image_loader.dart';
import '../theme/app_theme.dart';

/// Imagen de red con cola de descargas, reintentos y caché ([ImageLoader]).
/// Muestra un indicador mientras carga y un respaldo si falla o está vacía.
class CharacterImage extends StatefulWidget {
  const CharacterImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  State<CharacterImage> createState() => _CharacterImageState();
}

class _CharacterImageState extends State<CharacterImage> {
  ImageRequest? _request;
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CharacterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  @override
  void dispose() {
    // La imagen salió de pantalla: libera su lugar en la cola.
    _request?.cancel();
    super.dispose();
  }

  void _load() {
    _request?.cancel();
    _request = null;
    _failed = false;
    _bytes = null;

    final url = widget.url.trim();
    if (url.isEmpty) return;

    // Si ya está en caché se muestra de inmediato (sin parpadeo).
    _bytes = ImageLoader.instance.cached(url);
    if (_bytes != null) return;

    final request = ImageLoader.instance.load(url);
    _request = request;
    request.future.then((bytes) {
      if (mounted && _request == request) setState(() => _bytes = bytes);
    }, onError: (Object e) {
      if (mounted && _request == request && e is! ImageCancelled) {
        setState(() => _failed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.trim().isEmpty) return const _Placeholder();
    if (_failed) {
      return _Placeholder(broken: true, onRetry: () => setState(_load));
    }
    final bytes = _bytes;
    if (bytes == null) {
      return Container(
        color: AppColors.surfaceHigh,
        alignment: Alignment.center,
        child: const SizedBox.square(
          dimension: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return Image.memory(
      bytes,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      // Los bytes no son una imagen válida (p. ej. URL a una página web).
      errorBuilder: (_, _, _) => const _Placeholder(broken: true),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.broken = false, this.onRetry});

  final bool broken;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F3A1A), Color(0xFF12313A)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            broken ? Icons.broken_image_outlined : Icons.person_rounded,
            size: 56,
            color: AppColors.portal.withValues(alpha: 0.7),
          ),
          if (onRetry != null)
            const Text(
              'Toca para reintentar',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            ),
        ],
      ),
    );
    if (onRetry == null) return content;
    return GestureDetector(onTap: onRetry, child: content);
  }
}
