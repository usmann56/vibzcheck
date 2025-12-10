import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/voting_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  User? user = FirebaseAuth.instance.currentUser;
  runApp(MyApp(initialRoute: user == null ? '/login' : '/main'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, this.initialRoute = '/login'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF2C3639),
        fontFamily: 'SpaceGrotesk',
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF3F4E4F),
          onPrimary: const Color(0xFFA27B5C),
          secondary: const Color(0xFF3F4E4F),
          onSecondary: const Color(0xFFA27B5C),
          surface: const Color(0xFF2C3639),
          onSurface: const Color(0xFFA27B5C),
          error: Colors.red,
          onError: Colors.white,
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'BebasNeue',
            fontWeight: FontWeight.w400,
            fontSize: 36,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'BebasNeue',
            fontWeight: FontWeight.w400,
            fontSize: 28,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'BebasNeue',
            fontWeight: FontWeight.w400,
            fontSize: 22,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3F4E4F),
          foregroundColor: Color(0xFFA27B5C),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F4E4F),
            foregroundColor: const Color(0xFFDCD7C9),
            textStyle: const TextStyle(
              fontFamily: 'Raleway',
              color: Color(0xFFDCD7C9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFDCD7C9),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.grey),
          floatingLabelStyle: TextStyle(
            color: Color(0xFFDCD7C9),
            fontWeight: FontWeight.bold,
          ),
          hintStyle: TextStyle(color: Colors.grey),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFDCD7C9), width: 2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const HomePage(),
        '/voting': (context) => const VotingScreen(),
      },
    );
  }
}
