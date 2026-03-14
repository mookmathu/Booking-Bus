import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screen/login.dart';
import 'screen/register.dart';
import 'screen/search.dart';
import 'main_shell.dart';
import 'payment.dart';
import 'screen/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VanBookingApp());
}

class VanBookingApp extends StatelessWidget {
  const VanBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Van Booking',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Kodchasan',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6FB6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3F6FB6),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C4C85),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const MainShell(),
        '/search': (context) => const SearchResultScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/booking_success': (context) => const BookingSuccessScreen(), 
        '/Notification': (context) => NotificationScreen(),
        '/ticket': (context) => const MainShell(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}