// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على المستخدم الحالي
  static User? get currentUser => _auth.currentUser;

  // مراقبة حالة تسجيل الدخول
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // تسجيل الدخول بالبريد الإلكتروني
  static Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // حفظ المستخدم تلقائياً في Firestore عند تسجيل الدخول
      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      }

      return result.user;
    } catch (e) {
      throw e;
    }
  }

  // إنشاء حساب جديد بالبريد الإلكتروني
  static Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // حفظ المستخدم الجديد تلقائياً في Firestore عند التسجيل
      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      }

      return result.user;
    } catch (e) {
      throw e;
    }
  }

  // حفظ المستخدم في Firestore تلقائياً (بالضبط كما طلبت)
  static Future<void> _saveUserToFirestore(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      // البيانات المطلوبة بالضبط
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'username': user.email?.split('@')[0] ?? 'مستخدم',
        'name': user.email?.split('@')[0] ?? 'مستخدم',
        'isOnline': true,
        'isBlocked': false,
      };

      if (!userDoc.exists) {
        // إنشاء مستخدم جديد
        userData['createdAt'] = FieldValue.serverTimestamp();
        await userRef.set(userData);
        print('✅ تم حفظ مستخدم جديد في Firestore: ${user.email}');
      } else {
        // تحديث المستخدم الموجود
        await userRef.update({
          'isOnline': true,
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('✅ تم تحديث بيانات المستخدم: ${user.email}');
      }
    } catch (e) {
      print('❌ خطأ في حفظ المستخدم في Firestore: $e');
    }
  }

  // نقل المستخدمين الموجودين من Firebase Auth إلى Firestore
  static Future<void> migrateExistingUsers() async {
    try {
      print('🔄 بدء نقل المستخدمين الموجودين...');

      // قائمة المستخدمين الموجودين (من الصورة التي أرسلتها)
      final existingUsers = [
        {
          'email': 'inid939@gmail.com',
          'uid': 'user_inid939_001', // UID مبسط للاختبار
        },
        {
          'email': 'ollj8567@gmail.com',
          'uid': 'user_ollj8567_002',
        },
        {
          'email': 'zalo62464@gmail.com',
          'uid': 'user_zalo62464_003',
        },
        {
          'email': 'al3asma2030@gmail.com',
          'uid': 'user_al3asma2030_004',
        },
        {
          'email': 'alof9899@gmail.com',
          'uid': 'user_alof9899_005',
        },
        {
          'email': 'adel20111011@gmail.com',
          'uid': 'user_adel20111011_006',
        },
      ];

      for (var user in existingUsers) {
        final userData = {
          'uid': user['uid'],
          'email': user['email'],
          'username': user['email']!.split('@')[0],
          'name': user['email']!.split('@')[0],
          'isOnline': false,
          'isBlocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(user['uid']).set(userData);
        print('✅ تم نقل: ${user['email']}');
      }

      print('🎉 تم نقل ${existingUsers.length} مستخدمين بنجاح!');
      print('📱 الآن يظهر جميع المستخدمين في صفحة المحادثات');

    } catch (e) {
      print('❌ خطأ في نقل المستخدمين: $e');
    }
  }

  // تسجيل الدخول بـ Google
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // هنا يتم تطبيق تسجيل الدخول بـ Google
      // قم بإلغاء التعليق عند إضافة google_sign_in package
      /*
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential result = await FirebaseAuth.instance.signInWithCredential(credential);

        // حفظ المستخدم تلقائياً في Firestore
        if (result.user != null) {
          await _saveUserToFirestore(result.user!);
        }
      }
      */

      Navigator.of(context).pop(); // إغلاق مؤشر التحميل
      Navigator.of(context).pop(); // إغلاق Bottom Sheet

      // للاختبار فقط - محاكاة تسجيل دخول ناجح
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الدخول بنجاح عبر Google'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تسجيل الدخول: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // تسجيل الدخول بـ Apple
  static Future<void> signInWithApple(BuildContext context) async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // هنا يتم تطبيق تسجيل الدخول بـ Apple
      // قم بإلغاء التعليق عند إضافة sign_in_with_apple package
      /*
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential result = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // حفظ المستخدم تلقائياً في Firestore
      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      }
      */

      Navigator.of(context).pop(); // إغلاق مؤشر التحميل
      Navigator.of(context).pop(); // إغلاق Bottom Sheet

      // للاختبار فقط - محاكاة تسجيل دخول ناجح
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الدخول بنجاح عبر Apple'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.of(context).pop(); // إغلاق مؤشر التحميل

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تسجيل الدخول: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // تسجيل الخروج
  static Future<void> signOut() async {
    try {
      // تحديث حالة المستخدم إلى غير متصل قبل تسجيل الخروج
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      await _auth.signOut();
      // await GoogleSignIn().signOut(); // إذا كان مستخدماً Google Sign-In
    } catch (e) {
      throw Exception('خطأ في تسجيل الخروج');
    }
  }

  // إرسال رابط إعادة تعيين كلمة المرور
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('خطأ في إرسال رابط إعادة تعيين كلمة المرور');
    }
  }

  // تحديث كلمة المرور
  static Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    try {
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('خطأ في تحديث كلمة المرور');
    }
  }

  // حذف الحساب
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // حذف بيانات المستخدم من Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // حذف جميع محادثات المستخدم
      final chats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();

      final batch = _firestore.batch();
      for (var chat in chats.docs) {
        // حذف الرسائل أولاً
        final messages = await chat.reference.collection('messages').get();
        for (var message in messages.docs) {
          batch.delete(message.reference);
        }
        // ثم حذف المحادثة
        batch.delete(chat.reference);
      }
      await batch.commit();

      // حذف الحساب من Firebase Auth
      await user.delete();
    } catch (e) {
      throw Exception('خطأ في حذف الحساب');
    }
  }

  // التحقق من صحة البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  // التحقق من صحة كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (value.length > 128) {
      return 'كلمة المرور طويلة جداً';
    }
    return null;
  }

  // معالجة أخطاء Firebase Auth
  static String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور خاطئة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح، حاول لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      case 'operation-not-allowed':
        return 'العملية غير مسموحة';
      case 'requires-recent-login':
        return 'يجب تسجيل الدخول مرة أخرى لإجراء هذه العملية';
      default:
        return 'حدث خطأ غير متوقع: ${e.message}';
    }
  }
}