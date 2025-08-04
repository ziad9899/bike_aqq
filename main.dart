import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart'; // ✅ إضافة ChatService
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/otp_screen.dart'; // ✅ إضافة شاشة OTP

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AuthService.migrateExistingUsers();

  // ✅ تنظيف البيانات المُعطلة عند بدء التطبيق (اختياري)
  // يمكنك تفعيل هذا السطر لتنظيف تلقائي عند بدء التطبيق
  // await ChatService.deleteAllBrokenChats();

  runApp(AlasimahApp());
}

class AlasimahApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'العاصمة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF006241),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF333333)),
          bodyLarge: TextStyle(color: Color(0xFF333333)),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/main': (context) => MainScreen(),
        '/profile': (context) => ProfileScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/otp') {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (context) => OtpScreen(
              email: args?['email'],
              name: args?['name'],
              password: args?['password'],
              isSignup: args?['isSignup'] ?? false,
            ),
          );
        }
        return null;
      },
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: _CustomScrollBehavior(),
          child: child!,
        );
      },
    );
  }
}

class _CustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}