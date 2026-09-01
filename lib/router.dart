import 'package:go_router/go_router.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/invite/invite_screen.dart';
import 'screens/invite/join_fund_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/transactions/new_deposit_screen.dart';
import 'screens/transactions/new_expense_screen.dart';
import 'screens/transactions/new_income_screen.dart';
import 'screens/transactions/transaction_detail_screen.dart';
import 'state/app_state.dart';
import 'widgets/app_shell.dart';

GoRouter buildRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    redirect: (context, state) {
      if (appState.initializing) return null;

      final loggedIn = appState.firebaseUser != null;
      final verified = appState.firebaseUser?.emailVerified ?? false;
      final onLogin = state.matchedLocation == '/login';
      final onVerify = state.matchedLocation == '/verificar-email';

      if (!loggedIn) return onLogin ? null : '/login';
      if (!verified) return onVerify ? null : '/verificar-email';
      if (onLogin || onVerify) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/verificar-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/invitar', builder: (context, state) => const InviteScreen()),
      GoRoute(path: '/unirme', builder: (context, state) => const JoinFundScreen()),
      GoRoute(path: '/gasto', builder: (context, state) => const NewExpenseScreen()),
      GoRoute(path: '/ingreso', builder: (context, state) => const NewIncomeScreen()),
      GoRoute(path: '/deposito', builder: (context, state) => const NewDepositScreen()),
      GoRoute(
        path: '/transaccion/:fundId/:txId',
        builder: (context, state) => TransactionDetailScreen(
          fundId: state.pathParameters['fundId']!,
          transactionId: state.pathParameters['txId']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/historial', builder: (context, state) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/stats', builder: (context, state) => const StatsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/perfil', builder: (context, state) => const ProfileScreen())]),
        ],
      ),
    ],
  );
}
