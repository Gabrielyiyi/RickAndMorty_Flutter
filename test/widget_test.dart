import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rick_morty/main.dart';
import 'package:rick_morty/models/character.dart';
import 'package:rick_morty/services/api_service.dart';
import 'package:rick_morty/services/auth_service.dart';
import 'package:rick_morty/services/character_repository.dart';
import 'package:rick_morty/utils/validators.dart';

/// API falsa: 2 páginas con un personaje cada una.
RickAndMortyApi fakeApi() => RickAndMortyApi(
      client: MockClient((request) async {
        final page = request.url.queryParameters['page'];
        final id = page == '1' ? 1 : 2;
        final name = id == 1 ? 'Rick Sanchez' : 'Morty Smith';
        return http.Response(
          '{"info":{"count":2,"pages":2},"results":[{"id":$id,"name":"$name",'
          '"status":"Alive","species":"Human","type":"","gender":"Male",'
          '"origin":{"name":"Earth"},"location":{"name":"Citadel"},'
          '"image":"","episode":["a","b"],"created":"2017-11-04T18:48:46.250Z"}]}',
          200,
        );
      }),
    );

void main() {
  group('Validators', () {
    test('login no acepta campos vacíos', () {
      expect(Validators.loginUser(''), isNotNull);
      expect(Validators.loginUser('   '), isNotNull);
      expect(Validators.loginPassword(''), isNotNull);
      expect(Validators.loginUser('admin'), isNull);
      expect(Validators.loginPassword('x'), isNull);
    });

    test('registro', () {
      expect(Validators.password('abc'), isNotNull);
      expect(Validators.password('abcdef1'), isNotNull); // sin mayúscula
      expect(Validators.password('Abcdef1'), isNull);
      expect(Validators.confirmPassword('a', 'b'), isNotNull);
      expect(Validators.email('mal@correo'), isNotNull);
      expect(Validators.email('bien@correo.com'), isNull);
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('con espacio'), isNotNull);
    });

    test('personaje', () {
      expect(Validators.characterName(''), isNotNull);
      expect(Validators.characterName('123'), isNotNull);
      expect(Validators.characterName('Mr. Poopybutthole'), isNull);
      expect(Validators.species('Hum4n'), isNotNull);
      expect(Validators.imageUrl(''), isNull);
      expect(Validators.imageUrl('ftp://x.com/a.png'), isNotNull);
      expect(Validators.imageUrl('https://rickandmortyapi.com/a.jpeg'), isNull);
    });
  });

  test('AuthService compara credenciales y bloquea tras 3 fallos', () {
    final auth = AuthService();
    expect(auth.login('admin', 'mala'), isNotNull);
    expect(auth.login('admin', 'mala'), isNotNull);
    expect(auth.login('admin', 'mala'), contains('bloqueado'));
    expect(auth.login('admin', AuthService.defaultPassword), contains('Espera'));

    final auth2 = AuthService();
    expect(auth2.login('ADMIN', AuthService.defaultPassword), isNull);
    expect(auth2.isLoggedIn, isTrue);
  });

  test('Repositorio: cargar, agregar, editar, eliminar, deshacer y filtrar',
      () async {
    final repo = CharacterRepository(fakeApi());
    await repo.load();
    expect(repo.all.length, 2);
    expect(repo.isComplete, isTrue);

    final created = repo.add(const Character(
      id: 0,
      name: 'Pickle Rick',
      status: 'Alive',
      species: 'Pickle',
      gender: 'Male',
      origin: 'Earth',
    ));
    expect(repo.all.first.id, created.id);
    expect(repo.nameExists('pickle rick'), isTrue);

    repo.update(repo.byId(1)!.copyWith(status: 'Dead'));
    expect(repo.byId(1)!.status, 'Dead');
    expect(repo.byId(1)!.isEdited, isTrue);

    final undo = repo.delete(repo.byId(2)!);
    expect(repo.byId(2), isNull);
    undo();
    expect(repo.byId(2), isNotNull);

    expect(repo.search(const CharacterFilter(status: 'Dead')).length, 1);
    expect(repo.search(const CharacterFilter(query: 'morty')).length, 1);
    expect(repo.search(const CharacterFilter(species: 'pickle')).length, 1);
    expect(repo.search(const CharacterFilter(onlyMine: true)).length, 2);
  });

  testWidgets('Login muestra errores si los campos están vacíos',
      (tester) async {
    await pumpApp(tester);

    await tapText(tester, 'Ingresar');
    await tester.pump();

    expect(find.text('Ingresa tu usuario'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('Login correcto abre la pantalla de personajes', (tester) async {
    await pumpApp(tester);
    await login(tester);

    expect(find.text('Personajes'), findsOneWidget);
    expect(find.text('Rick Sanchez'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Ver detalles de un personaje', (tester) async {
    await pumpApp(tester);
    await login(tester);

    await tester.tap(find.text('Rick Sanchez'));
    await tester.pumpAndSettle();

    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.text('Citadel'), findsOneWidget);
    expect(find.text('Apariciones'), findsOneWidget);
  });

  testWidgets('Formulario valida campos obligatorios y agrega personaje',
      (tester) async {
    await pumpApp(tester);
    await login(tester);

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    await tapText(tester, 'Agregar personaje');
    await tester.pumpAndSettle();
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('Selecciona un estado'), findsOneWidget);

    Future<void> enter(String label, String text) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
    }

    // Todos los campos existen aunque estén fuera de pantalla, así
    // validate() los revisa todos.
    expect(find.text('Selecciona un género'), findsOneWidget);
    expect(find.text('El origen es obligatorio'), findsOneWidget);

    await enter('Nombre *', 'Pickle Rick');
    await enter('Especie *', 'Pickle');
    await enter('Origen *', 'Earth');
    for (final option in ['Vivo', 'Masculino']) {
      final chip = find.widgetWithText(ChoiceChip, option);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    await tapText(tester, 'Agregar personaje');
    await tester.pumpAndSettle();

    expect(find.text('Explora el multiverso'), findsOneWidget);
    expect(find.text('Pickle Rick'), findsOneWidget);
  });
}

/// Monta la app en un tamaño de teléfono (411 x 914).
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RickMortyApp(
    auth: AuthService(),
    repository: CharacterRepository(fakeApi()),
  ));
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  // Centra el elemento para que no quede bajo la AppBar o la barra inferior.
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  // No se usa pumpAndSettle: el logo del login gira de forma continua.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.tap(finder);
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'admin');
  await tester.enterText(find.byType(TextFormField).at(1), AuthService.defaultPassword);
  await tapText(tester, 'Ingresar');
  await tester.pumpAndSettle();
}
