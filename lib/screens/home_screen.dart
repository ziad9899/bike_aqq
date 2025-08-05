import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_screen.dart';
import '../widgets/ad_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedRegion = 'الرياض';
  String _selectedCity = 'الرياض';
  PageController _bannerController = PageController();

  // قوائم المحافظات
  final Map<String, List<String>> _regionCities = {
    'الرياض': ['الرياض', 'الدرعية', 'الخرج', 'الدوادمي', 'المجمعة', 'القويعية', 'وادي الدواسر', 'الأفلاج', 'الزلفي', 'شقراء', 'حوطة بني تميم', 'عفيف', 'الغاط', 'السليل', 'ضرما', 'المزاحمية', 'رماح', 'ثادق', 'حريملاء', 'الحريق', 'مرات', 'الدلم', 'الرين'],
    'القصيم': ['بريدة', 'عنيزة', 'الرس', 'المذنب', 'البكيرية', 'البدائع', 'الأسياح', 'النبهانية', 'رياض الخبراء', 'عيون الجواء', 'عقلة الصقور', 'ضرية', 'الشماسية'],
  };

  @override
  void initState() {
    super.initState();
    // التحقق من التحديث بعد الدفع
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void _checkForUpdates() {
    // تحديث الصفحة عند العودة من الدفع
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBannerSection() {
    final List<String> bannerImages = [
      'assets/images/banner2.jpg',
      'assets/images/banner3.jpg',
    ];

    return Container(
      height: 150,
      margin: const EdgeInsets.all(16),
      child: PageView.builder(
        controller: _bannerController,
        itemCount: bannerImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                bannerImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.error,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.home, color: Color(0xFF006241)),
            SizedBox(width: 8),
            Text(
              'العاصمة',
              style: TextStyle(
                color: Color(0xFF006241),
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // بنرات من assets/images/
            _buildBannerSection(),

            // فلتر المدينة والمحافظة
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر المنطقة والمحافظة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRegion,
                          decoration: const InputDecoration(
                            labelText: 'المنطقة',
                            labelStyle: TextStyle(fontSize: 16),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                          items: _regionCities.keys.map((region) =>
                              DropdownMenuItem(value: region, child: Text(region))).toList(),
                          onChanged: (value) => setState(() {
                            _selectedRegion = value!;
                            _selectedCity = _regionCities[value]!.first;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'المحافظة',
                            labelStyle: TextStyle(fontSize: 16),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                          items: _regionCities[_selectedRegion]!.map((city) =>
                              DropdownMenuItem(value: city, child: Text(city))).toList(),
                          onChanged: (value) => setState(() => _selectedCity = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // الأقسام الشائعة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأقسام الشائعة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final categories = [
                        {'name': 'العقارات', 'icon': Icons.home_work_outlined},
                        {'name': 'السيارات', 'icon': Icons.directions_car_outlined},
                        {'name': 'الأجهزة', 'icon': Icons.devices_outlined},
                        {'name': 'المواشي', 'icon': Icons.pets_outlined},
                        {'name': 'الخدمات', 'icon': Icons.build_outlined},
                        {'name': 'الأثاث', 'icon': Icons.chair_outlined},
                      ];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryScreen(
                                categoryName: categories[index]['name'] as String,
                              ),
                            ),
                          ).then((_) {
                            // تحديث الصفحة عند العودة من أي صفحة
                            if (mounted) {
                              setState(() {});
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF006241).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006241).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  categories[index]['icon'] as IconData,
                                  size: 28,
                                  color: const Color(0xFF006241),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  categories[index]['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // جميع الإعلانات مفلترة حسب المدينة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإعلانات في $_selectedCity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ads')
                        .where('isActive', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF006241)));
                      }

                      if (snapshot.hasError) {
                        return const Center(child: Text('حدث خطأ أثناء تحميل الإعلانات'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: Text('لا توجد بيانات'));
                      }

                      final allAds = snapshot.data!.docs;

                      // فلترة حسب المدينة بعد التحميل
                      final filteredAds = allAds.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['city'] == _selectedCity;
                      }).toList();

                      if (filteredAds.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد إعلانات',
                            style: TextStyle(fontSize: 18, color: Color(0xFF333333)),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredAds.length,
                        itemBuilder: (context, index) {
                          final ad = filteredAds[index].data() as Map<String, dynamic>;
                          return AdCard(ad: ad, adId: filteredAds[index].id);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}