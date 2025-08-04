import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'ad_detail_screen.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  _PostAdScreenState createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _realEstateLicenseController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _whatsappLinkController = TextEditingController();

  String _selectedCategory = 'عقار';
  String _selectedSubCategory = 'للبيع';
  String _selectedRegion = 'الرياض';
  String _selectedCity = 'الرياض';
  List<File> _selectedImages = [];
  bool _isLoading = false;

  final Map<String, List<String>> _regionCities = {
    'الرياض': ['الرياض', 'الدرعية', 'الخرج', 'الدوادمي', 'المجمعة', 'القويعية', 'وادي الدواسر', 'الأفلاج', 'الزلفي', 'شقراء', 'حوطة بني تميم', 'عفيف', 'الغاط', 'السليل', 'ضرما', 'المزاحمية', 'رماح', 'ثادق', 'حريملاء', 'الحريق', 'مرات', 'الدلم', 'الرين'],
    'القصيم': ['بريدة', 'عنيزة', 'الرس', 'المذنب', 'البكيرية', 'البدائع', 'الأسياح', 'النبهانية', 'رياض الخبراء', 'عيون الجواء', 'عقلة الصقور', 'ضرية', 'الشماسية'],
  };

  final Map<String, List<String>> _categorySubCategories = {
    'عقار': ['للبيع', 'الإيجار'],
    'سيارات': ['جديد', 'مستعمل', 'قطع غيار'],
    'أجهزة': ['جديد', 'مستعمل'],
    'مواشي': ['الأغنام', 'الإبل', 'الخيول', 'الدواجن'],
    'خدمات': ['خدمات نظافة', 'نقل عفش', 'برمجة و تصميم', 'مستلزمات افراح'],
    'أثاث': ['جديد', 'مستعمل'],
  };

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null) {
      final newImages = images.map((img) => File(img.path)).toList();
      if (_selectedImages.length + newImages.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يمكنك رفع 5 صور كحد أقصى')),
        );
        return;
      }
      setState(() {
        _selectedImages.addAll(newImages);
      });
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    final cloudName = 'deu1ndjzm';
    final uploadPreset = 'flutter_unsigned';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = json.decode(resStr);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  Future<void> _postAd() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      for (File image in _selectedImages) {
        final url = await _uploadToCloudinary(image);
        if (url != null) imageUrls.add(url);
      }

      String finalCategory = _selectedSubCategory;
      if (_selectedCategory == 'عقار') {
        finalCategory = 'عقار $_selectedSubCategory';
      } else if (_selectedCategory != 'عقار') {
        finalCategory = '$_selectedCategory $_selectedSubCategory';
      }

      final Map<String, dynamic> adData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': finalCategory,
        'mainCategory': _selectedCategory,
        'subCategory': _selectedSubCategory,
        'region': _selectedRegion,
        'city': _selectedCity,
        'images': imageUrls,
        'phoneNumber': _phoneNumberController.text,
        'whatsappLink': _whatsappLinkController.text,
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'isPinned': false,
        'isActive': true,
      };

      if (_selectedCategory == 'عقار') {
        adData['realEstateLicense'] = _realEstateLicenseController.text;
      }

      final docRef = await FirebaseFirestore.instance.collection('ads').add(adData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نشر الإعلان بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdDetailScreen(
            ad: adData,
            adId: docRef.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'نشر إعلان',
          style: TextStyle(
            color: Color(0xFF006241),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF006241)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 20),
              _buildTextFields(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9C5A0)),
      ),
      child: _selectedImages.isEmpty
          ? InkWell(
        onTap: _pickImages,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 50, color: Color(0xFF006241)),
              Text(
                'اضغط لإضافة الصور',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return _buildAddImageButton();
          }
          return _buildImagePreview(index);
        },
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Visibility(
      visible: _selectedImages.length < 5,
      child: Container(
        width: 100,
        margin: const EdgeInsets.all(8),
        child: InkWell(
          onTap: _pickImages,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9C5A0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Color(0xFF006241), size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Image.file(_selectedImages[index]),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.all(8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImages[index],
                width: 100,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => setState(() => _selectedImages.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'عنوان الإعلان',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال عنوان الإعلان' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'رقم الجوال/الواتس',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال رقم الجوال' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _whatsappLinkController,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'رابط الواتساب (اختياري)',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: 'https://wa.me/966xxxxxxxxx',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006241),
          ),
          decoration: const InputDecoration(
            labelText: 'السعر (ريال)',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'يرجى إدخال السعر';
            if (double.tryParse(value) == null) return 'يرجى إدخال رقم صحيح';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                decoration: const InputDecoration(
                  labelText: 'القسم الرئيسي',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ['عقار', 'سيارات', 'أجهزة', 'مواشي', 'خدمات', 'أثاث']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 16))))
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedCategory = value!;
                  _selectedSubCategory = _categorySubCategories[value]!.first;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSubCategory,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                decoration: const InputDecoration(
                  labelText: 'القسم الفرعي',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _categorySubCategories[_selectedCategory]!
                    .map((sub) => DropdownMenuItem(value: sub, child: Text(sub, style: const TextStyle(fontSize: 16))))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSubCategory = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedRegion,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                decoration: const InputDecoration(
                  labelText: 'المنطقة',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _regionCities.keys
                    .map((region) => DropdownMenuItem(value: region, child: Text(region, style: const TextStyle(fontSize: 16))))
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedRegion = value!;
                  _selectedCity = _regionCities[value]!.first;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCity,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _regionCities[_selectedRegion]!
                    .map((city) => DropdownMenuItem(value: city, child: Text(city, style: const TextStyle(fontSize: 16))))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCity = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedCategory == 'عقار') ...[
          TextFormField(
            controller: _realEstateLicenseController,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'رقم الترخيص العقاري',
              labelStyle: TextStyle(fontSize: 16),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال رقم الترخيص العقاري' : null,
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            labelText: 'وصف الإعلان',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال وصف الإعلان' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _postAd,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006241),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'نشر الإعلان',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}