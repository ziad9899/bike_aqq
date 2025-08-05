import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../widgets/ad_card.dart'; // ✅ معلق مؤقتاً

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _selectedCity = 'الكل';

  // ✅ حل مؤقت: AdCard بديل
  Widget AdCard({required Map<String, dynamic> ad, required String adId}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ad['title'] ?? 'بدون عنوان',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                ad['description'] ?? 'بدون وصف',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ad['price'] ?? '0'} ريال',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006241),
                    ),
                  ),
                  Text(
                    ad['city'] ?? 'غير محدد',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
