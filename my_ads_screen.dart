import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/ad_card.dart'; // أو import 'my_ad_card.dart'; إذا كانت البطاقة خاصة

class MyAdsScreen extends StatelessWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعلاناتي')),
        body: const Center(child: Text('يجب تسجيل الدخول أولاً')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF55555),
      appBar: AppBar(
        title: const Text(
          'إعلاناتي',
          style: TextStyle(
            color: Color(0xFF006241),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF55555),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ads')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ads = snapshot.data!.docs;

          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.post_add, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'لم تقم بنشر أي إعلانات بعد',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006241),
                    ),
                    child: const Text(
                      'نشر إعلان جديد',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index].data() as Map<String, dynamic>;
              return AdCard(ad: ad, adId: ads[index].id); // أو MyAdCard
            },
          );
        },
      ),
    );
  }
}
