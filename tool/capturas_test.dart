// Genera capturas de pantalla de la app con datos e imágenes reales de la API.
//
// Uso:
//   flutter test tool/capturas_test.dart \
//     --dart-define=FLUTTER_ROOT=C:/flutter --dart-define=OUT=<carpeta destino>
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rick_morty/main.dart';
import 'package:rick_morty/services/api_service.dart';
import 'package:rick_morty/services/auth_service.dart';
import 'package:rick_morty/services/character_repository.dart';
import 'package:rick_morty/services/image_loader.dart';

const _flutterRoot = String.fromEnvironment('FLUTTER_ROOT');
const _out = String.fromEnvironment('OUT', defaultValue: 'tool/capturas');
const _ratio = 2.625;
final _shotKey = GlobalKey();

Future<void> _loadFonts() async {
  final dir = '$_flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black', 'light']) {
    final bytes = File('$dir/roboto-$w.ttf').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(
        ByteData.sublistView(File('$dir/materialicons-regular.otf').readAsBytesSync())));
  await icons.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 900));
  // Deja que se decodifiquen las imágenes (trabajo asíncrono real).
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
  await tester.pump(const Duration(milliseconds: 50));
  final boundary =
      _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
  // ignore: avoid_print
  print('captura: $_out/$name.png');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(finder);
  // Dos cuadros: en el primero la ruta nueva se construye oculta (Hero).
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null; // permite peticiones reales
    await _loadFonts();
  });

  testWidgets('capturas', (tester) async {
    tester.view.physicalSize = const Size(411 * _ratio, 891 * _ratio);
    tester.view.devicePixelRatio = _ratio;
    addTearDown(tester.view.reset);
    // En pruebas las sombras se dibujan como bordes negros; se activan las reales.
    debugDisableShadows = false;

    // Primera página real de la API; se sirve como única página.
    final body = await tester.runAsync(() async {
      final res = await http.get(Uri.parse('${RickAndMortyApi.baseUrl}?page=1'));
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      (json['info'] as Map<String, dynamic>)['pages'] = 1;
      for (final c in json['results'] as List) {
        await ImageLoader.instance.load(c['image'] as String).future;
      }
      return jsonEncode(json);
    });
    final api = RickAndMortyApi(
      client: MockClient((_) async => http.Response.bytes(utf8.encode(body!), 200,
          headers: {'content-type': 'application/json; charset=utf-8'})),
    );

    await tester.pumpWidget(RepaintBoundary(
      key: _shotKey,
      child: RickMortyApp(auth: AuthService(), repository: CharacterRepository(api)),
    ));

    // Login vacío y con errores de validación.
    await _shot(tester, '01_login');
    await _tap(tester, find.text('Ingresar'));
    await _shot(tester, '02_login_validacion');

    // Credenciales incorrectas.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), 'clave_mala');
    await _tap(tester, find.text('Ingresar'));
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, '03_login_incorrecto');

    // Registro.
    await _tap(tester, find.text('Regístrate'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextFormField).at(0), 'Morty Smith');
    await tester.enterText(find.byType(TextFormField).at(1), 'morty');
    await tester.enterText(find.byType(TextFormField).at(3), 'Morty12');
    await _shot(tester, '04_registro');
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pump(const Duration(seconds: 1));

    // Login correcto.
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), AuthService.defaultPassword);
    await _tap(tester, find.text('Ingresar'));
    await tester.pump(const Duration(seconds: 2));
    await _shot(tester, '05_personajes');

    // Búsqueda.
    await tester.enterText(find.byType(TextField).first, 'smith');
    await tester.pump(const Duration(milliseconds: 500));
    await _shot(tester, '06_busqueda');
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(milliseconds: 500));

    // Filtros.
    await _tap(tester, find.byTooltip('Filtros'));
    await _tap(tester, find.widgetWithText(ChoiceChip, 'Muerto'));
    await _shot(tester, '07_filtros');
    await _tap(tester, find.text('Aplicar'));
    await _shot(tester, '08_filtrado_muertos');
    await _tap(tester, find.text('Limpiar todo'));

    // Detalles.
    await tester.tap(find.text('Rick Sanchez').first);
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, '09_detalle');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -560));
    await _shot(tester, '10_detalle_info');

    // Editar desde el detalle.
    await _tap(tester, find.byTooltip('Editar'));
    await _shot(tester, '11_editar');
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pump(const Duration(seconds: 1));
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pump(const Duration(seconds: 1));


    // Agregar: validaciones y formulario lleno.
    await _tap(tester, find.text('Agregar'));
    await _tap(tester, find.text('Agregar personaje'));
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -3000));
    await _shot(tester, '12_agregar_validacion');
    // Espera a que se oculte el aviso "Revisa los campos" (tapa los chips).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    Future<void> enter(String label, String text) async {
      final f = find.widgetWithText(TextFormField, label);
      await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
      await tester.enterText(f, text);
    }

    await enter('Nombre *', 'Pickle Rick');
    await enter('Especie *', 'Pickle');
    await enter('Origen *', 'Earth (C-137)');
    await enter('Última ubicación (opcional)', 'Smith Garage');
    // Sin foco, el campo activo deja de desplazar la vista hacia sí mismo.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    for (final o in ['Vivo', 'Masculino']) {
      await _tap(tester, find.widgetWithText(ChoiceChip, o));
    }
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -3000));
    await _shot(tester, '13_agregar_lleno');
    await _tap(tester, find.text('Agregar personaje'));
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, '14_agregado');

    // Eliminar.
    await tester.tap(find.byTooltip('Opciones').first);
    await tester.pump(const Duration(milliseconds: 600));
    await _shot(tester, '15_menu_card');
    await tester.tap(find.text('Eliminar').last);
    await tester.pump(const Duration(milliseconds: 600));
    await _shot(tester, '16_eliminar_confirmar');
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pump(const Duration(milliseconds: 800));
    await _shot(tester, '17_eliminado_deshacer');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    debugDisableShadows = true;
  }, timeout: const Timeout(Duration(minutes: 5)));
}
