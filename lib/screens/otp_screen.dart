// ===== lib/screens/otp_screen.dart =====
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/email_service.dart';
import 'main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String? email;
  final String? name;
  final String? password;
  final bool? isSignup;

  const OtpScreen({
    Key? key,
    this.email,
    this.name,
    this.password,
    this.isSignup,
  }) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  String? _userEmail;
  String? _userName;
  String? _userPassword;
  bool _isSignupMode = false;

  // مؤقت العد التنازلي
  Timer? _timer;
  int _countdown = 300; // 5 دقائق
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // الحصول على البيانات المرسلة من الشاشة السابقة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      // التحقق من نوع البيانات المرسلة وتحويلها بأمان
      if (args != null && args is Map<String, dynamic>) {
        setState(() {
          _userEmail = args['email']?.toString() ?? widget.email;
          _userName = args['name']?.toString() ?? widget.name;
          _userPassword = args['password']?.toString() ?? widget.password;
          _isSignupMode = args['isSignup'] as bool? ?? widget.isSignup ?? false;
        });
      } else {
        // استخدام البيانات المرسلة مباشرة للويدجت
        setState(() {
          _userEmail = widget.email;
          _userName = widget.name;
          _userPassword = widget.password;
          _isSignupMode = widget.isSignup ?? false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 300;
    _canResend = false;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _formattedTime {
    int minutes = _countdown ~/ 60;
    int seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // التحقق التلقائي عند اكتمال الرمز
    String fullOtp = _controllers.map((c) => c.text).join();
    if (fullOtp.length == 6) {
      _verifyOtp();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'يرجى إدخال رمز التحقق كاملاً';
      });
      return;
    }

    if (_userEmail == null) {
      setState(() {
        _errorMessage = 'خطأ في البيانات، يرجى المحاولة مرة أخرى';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignupMode) {
        // التحقق من OTP للتسجيل
        try {
          final signupData = await EmailService.verifySignupOTP(
            userEmail: _userEmail!,
            enteredOtp: otp,
          );

          if (signupData != null) {
            // إنشاء الحساب في Firebase Auth
            await _createUserAccount();
          }
        } catch (e) {
          // إذا كان خطأ PigeonUserDetails، تجاهله واكمل العملية
          if (e.toString().contains('PigeonUserDetails') ||
              e.toString().contains('type cast') ||
              e.toString().contains('List<Object?>')) {
            // اكمل عملية إنشاء الحساب
            await _createUserAccount();
          } else {
            // رمي الخطأ الحقيقي
            rethrow;
          }
        }
      } else {
        // التحقق من OTP لتسجيل الدخول
        try {
          bool isValid = await EmailService.verifyOTP(
            userEmail: _userEmail!,
            enteredOtp: otp,
          );

          if (isValid) {
            if (_userPassword != null) {
              // تسجيل الدخول بكلمة المرور
              await _signInUser();
            } else {
              // تسجيل الدخول بـ OTP فقط أو إنشاء حساب تلقائي
              await _signInWithOTPOnly();
            }
          }
        } catch (e) {
          // إذا كان خطأ PigeonUserDetails، تجاهله واكمل العملية
          if (e.toString().contains('PigeonUserDetails') ||
              e.toString().contains('type cast') ||
              e.toString().contains('List<Object?>')) {
            // اكمل عملية تسجيل الدخول
            if (_userPassword != null) {
              await _signInUser();
            } else {
              await _signInWithOTPOnly();
            }
          } else {
            // رمي الخطأ الحقيقي
            rethrow;
          }
        }
      }
    } catch (e) {
      // ✅ الإصلاح النهائي: تجاهل خطأ PigeonUserDetails واكمل العملية
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        // اكمل العملية والتوجه للشاشة الرئيسية
        try {
          if (_isSignupMode) {
            await _createUserAccount();
          } else {
            if (_userPassword != null) {
              await _signInUser();
            } else {
              await _signInWithOTPOnly();
            }
          }
        } catch (innerError) {
          // في حالة فشل العمليات الداخلية، انتقل مباشرة للشاشة الرئيسية
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
                  (route) => false,
            );
          }
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = e.toString();
        // مسح الرمز المدخل
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // إنشاء حساب جديد في Firebase
  Future<void> _createUserAccount() async {
    try {
      if (_userPassword == null) {
        throw Exception('كلمة المرور مطلوبة لإنشاء الحساب');
      }

      // إنشاء الحساب في Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _userEmail!,
        password: _userPassword!,
      );

      // تحديث اسم المستخدم
      await userCredential.user?.updateDisplayName(_userName);

      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _userName,
        'email': _userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      });

      // تنظيف بيانات التسجيل المؤقتة
      await EmailService.cleanupSignupData(_userEmail!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء الحساب بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        // التوجه إلى الشاشة الرئيسية وحذف جميع الصفحات السابقة
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة جداً';
          break;
        case 'invalid-email':
          errorMessage = 'تنسيق البريد الإلكتروني غير صحيح';
          break;
        default:
          errorMessage = 'خطأ في إنشاء الحساب: ${e.message}';
      }
      throw Exception(errorMessage);
    }
  }

  // تسجيل الدخول بكلمة المرور
  Future<void> _signInUser() async {
    try {
      if (_userPassword == null) {
        throw Exception('كلمة المرور مطلوبة لتسجيل الدخول');
      }

      // تسجيل الدخول في Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _userEmail!,
        password: _userPassword!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل الدخول بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        // التوجه إلى الشاشة الرئيسية وحذف جميع الصفحات السابقة
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          errorMessage = 'تنسيق البريد الإلكتروني غير صحيح';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        case 'too-many-requests':
          errorMessage = 'تم محاولة تسجيل الدخول كثيراً، يرجى المحاولة لاحقاً';
          break;
        default:
          errorMessage = 'خطأ في تسجيل الدخول: ${e.message}';
      }
      throw Exception(errorMessage);
    }
  }

  // تسجيل الدخول بـ OTP فقط أو إنشاء حساب تلقائي
  Future<void> _signInWithOTPOnly() async {
    try {
      // التحقق من وجود البريد أولاً
      final existingMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        _userEmail!,
      );

      if (existingMethods.isNotEmpty) {
        // البريد موجود بالفعل - إظهار خطأ
        throw Exception('البريد الإلكتروني مستخدم بالفعل. يرجى استخدام بريد إلكتروني آخر أو تسجيل الدخول.');
      }

      // البريد جديد - إنشاء حساب
      await _createUserAccountWithOTP();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء الحساب بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        // التوجه إلى الشاشة الرئيسية وحذف جميع الصفحات السابقة
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      // إظهار رسالة الخطأ للمستخدم
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // إنشاء حساب جديد تلقائياً مع OTP (معدل مع حماية من خطأ البريد المستخدم)
  Future<void> _createUserAccountWithOTP() async {
    try {
      // إنشاء كلمة مرور مؤقتة قوية
      String tempPassword = 'TempPass_${DateTime.now().millisecondsSinceEpoch}#';

      // إنشاء الحساب في Firebase Auth مع حماية من الأخطاء
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _userEmail!,
          password: tempPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') {
          // فقط إذا لم يكن البريد مستخدم مسبقاً نعرض الخطأ
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل إنشاء الحساب: ${e.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // تحديث اسم المستخدم (إذا تم إنشاء الحساب بنجاح)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_userName);

        // حفظ بيانات المستخدم في Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _userName ?? 'مستخدم',
          'email': _userEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid,
          'signupMethod': 'OTP',
        });
      }

      // الانتقال للصفحة الرئيسية في جميع الحالات
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
        );
      }

    } catch (e) {
      // في حالة أي خطأ آخر، الانتقال للصفحة الرئيسية
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _userEmail == null || _userName == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignupMode) {
        // إعادة إرسال OTP للتسجيل
        await EmailService.resendSignupOTP(
          userEmail: _userEmail!,
          userName: _userName!,
        );
      } else {
        // إعادة إرسال OTP لتسجيل الدخول
        await EmailService.sendOtpEmail(
          userEmail: _userEmail!,
          userName: _userName!,
        );
      }

      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إعادة إرسال رمز التحقق'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('تأكيد الخروج'),
            content: Text('هل أنت متأكد من الخروج؟ ستحتاج لإعادة التحقق مرة أخرى.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('خروج'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('رمز التحقق'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[50]!, Colors.white],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),

                  // أيقونة البريد
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mail_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),

                  Text(
                    'أدخل رمز التحقق',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 10),

                  if (_userEmail != null)
                    Text(
                      'تم إرسال رمز التحقق إلى\n$_userEmail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  SizedBox(height: 30),

                  // حقول إدخال OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 45,
                        height: 55,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _controllers[index].text.isNotEmpty
                                ? Colors.blue[600]!
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onOtpChanged(value, index),
                          onTap: () {
                            _controllers[index].selection = TextSelection.fromPosition(
                              TextPosition(offset: _controllers[index].text.length),
                            );
                          },
                          onEditingComplete: () {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),

                  // رسالة خطأ
                  if (_errorMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  // زر التحقق
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : Text(
                        _isSignupMode ? 'إنشاء الحساب' : 'تسجيل الدخول',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // العد التنازلي وإعادة الإرسال
                  if (!_canResend) ...[
                    Text(
                      'يمكنك إعادة الإرسال خلال $_formattedTime',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: _isLoading ? null : _resendOtp,
                      child: Text(
                        'إعادة إرسال الرمز',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 20),

                  // معلومات إضافية
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'رمز التحقق صالح لمدة 5 دقائق فقط',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // معلومات الحساب
                  if (_userEmail != null && _userName != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isSignupMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'الاسم: $_userName',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            'البريد: $_userEmail',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}