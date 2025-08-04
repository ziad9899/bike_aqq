// ===== lib/screens/forgot_password_screen.dart (نفس الكود الأصلي) =====
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'استعادة كلمة المرور',
          style: TextStyle(
            color: Color(0xFF006241),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF006241)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // شعار أو أيقونة
              Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF006241).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 50,
                  color: Color(0xFF006241),
                ),
              ),

              if (!_emailSent) ...[
                // النص التوضيحي قبل إرسال الإيميل
                const Text(
                  'نسيت كلمة المرور؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'لا تقلق! أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // حقل البريد الإلكتروني
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF006241)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // زر إرسال رابط الاستعادة
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006241),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'إرسال رابط الاستعادة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // النص التوضيحي بعد إرسال الإيميل
                const Icon(
                  Icons.mark_email_read,
                  size: 80,
                  color: Color(0xFF006241),
                ),

                const SizedBox(height: 20),

                const Text(
                  'تم إرسال الرابط!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006241),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'تم إرسال رابط إعادة تعيين كلمة المرور إلى:\n${_emailController.text}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF1E88E5),
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'تحقق من صندوق الوارد وصندوق الرسائل غير المرغوب فيها. قد يستغرق الأمر بضع دقائق.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // زر إعادة الإرسال
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006241),
                      side: const BorderSide(color: Color(0xFF006241)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF006241))
                        : const Text(
                      'إعادة إرسال الرابط',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // رابط العودة لتسجيل الدخول
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'تذكرت كلمة المرور؟ ',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // العودة للصفحة السابقة
                    },
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold,
                      ),
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

  // دالة إرسال رابط استعادة كلمة المرور
  Future<void> _resetPassword() async {
    if (!_emailSent && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });

        if (!_emailSent) {
          _showSuccess('تم إرسال رابط استعادة كلمة المرور بنجاح');
        } else {
          _showSuccess('تم إعادة إرسال الرابط');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صحيح';
            break;
          case 'too-many-requests':
            errorMessage = 'تم إرسال عدة طلبات، حاول مرة أخرى لاحقاً';
            break;
          default:
            errorMessage = 'حدث خطأ: ${e.message}';
        }
        _showError(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showError('حدث خطأ غير متوقع: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF006241),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}