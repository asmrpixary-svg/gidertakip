import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/finance_provider.dart';
import 'providers/fuel_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => FuelProvider()..loadFuelData()),
      ],
      child: MaterialApp(
        title: 'Bütçe & Yakıt Takip',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            primary: Colors.teal.shade700,
            secondary: Colors.tealAccent.shade700,
            surface: const Color(0xFFF7F9FC),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F9FC),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
