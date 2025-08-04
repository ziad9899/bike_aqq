import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'post_ad_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _pages = [
    HomeScreen(),
    SearchScreen(),
    PostAdScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          children: _pages,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: _currentIndex == 2 ? Colors.blue : const Color(0xFF006241),
            unselectedItemColor: const Color(0xFF333333),
            backgroundColor: Colors.white,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
              const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'البحث'),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.add_circle,
                  color: _currentIndex == 2 ? Colors.blue : const Color(0xFF333333),
                ),
                label: 'نشر إعلان',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
        ),
      ),
    );
  }
}
