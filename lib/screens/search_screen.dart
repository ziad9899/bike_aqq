import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/ad_card.dart'; // لم ترسل بعد

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _selectedCity = 'الكل';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ تغيير لون الخلفية
      appBar: AppBar(
        title: const Text(
          'البحث',
          style: TextStyle(
            color: Color(0xFF006241),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white, // ✅ تغيير لون AppBar
        elevation: 0,
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ابحث عن المنتجات...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Color(0xFF006241)),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // الفلاتر
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'القسم',
                          border: OutlineInputBorder(),
                        ),
                        items: ['الكل', 'السيارات', 'العقارات', 'الإلكترونيات', 'الأثاث', 'الخدمات']
                            .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'المدينة',
                          border: OutlineInputBorder(),
                        ),
                        items: ['الكل', 'الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة']
                            .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // نتائج البحث
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ads = snapshot.data!.docs;

                if (ads.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: TextStyle(fontSize: 18, color: Color(0xFF333333)),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index].data() as Map<String, dynamic>;
                    return AdCard(ad: ad, adId: ads[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('ads');

    if (_searchController.text.isNotEmpty) {
      query = query.where('title', isGreaterThanOrEqualTo: _searchController.text);
    }

    if (_selectedCategory != 'الكل') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    if (_selectedCity != 'الكل') {
      query = query.where('city', isEqualTo: _selectedCity);
    }

    return query.orderBy('createdAt', descending: true);
  }
}