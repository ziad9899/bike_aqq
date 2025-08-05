import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../widgets/ad_card.dart'; // ✅ معلق مؤقتاً
import 'post_ad_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final String? subCategoryName;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    this.subCategoryName,
  });

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _selectedRegion = 'الرياض';
  String _selectedCity = 'الرياض';
  List<DocumentSnapshot> _allAds = [];
  bool _isLoading = true;

  // قوائم المحافظات
  final Map<String, List<String>> _regionCities = {
    'الرياض': ['الرياض', 'الدرعية', 'الخرج', 'الدوادمي', 'المجمعة', 'القويعية', 'وادي الدواسر', 'الأفلاج', 'الزلفي', 'شقراء', 'حوطة بني تميم', 'عفيف', 'الغاط', 'السليل', 'ضرما', 'المزاحمية', 'رماح', 'ثادق', 'حريملاء', 'الحريق', 'مرات', 'الدلم', 'الرين'],
    'القصيم': ['بريدة', 'عنيزة', 'الرس', 'المذنب', 'البكيرية', 'البدائع', 'الأسياح', 'النبهانية', 'رياض الخبراء', 'عيون الجواء', 'عقلة الصقور', 'ضرية', 'الشماسية'],
  };

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
  void initState() {
    super.initState();
    _loadAds();
    // التحقق من التحديث بعد العودة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  @override
  void didUpdateWidget(covariant CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subCategoryName != widget.subCategoryName ||
        oldWidget.categoryName != widget.categoryName) {
      _loadAds(); // تحديث الإعلانات عند تغير التصنيف
    }
  }

  void _loadAds() async {
    // إذا نفس البيانات موجودة، لا تعيد التحميل
    if (!_isLoading && _allAds.isNotEmpty) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('ads')
        .where('isActive', isEqualTo: true)
        .where('mainCategory', isEqualTo: _getCategoryForQuery())
        .where('city', isEqualTo: _selectedCity);

    if (widget.subCategoryName != null) {
      query = query.where('subCategory', isEqualTo: widget.subCategoryName);
    }

    final snapshot = await query.get();

    if (mounted) {
      setState(() {
        _allAds = snapshot.docs;
        _isLoading = false;
      });
    }
  }

  void _checkForUpdates() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildAdsSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF006241)),
      );
    }

    if (_allAds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد إعلانات في هذا القسم',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 20),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allAds.length,
      itemBuilder: (context, index) {
        final ad = _allAds[index].data() as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AdCard(ad: ad, adId: _allAds[index].id),
        );
      },
    );
  }

  // دالة لحساب حجم الخط بناءً على حجم الشاشة
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 375; // 375 هو عرض iPhone 6/7/8 كمرجع
    return baseSize * scaleFactor.clamp(0.9, 1.3); // تحديد الحد الأدنى والأقصى للتكبير
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> subCategories = _getSubCategories();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(
            color: const Color(0xFF006241),
            fontWeight: FontWeight.bold,
            fontSize: _getResponsiveFontSize(context, 24),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF006241)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // بانر القسم
            Container(
              margin: const EdgeInsets.all(16),
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF006241),
                    const Color(0xFF006241).withOpacity(0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        'قسم ${widget.categoryName}',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                  Text(
                    'اختر المنطقة والمحافظة',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // المحافظة
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'المحافظة',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(
                            fontSize: 14, // ✅ واضح ومناسب للجميع
                            color: Color(0xFF333333),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF006241)),
                          items: _regionCities[_selectedRegion]?.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(
                                city,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList() ?? [],
                          onChanged: (value) {
                            if (value != null && value != _selectedCity) {
                              setState(() {
                                _selectedCity = value;
                              });
                              _loadAds(); // ✅ تحميل الإعلانات الجديدة بعد اختيار المدينة
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // المنطقة
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRegion,
                          decoration: const InputDecoration(
                            labelText: 'المنطقة',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF006241)),
                          items: _regionCities.keys.map((region) {
                            return DropdownMenuItem<String>(
                              value: region,
                              child: Text(
                                region,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _selectedRegion) {
                              setState(() {
                                _selectedRegion = value;
                                _selectedCity = _regionCities[value]?.first ?? '';
                              });
                              _loadAds(); // ✅ تحميل جديد
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // الأقسام الفرعية
            if (subCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تصنيفات ${widget.categoryName}',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 22),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: subCategories.length,
                      itemBuilder: (context, index) {
                        final subCategory = subCategories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryScreen(
                                  categoryName: widget.categoryName,
                                  subCategoryName: subCategory['name'] as String,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF006241).withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF006241).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      subCategory['icon'] as IconData,
                                      size: 20,
                                      color: const Color(0xFF006241),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subCategory['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // الإعلانات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعلانات ${widget.categoryName}',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 22),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // عرض الإعلانات من Firebase فقط
                  _buildAdsSection(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // دالة لتحويل اسم القسم إلى القسم المناسب للاستعلام
  String _getCategoryForQuery() {
    switch (widget.categoryName) {
      case 'العقارات':
        return 'عقار';
      case 'السيارات':
        return 'سيارات';
      case 'الأجهزة':
        return 'أجهزة';
      case 'المواشي':
        return 'مواشي';
      case 'الخدمات':
        return 'خدمات';
      case 'الأثاث':
        return 'أثاث';
      default:
        return widget.categoryName;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.categoryName) {
      case 'العقارات':
      case 'للبيع':
      case 'الإيجار':
        return Icons.home_work_outlined;
      case 'السيارات':
      case 'جديد':
      case 'مستعمل':
      case 'قطع غيار':
      case 'لوحات مميزة':
        return Icons.directions_car_outlined;
      case 'الأجهزة':
        return Icons.devices_outlined;
      case 'المواشي':
      case 'الأغنام':
      case 'الإبل':
      case 'الخيول':
      case 'الدواجن':
        return Icons.pets_outlined;
      case 'الخدمات':
      case 'خدمات نظافة':
      case 'نقل عفش':
      case 'برمجة و تصميم':
      case 'مستلزمات افراح':
        return Icons.build_outlined;
      case 'الأثاث':
        return Icons.chair_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  List<Map<String, dynamic>> _getSubCategories() {
    switch (widget.categoryName) {
      case 'العقارات':
        return [
          {'name': 'للبيع', 'icon': Icons.sell_outlined},
          {'name': 'الإيجار', 'icon': Icons.key_outlined},
        ];
      case 'السيارات':
        return [
          {'name': 'جديد', 'icon': Icons.new_releases_outlined},
          {'name': 'مستعمل', 'icon': Icons.car_rental_outlined},
          {'name': 'قطع غيار', 'icon': Icons.build_outlined},
          {'name': 'لوحات مميزة', 'icon': Icons.credit_card},
        ];
      case 'المواشي':
        return [
          {'name': 'الأغنام', 'icon': FontAwesomeIcons.kaaba}, // استخدمنا رمز يشبه الغنم
          {'name': 'الإبل', 'icon': FontAwesomeIcons.horseHead}, // أيقونة رأس حصان كرمز للجِمال
          {'name': 'الخيول', 'icon': FontAwesomeIcons.horse}, // أيقونة خيل
          {'name': 'الدواجن', 'icon': FontAwesomeIcons.drumstickBite}, // أيقونة فخذ دجاج
        ];
      case 'الخدمات':
        return [
          {'name': 'خدمات نظافة', 'icon': Icons.cleaning_services_outlined},
          {'name': 'نقل عفش', 'icon': Icons.local_shipping_outlined},
          {'name': 'برمجة و تصميم', 'icon': Icons.code_outlined},
          {'name': 'مستلزمات افراح', 'icon': Icons.celebration_outlined},
        ];
      case 'الأجهزة':
        return [
          {'name': 'جديد', 'icon': Icons.new_releases_outlined},
          {'name': 'مستعمل', 'icon': Icons.devices_outlined},
        ];
      case 'الأثاث':
        return [
          {'name': 'جديد', 'icon': Icons.new_releases_outlined},
          {'name': 'مستعمل', 'icon': Icons.chair_outlined},
        ];
      default:
        return [];
    }
  }
}
