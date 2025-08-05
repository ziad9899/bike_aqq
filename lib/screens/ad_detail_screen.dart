import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/comment_card.dart';
import 'main_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ad;
  final String adId;

  const AdDetailScreen({super.key, required this.ad, required this.adId});

  @override
  _AdDetailScreenState createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isRequest = widget.ad['isRequest'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isRequest ? 'تفاصيل الطلب' : 'تفاصيل الإعلان',
          style: const TextStyle(
            color: Color(0xFF006241),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF006241)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            _buildAdDetails(isRequest),
            const SizedBox(height: 20),
            _buildCommentsSection(),
            const SizedBox(height: 20),
            _buildHomeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 250,
      child: widget.ad['images'] != null && widget.ad['images'].isNotEmpty
          ? Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.ad['images'].length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.black,
                      child: Stack(
                        children: [
                          Center(
                            child: Image.network(
                              widget.ad['images'][index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 80, color: Color(0xFF006241)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Image.network(
                  widget.ad['images'][index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 80, color: Color(0xFF006241)),
                  ),
                ),
              );
            },
          ),
          if (widget.ad['images'].length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.ad['images'].length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index ? const Color(0xFF006241) : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      )
          : Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 80, color: Color(0xFF006241))),
      ),
    );
  }

  Widget _buildAdDetails(bool isRequest) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRequest)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.request_page, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'طلب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          Text(
            widget.ad['title'] ?? '',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            isRequest ? '1 ريال' : '${widget.ad['price']} ريال',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isRequest ? Colors.orange : const Color(0xFF006241),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.ad['city'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.category, color: Colors.grey, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.ad['category'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 22),
              const SizedBox(width: 8),
              Text(
                _formatDate(widget.ad['createdAt']),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          Text(
            isRequest ? 'تفاصيل الطلب' : 'الوصف',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            widget.ad['description'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF333333),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          _buildContactButtons(isRequest),
        ],
      ),
    );
  }

  Widget _buildContactButtons(bool isRequest) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final phone = widget.ad['phoneNumber'] ?? '';
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.phone, color: Colors.white, size: 22),
            label: Text(
              isRequest ? 'تواصل مع الطالب' : 'اتصال',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006241),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final whatsappLink = widget.ad['whatsappLink'] ?? '';
              final phone = widget.ad['phoneNumber'] ?? '';

              print('WhatsApp Link: $whatsappLink');
              print('Phone: $phone');

              bool success = false;

              if (whatsappLink.isNotEmpty) {
                success = await _tryOpenWhatsApp(whatsappLink);
              }

              if (!success && phone.isNotEmpty) {
                String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                if (!cleanPhone.startsWith('966')) {
                  if (cleanPhone.startsWith('0')) {
                    cleanPhone = '966${cleanPhone.substring(1)}';
                  } else {
                    cleanPhone = '966$cleanPhone';
                  }
                }

                List<String> whatsappUrls = [
                  'whatsapp://send?phone=$cleanPhone',
                  'https://wa.me/$cleanPhone',
                  'https://api.whatsapp.com/send?phone=$cleanPhone',
                ];

                for (String url in whatsappUrls) {
                  success = await _tryOpenWhatsApp(url);
                  if (success) break;
                }
              }

              if (!success && whatsappLink.isNotEmpty) {
                try {
                  final uri = Uri.parse(whatsappLink);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.inAppWebView);
                    success = true;
                  }
                } catch (e) {
                  print('Browser fallback failed: $e');
                }
              }

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('لا يمكن فتح الواتساب تلقائياً'),
                        if (whatsappLink.isNotEmpty)
                          Text('الرابط: $whatsappLink', style: const TextStyle(fontSize: 12)),
                        if (phone.isNotEmpty)
                          Text('الرقم: $phone', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'نسخ الرابط',
                      textColor: Colors.white,
                      onPressed: () async {
                        final textToCopy = whatsappLink.isNotEmpty
                            ? whatsappLink
                            : 'https://wa.me/966${phone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0'), '')}';
                        await Clipboard.setData(ClipboardData(text: textToCopy));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الرابط! افتح الواتساب والصق الرابط'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.message, color: Colors.white, size: 22),
            label: const Text(
              'واتساب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _tryOpenWhatsApp(String url) async {
    try {
      print('Trying to open: $url');

      List<Uri> urisToTry = [];

      if (url.contains('wa.me/message/')) {
        urisToTry.add(Uri.parse(url));
        urisToTry.add(Uri.parse(url.replaceFirst('https://', 'whatsapp://')));
      } else if (url.contains('wa.me/')) {
        urisToTry.add(Uri.parse(url));
        String phoneFromUrl = url.replaceAll(RegExp(r'[^\d]'), '');
        if (phoneFromUrl.isNotEmpty) {
          urisToTry.add(Uri.parse('whatsapp://send?phone=$phoneFromUrl'));
        }
      } else {
        urisToTry.add(Uri.parse(url));
      }

      for (Uri uri in urisToTry) {
        try {
          print('Testing URI: $uri');
          bool canLaunch = await canLaunchUrl(uri);
          print('Can launch $uri: $canLaunch');

          if (canLaunch) {
            bool launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            print('Launch result for $uri: $launched');
            if (launched) return true;
          }
        } catch (e) {
          print('Error with $uri: $e');
          continue;
        }
      }

      return false;
    } catch (e) {
      print('General error opening WhatsApp: $e');
      return false;
    }
  }

  Widget _buildCommentsSection() {
    final user = FirebaseAuth.instance.currentUser;
    final bool isRequest = widget.ad['isRequest'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequest ? 'الاستفسارات' : 'التعليقات',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          if (user != null) _buildCommentInput(isRequest),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ads')
                .doc(widget.adId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF006241)),
                );
              }

              final comments = snapshot.data!.docs;
              if (comments.isEmpty) {
                return Center(
                  child: Text(
                    isRequest ? 'لا توجد استفسارات حتى الآن' : 'لا توجد تعليقات حتى الآن',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index].data() as Map<String, dynamic>;
                  return CommentCard(comment: comment);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(bool isRequest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: isRequest ? 'اكتب استفسارك هنا...' : 'اكتب تعليقك هنا...',
              hintStyle: const TextStyle(fontSize: 16),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _addComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006241),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إرسال',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
                  (route) => false,
            );
          },
          icon: const Icon(Icons.home, color: Colors.white, size: 22),
          label: const Text(
            'العودة للصفحة الرئيسية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006241),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(widget.adId)
          .collection('comments')
          .add({
        'text': _commentController.text.trim(),
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ad['isRequest'] == true
                ? 'تم إضافة الاستفسار بنجاح'
                : 'تم إضافة التعليق بنجاح',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: const Color(0xFF006241),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ad['isRequest'] == true
                ? 'حدث خطأ في إضافة الاستفسار'
                : 'حدث خطأ في إضافة التعليق',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }

      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 0) return 'منذ ${difference.inDays} يوم';
      if (difference.inHours > 0) return 'منذ ${difference.inHours} ساعة';
      if (difference.inMinutes > 0) return 'منذ ${difference.inMinutes} دقيقة';
      return 'الآن';
    } catch (_) {
      return '';
    }
  }
}