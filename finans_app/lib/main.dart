import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/market_provider.dart';
import 'data/providers/portfolio_provider.dart';
import 'data/providers/finance_provider.dart';
import 'data/providers/note_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/portfolio/portfolio_screen.dart';
import 'presentation/screens/finance/finance_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/tools/tools_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          print('Main: Building application... isLoading=${auth.isLoading}, isAuthenticated=${auth.isAuthenticated}');
          return MaterialApp(
            title: 'Finans App',
            theme: AppTheme.darkTheme,
            builder: (context, child) {
              if (auth.isLoading) {
                print('Main: Showing Loading Screen');
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              print('Main: Showing Application Shell');
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
              '/settings': (_) => const SettingsScreen(),
            },

            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
