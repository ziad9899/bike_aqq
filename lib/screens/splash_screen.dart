import 'dart:async';
import 'package:flutter/material.dart';
import 'main_screen.dart'; // تأكد من أن المسار صحيح

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.5),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInBack,
    ));

    Timer(const Duration(milliseconds: 1500), () {
      _animationController.forward();
    });

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Image.asset(
            'assets/images/banner1.jpg', // ✅ نفس الصورة الأصلية
            width: MediaQuery.of(context).size.width * 0.7, // ⬅️ تكبيرها تلقائيًا
            fit: BoxFit.cover, // ⬅️ يجعلها تغطي المساحة بدون حواف بيضاء ظاهرة
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
