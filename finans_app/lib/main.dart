import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/market_provider.dart';
import 'data/providers/portfolio_provider.dart';
import 'data/providers/finance_provider.dart';
import 'data/providers/recurring_provider.dart';
import 'data/providers/note_provider.dart';
import 'data/providers/binance_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/lock_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/portfolio/portfolio_screen.dart';
import 'presentation/screens/finance/finance_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/tools/tools_screen.dart';
import 'presentation/screens/tools/loan_calculator_screen.dart';
import 'presentation/screens/tools/currency_converter_screen.dart';
import 'presentation/screens/tools/ipo_screen.dart';
import 'presentation/screens/tools/notepad/notepad_screen.dart';
import 'presentation/screens/market/market_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/widgets/inactivity_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulama lifecycle değişince çağrılır.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Arka plana geçince veya cihaz kilitlenince kilitle
      final currentContext = _navigatorKey.currentContext;
      if (currentContext != null) {
        currentContext.read<AuthProvider>().lockScreen();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Ön plana dönünce; zaten kilitliyse LockScreen gösterilecek
      // (ekstra bir şey yapmaya gerek yok)
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => MarketProvider()..startPolling()),
        ChangeNotifierProxyProvider<AuthProvider, PortfolioProvider>(
          create: (_) => PortfolioProvider(),
          update: (_, auth, portfolio) => portfolio!..updateToken(auth.isAuthenticated ? auth.token : null), 
        ),
        ChangeNotifierProxyProvider<AuthProvider, FinanceProvider>(
          create: (_) => FinanceProvider(),
          update: (_, auth, finance) => finance!..updateToken(auth.isAuthenticated ? auth.token : null),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RecurringProvider>(
          create: (_) => RecurringProvider(),
          update: (_, auth, recurring) => recurring!..updateToken(auth.isAuthenticated ? auth.token : null),
        ),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => BinanceProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          print('Main: Building application... isLoading=${auth.isLoading}, isAuthenticated=${auth.isAuthenticated}');
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Finans App',
            theme: AppTheme.darkTheme,
            builder: (context, child) {
              if (auth.isLoading) {
                print('Main: Showing Loading Screen');
                return Scaffold(
                  backgroundColor: const Color(0xFF002F6C), // Same as login header
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'O',
                            style: TextStyle(
                              color: Color(0xFF002F6C),
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'FinansApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kişisel Finans Yönetimi',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 60),
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  ),
                );
              }
              print('Main: Showing Application Shell');
              // Kilit ekranı kontrolü
              if (auth.isAuthenticated && auth.isLocked) {
                return const LockScreen();
              }
              return child!;
            },
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/home': (_) => const HomeScreen(),
              '/portfolio': (_) => const PortfolioScreen(),
              '/finance': (_) => const FinanceScreen(),
              '/tools': (_) => const ToolsScreen(),
              '/tools/loan': (_) => const LoanCalculatorScreen(),
              '/tools/converter': (_) => const CurrencyConverterScreen(),
              '/tools/ipo': (_) => const IPOScreen(),
              '/tools/notepad': (_) => const NotepadScreen(),
              '/market': (_) => const MarketScreen(),
              '/settings': (_) => const SettingsScreen(),
            },

            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
