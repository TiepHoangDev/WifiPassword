import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

// Updated imports with the renamed model
import 'models/wifi_network_model.dart';
import 'services/wifi_service.dart';
import 'services/location_service.dart';
import 'services/storage_service.dart';
import 'providers/wifi_provider.dart';
import 'screens/home_screen.dart';
import 'screens/add_wifi_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final storageService = StorageService();
  await storageService.init();
  
  final locationService = LocationService();
  final wifiService = WifiService(storageService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WifiProvider(
            wifiService: wifiService,
            locationService: locationService,
            storageService: storageService,
          ),
        ),
      ],
      child: const WifiPassApp(),
    ),
  );
}

class WifiPassApp extends StatelessWidget {
  const WifiPassApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WifiPass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Blue as primary color
          brightness: Brightness.light,
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF03DAC6),
          tertiary: const Color(0xFF0288D1),
          background: const Color(0xFFF5F5F5),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
          primary: const Color(0xFF90CAF9),
          secondary: const Color(0xFF03DAC6),
          tertiary: const Color(0xFF64B5F6),
          background: const Color(0xFF121212),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system, // Respect system theme
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/add_wifi': (context) => const AddWifiScreen(),
      },
    );
  }
}
