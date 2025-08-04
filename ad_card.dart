import 'package:flutter/material.dart';
import '../screens/ad_detail_screen.dart';

class AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final String adId;

  const AdCard({super.key, required this.ad, required this.adId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdDetailScreen(ad: ad, adId: adId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
        child: Row(
          children: [
            // صورة الإعلان
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ad['images'] != null && ad['images'].isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ad['images'][0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF006241).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Color(0xFF006241),
                        size: 40,
                      ),
                    );
                  },
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF006241).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.image,
                  color: Color(0xFF006241),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // تفاصيل الإعلان
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    ad['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // السعر
                  Text(
                    '${_formatPrice(ad['price'])} ريال',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006241),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // المعلومات الإضافية
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ad['city'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ad['category'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // الوقت والقسم الفرعي
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(ad['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (ad['subCategory'] != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006241).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ad['subCategory'],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006241),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // المؤشرات الجانبية
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // مؤشر الإعلان المثبت
                if (ad['isPinned'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'مثبت',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // مؤشر الإعلان الوهمي (اختياري للتطوير)
                if (ad['isReal'] == false && _isDebugMode())
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'وهمي',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // أيقونة المشاهدة
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // تنسيق السعر
  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is String) {
      final numPrice = double.tryParse(price) ?? 0;
      return _formatNumber(numPrice);
    }
    if (price is num) {
      return _formatNumber(price.toDouble());
    }
    return price.toString();
  }

  // تنسيق الأرقام مع الفواصل
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}م';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}ك';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  // تنسيق الوقت منذ النشر
  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;

    try {
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        // Firebase Timestamp
        dateTime = timestamp.toDate();
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return 'منذ ${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return '';
    }
  }

  // فحص وضع التطوير (لإخفاء مؤشرات الإعلانات الوهمية في الإنتاج)
  bool _isDebugMode() {
    return false; // أو استخدام kDebugMode من foundation
  }
}