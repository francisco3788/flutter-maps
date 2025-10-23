import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_snackbar.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/reports/presentation/pages/dashboard_page.dart';
import 'features/reports/presentation/pages/map_page.dart';
import 'features/reports/presentation/pages/report_detail_page.dart';
import 'features/reports/presentation/pages/report_form_page.dart';
import 'features/reports/presentation/pages/report_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.maybeGet('SUPABASE_URL');
  final supabaseAnonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Define SUPABASE_URL y SUPABASE_ANON_KEY en .env antes de ejecutar la app.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'VÃ­a Limpia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case ReportFormPage.route:
            final args = settings.arguments as ReportFormArgs?;
            return MaterialPageRoute(
              builder: (_) => ReportFormPage(args: args),
              fullscreenDialog: true,
            );
          case ReportDetailPage.route:
            final reportId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ReportDetailPage(reportId: reportId),
            );
        }
        return null;
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    return authState.when(
      data: (_) => const HomeShell(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text('No se pudo iniciar sesiÃ³n: $error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).refreshSession(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  final _pages = const [
    MapPage(),
    ReportListPage(),
    DashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final showFab = _currentIndex == 1;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list), label: 'Reportes'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Tablero'),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _openNewReport,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _openNewReport() async {
    final created = await Navigator.of(context).pushNamed(ReportFormPage.route);
    if (created == true && mounted) {
      showAppSnackBar(context, 'Reporte enviado');
    }
  }
}
