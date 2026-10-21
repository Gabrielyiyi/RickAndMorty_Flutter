import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Descargador de imágenes con cola, reintentos y caché en memoria.
///
/// La API de Rick and Morty responde `429 Too Many Requests` cuando recibe
/// muchas peticiones simultáneas (por ejemplo, al mostrar una cuadrícula de
/// imágenes). Para evitarlo:
///  * se limita el número de descargas en paralelo,
///  * ante un 429 se pausa la cola y se reintenta (respetando `Retry-After`),
///  * las imágenes ya descargadas se guardan en caché,
///  * las peticiones de imágenes que salieron de pantalla se cancelan.
class ImageLoader {
  ImageLoader._();

  static final ImageLoader instance = ImageLoader._();

  static const _maxConcurrent = 4;
  static const _maxCached = 400;
  static const _maxAttempts = 6;
  static const _timeout = Duration(seconds: 20);

  final http.Client _client = http.Client();
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  final Map<String, _Job> _jobs = {};
  final ListQueue<_Job> _queue = ListQueue();

  int _active = 0;
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _resumeTimer;

  /// Imagen en caché (para mostrarla sin parpadeo), o `null`.
  Uint8List? cached(String url) {
    final bytes = _cache.remove(url);
    if (bytes != null) _cache[url] = bytes; // marca como usada recientemente
    return bytes;
  }

  /// Pide una imagen. Llama a [ImageRequest.cancel] si ya no se necesita.
  ImageRequest load(String url) {
    final bytes = cached(url);
    if (bytes != null) return ImageRequest._done(bytes);

    final job = _jobs.putIfAbsent(url, () {
      final created = _Job(url);
      _queue.add(created);
      return created;
    });
    job.waiters++;
    _pump();
    return ImageRequest._(job.completer.future, () => _cancel(job));
  }

  void _cancel(_Job job) {
    job.waiters--;
    if (job.waiters > 0 || job.running) return;
    // Nadie la espera y aún no empezó: se saca de la cola.
    _queue.remove(job);
    _jobs.remove(job.url);
    if (!job.completer.isCompleted) {
      job.completer.completeError(const ImageCancelled());
    }
  }

  void _pump() {
    final wait = _pausedUntil.difference(DateTime.now());
    if (wait > Duration.zero) {
      _resumeTimer ??= Timer(wait, () {
        _resumeTimer = null;
        _pump();
      });
      return;
    }
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      _run(_queue.removeFirst());
    }
  }

  Future<void> _run(_Job job) async {
    _active++;
    job.running = true;
    job.attempts++;

    Duration? retryIn;
    try {
      final res = await _client.get(Uri.parse(job.url)).timeout(_timeout);
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _store(job.url, res.bodyBytes);
        _finish(job);
        job.completer.complete(res.bodyBytes);
      } else if (res.statusCode == 429 || res.statusCode >= 500) {
        retryIn = _retryDelay(job.attempts, res.headers['retry-after']);
        if (res.statusCode == 429) {
          // Límite alcanzado: pausa toda la cola, no solo esta imagen.
          _pausedUntil = DateTime.now().add(retryIn);
        }
      } else {
        _fail(job, 'HTTP ${res.statusCode}');
      }
    } catch (e) {
      retryIn = _retryDelay(job.attempts, null);
    }

    if (retryIn != null) {
      job.running = false;
      if (job.attempts >= _maxAttempts) {
        _fail(job, 'Demasiados intentos');
      } else if (job.waiters <= 0) {
        _fail(job, 'Cancelada');
      } else if (_pausedUntil.isAfter(DateTime.now())) {
        // 429: la cola está en pausa; la imagen conserva su prioridad.
        _queue.addFirst(job);
      } else {
        // Fallo puntual: se reintenta solo esta imagen tras la espera.
        Timer(retryIn, () {
          if (job.completer.isCompleted) return; // se canceló mientras tanto
          _queue.addFirst(job);
          _pump();
        });
      }
    }

    _active--;
    _pump();
  }

  Duration _retryDelay(int attempt, String? retryAfter) {
    final seconds = int.tryParse(retryAfter ?? '');
    if (seconds != null) return Duration(seconds: seconds.clamp(1, 30));
    // Espera exponencial: 1s, 2s, 4s, 8s... (máx. 15s) + un poco de azar.
    final ms = min(15000, 1000 * pow(2, attempt - 1).toInt());
    return Duration(milliseconds: ms + Random().nextInt(400));
  }

  void _store(String url, Uint8List bytes) {
    _cache[url] = bytes;
    while (_cache.length > _maxCached) {
      _cache.remove(_cache.keys.first);
    }
  }

  void _finish(_Job job) {
    job.running = false;
    _jobs.remove(job.url);
  }

  void _fail(_Job job, String reason) {
    _finish(job);
    if (job.completer.isCompleted) return;
    job.completer.completeError(ImageLoadException(reason));
  }
}

class _Job {
  _Job(this.url) {
    // Evita errores "no manejados" si nadie escucha cuando falla.
    completer.future.ignore();
  }

  final String url;
  final Completer<Uint8List> completer = Completer();
  int waiters = 0;
  int attempts = 0;
  bool running = false;
}

/// Petición de una imagen que puede cancelarse.
class ImageRequest {
  ImageRequest._(this.future, this._onCancel);
  ImageRequest._done(Uint8List bytes)
      : future = SynchronousFuture(bytes),
        _onCancel = null;

  final Future<Uint8List> future;
  final VoidCallback? _onCancel;
  bool _cancelled = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel?.call();
  }
}

class ImageLoadException implements Exception {
  const ImageLoadException(this.reason);
  final String reason;

  @override
  String toString() => 'No se pudo cargar la imagen: $reason';
}

class ImageCancelled implements Exception {
  const ImageCancelled();
}
