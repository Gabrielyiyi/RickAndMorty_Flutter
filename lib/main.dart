import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/character_repository.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(RickMortyApp(
    auth: AuthService(),
    repository: CharacterRepository(RickAndMortyApi()),
  ));
}

class RickMortyApp extends StatelessWidget {
  const RickMortyApp({super.key, required this.auth, required this.repository});

  final AuthService auth;
  final CharacterRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      repository: repository,
      child: MaterialApp(
        title: 'Rick and Morty',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const LoginScreen(),
      ),
    );
  }
}
