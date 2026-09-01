import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'models/app_user.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/fund_service.dart';
import 'services/invite_service.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class BitersApp extends StatelessWidget {
  const BitersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FundService>(create: (_) => FundService()),
        Provider<InviteService>(create: (_) => InviteService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<AppState>(
          create: (context) => AppState(
            authService: context.read<AuthService>(),
            fundService: context.read<FundService>(),
          ),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _router = buildRouter(appState);
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AppState>().appUser;
    final themeMode = switch (appUser?.tema) {
      AppThemeMode.claro => ThemeMode.light,
      AppThemeMode.oscuro => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Biters',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'PY'), Locale('es'), Locale('en')],
      locale: const Locale('es', 'PY'),
    );
  }
}
