// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ الحل السريع للأخطاء الـ 6
String _normalizeUID(String uid) => uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ دالة تنظيف شاملة لـ UID - إزالة جميع الرموز غير الأبجدية والرقمية
  static String normalizeUID(String uid) {
    // إزالة جميع الرموز والمسافات وترك الأحرف والأرقام فقط
    return uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
  }

  /// ✅ الدالة الموحدة لإنشاء chatId مع ترتيب ثابت
  static String generateChatId(String uid1, String uid2) {
    if (uid1.isEmpty || uid2.isEmpty) {
      throw Exception('UIDs cannot be empty');
    }

    // ✅ تنظيف وترتيب ثابت باستخدام compareTo
    final normalizedUid1 = normalizeUID(uid1);
    final normalizedUid2 = normalizeUID(uid2);

    final chatId = (normalizedUid1.compareTo(normalizedUid2) < 0)
        ? 'chat_${normalizedUid1}_${normalizedUid2}'
        : 'chat_${normalizedUid2}_${normalizedUid1}';

    print('🔑 ChatService.generateChatId:');
    print('   Original UIDs: [$uid1, $uid2]');
    print('   Normalized UIDs: [$normalizedUid1, $normalizedUid2]');
    print('   Generated ChatID: $chatId');

    return chatId;
  }

  /// إنشاء أو الحصول على محادثة موجودة
  static Future<String> createOrGetChat(String otherUserUid, String otherUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    // ✅ استخدام الدالة الموحدة مع تنظيف UIDs
    final chatId = generateChatId(currentUser.uid, otherUserUid);

    print('🔥 ChatService.createOrGetChat:');
    print('   Current UID: ${currentUser.uid}');
    print('   Other UID: $otherUserUid');
    print('   Generated ChatID: $chatId');

    // التحقق من وجود المحادثة
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // الحصول على اسم المستخدم الحالي
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentUserName = currentUserDoc.data()?['name'] ?? 'مستخدم';

      // ✅ إنشاء محادثة جديدة مع UIDs منظفة
      final now = Timestamp.now();

      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'user1Id': _normalizeUID(currentUser.uid),
        'user2Id': _normalizeUID(otherUserUid),
        'user1Name': currentUserName,
        'user2Name': otherUserName,
        'participants': [_normalizeUID(currentUser.uid), _normalizeUID(otherUserUid)],
        'lastMessage': 'تم إنشاء المحادثة',
        'timestamp': now,
        'createdAt': now,
        'senderId': _normalizeUID(currentUser.uid),
        'receiverId': _normalizeUID(otherUserUid),
        'isSeen': false,
      });

      print('✅ تم إنشاء محادثة جديدة: $chatId');
    } else {
      print('ℹ️ المحادثة موجودة مسبقاً: $chatId');
    }

    return chatId;
  }

  /// ✅ إرسال رسالة - مُصحح مع تشخيص كامل
  static Future<void> sendMessage(String chatId, String otherUserUid, String messageText) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    if (messageText.trim().isEmpty) {
      throw Exception('الرسالة فارغة');
    }

    try {
      print('📤 ChatService.sendMessage:');
      print('   ChatID: $chatId');
      print('   From: ${currentUser.uid}');
      print('   To: $otherUserUid');
      print('   Message: $messageText');

      final now = Timestamp.now();
      final normalizedCurrentUID = _normalizeUID(currentUser.uid);
      final normalizedOtherUID = _normalizeUID(otherUserUid);

      // التحقق من وجود المحادثة وإنشاؤها إذا لم تكن موجودة
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        print('⚠️ المحادثة غير موجودة، سيتم إنشاؤها...');

        final currentUserDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        final currentUserName = currentUserDoc.data()?['name'] ?? 'مستخدم';

        final otherUserDoc = await _firestore
            .collection('users')
            .doc(otherUserUid)
            .get();
        final otherUserName = otherUserDoc.data()?['name'] ?? 'مستخدم';

        await _firestore.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'user1Id': normalizedCurrentUID,
          'user2Id': normalizedOtherUID,
          'user1Name': currentUserName,
          'user2Name': otherUserName,
          'participants': [normalizedCurrentUID, normalizedOtherUID],
          'lastMessage': messageText.trim(),
          'timestamp': now,
          'createdAt': now,
          'senderId': normalizedCurrentUID,
          'receiverId': normalizedOtherUID,
          'isSeen': false,
        });
        print('✅ تم إنشاء المحادثة: $chatId');
      }

      // ✅ إضافة الرسالة مع UIDs منظفة وتشخيص مُفصل
      print('📤 بيانات الرسالة التي سيتم حفظها:');
      print('   chatId: $chatId');
      print('   senderId: $normalizedCurrentUID');
      print('   receiverId: $normalizedOtherUID');
      print('   text: ${messageText.trim()}');
      print('   timestamp: $now');

      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'chatId': chatId,
        'senderId': normalizedCurrentUID,
        'receiverId': normalizedOtherUID,  // ✅ هذا مهم جداً!
        'text': messageText.trim(),
        'timestamp': now,
        'isRead': false,
      });

      print('✅ تم إضافة الرسالة: ${messageRef.id}');

      // تحديث آخر رسالة في وثيقة المحادثة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': messageText.trim(),
        'timestamp': now,
        'senderId': normalizedCurrentUID,
        'receiverId': normalizedOtherUID,
        'isSeen': false,
      });

      print('✅ تم تحديث آخر رسالة في المحادثة');

      // ✅ التحقق الفوري من الإضافة
      final verifySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      print('✅ تحقق: إجمالي الرسائل الآن: ${verifySnapshot.docs.length}');

      print('✅ تم إرسال الرسالة بنجاح في ChatID: $chatId');
    } catch (e) {
      print('❌ خطأ في إرسال الرسالة: $e');
      throw Exception('فشل في إرسال الرسالة: $e');
    }
  }

  /// وضع علامة مقروء على الرسائل
  static Future<void> markMessagesAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final normalizedCurrentUID = _normalizeUID(currentUser.uid);

      // البحث عن الرسائل غير المقروءة
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: normalizedCurrentUID)
          .where('isRead', isEqualTo: false)
          .get();

      // تحديث الرسائل كمقروءة
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // تحديث حالة المحادثة
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        if (chatData['receiverId'] == normalizedCurrentUID) {
          batch.update(chatDoc.reference, {'isSeen': true});
        }
      }

      await batch.commit();
      print('✅ تم تحديد الرسائل كمقروءة في ChatID: $chatId');
    } catch (e) {
      print('❌ خطأ في تحديد الرسائل كمقروءة: $e');
    }
  }

  /// الحصول على تدفق الرسائل
  static Stream<QuerySnapshot> getMessagesStream(String chatId) {
    print('📡 ChatService.getMessagesStream: $chatId');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  /// الحصول على تدفق المحادثات للمستخدم الحالي
  static Stream<QuerySnapshot> getChatsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    final normalizedCurrentUID = _normalizeUID(currentUser.uid);
    print('📡 ChatService.getChatsStream for normalized UID: $normalizedCurrentUID');

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: normalizedCurrentUID)
        .snapshots();
  }

  /// التحقق من وجود محادثة بين مستخدمين
  static Future<bool> chatExists(String uid1, String uid2) async {
    final chatId = generateChatId(uid1, uid2);
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    return chatDoc.exists;
  }

  /// الحصول على معلومات المحادثة
  static Future<Map<String, dynamic>?> getChatInfo(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        return chatDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ خطأ في الحصول على معلومات المحادثة: $e');
      return null;
    }
  }

  /// ✅ إصلاح المحادثات الموجودة - دالة لتنظيف البيانات القديمة
  static Future<void> fixExistingChats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      print('🔧 بدء إصلاح المحادثات الموجودة...');

      // جلب جميع المحادثات
      final chatsSnapshot = await _firestore.collection('chats').get();

      for (var doc in chatsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        // تنظيف participants
        final cleanedParticipants = participants.map((uid) => _normalizeUID(uid)).toList();

        // تحديث المحادثة بـ UIDs منظفة
        await doc.reference.update({
          'user1Id': _normalizeUID(data['user1Id'] ?? ''),
          'user2Id': _normalizeUID(data['user2Id'] ?? ''),
          'senderId': _normalizeUID(data['senderId'] ?? ''),
          'receiverId': _normalizeUID(data['receiverId'] ?? ''),
          'participants': cleanedParticipants,
        });

        print('✅ تم إصلاح المحادثة: ${doc.id}');
      }

      print('✅ تم إصلاح جميع المحادثات');
    } catch (e) {
      print('❌ خطأ في إصلاح المحادثات: $e');
    }
  }

  /// ✅ حذف جميع المحادثات القديمة المُعطلة
  static Future<void> deleteAllBrokenChats() async {
    try {
      print('🗑️ بدء حذف المحادثات المُعطلة...');

      // جلب جميع المحادثات
      final chatsSnapshot = await _firestore.collection('chats').get();

      final batch = _firestore.batch();
      int deletedCount = 0;

      for (var doc in chatsSnapshot.docs) {
        print('🗑️ حذف المحادثة: ${doc.id}');

        // حذف جميع الرسائل في المحادثة أولاً
        final messagesSnapshot = await doc.reference.collection('messages').get();
        for (var messageDoc in messagesSnapshot.docs) {
          batch.delete(messageDoc.reference);
        }

        // حذف المحادثة نفسها
        batch.delete(doc.reference);
        deletedCount++;
      }

      await batch.commit();
      print('✅ تم حذف $deletedCount محادثة مُعطلة');
      print('✅ تم تنظيف قاعدة البيانات بالكامل');

    } catch (e) {
      print('❌ خطأ في حذف المحادثات: $e');
    }
  }

  /// ✅ إرسال رسالة اختبار
  static Future<void> sendTestMessage(String chatId, String otherUserUid, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final cleanCurrentUID = _normalizeUID(currentUser.uid);
      final cleanOtherUID = _normalizeUID(otherUserUid);
      final now = Timestamp.now();

      print('📤 إرسال رسالة اختبار:');
      print('   ChatID: $chatId');
      print('   Message: $message');

      // إضافة الرسالة
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'chatId': chatId,
        'senderId': cleanCurrentUID,
        'receiverId': cleanOtherUID,
        'text': message,
        'timestamp': now,
        'isRead': false,
      });

      print('✅ تم إضافة الرسالة: ${messageRef.id}');

      // تحديث آخر رسالة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'timestamp': now,
        'senderId': cleanCurrentUID,
        'receiverId': cleanOtherUID,
        'isSeen': false,
      });

      print('✅ تم تحديث آخر رسالة');

    } catch (e) {
      print('❌ خطأ في إرسال رسالة اختبار: $e');
    }
  }

  /// ✅ دالة جديدة للتحقق من الرسائل وتشخيص المشاكل
  static Future<void> debugMessages(String chatId) async {
    try {
      print('🔍 ===== تشخيص الرسائل في ChatID: $chatId =====');

      // التحقق من وجود المحادثة
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        print('❌ المحادثة غير موجودة!');
        return;
      }

      print('✅ المحادثة موجودة');
      final chatData = chatDoc.data() as Map<String, dynamic>;
      print('   Participants: ${chatData['participants']}');

      // التحقق من الرسائل
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      print('📨 إجمالي الرسائل: ${messagesSnapshot.docs.length}');

      if (messagesSnapshot.docs.isEmpty) {
        print('❌ لا توجد رسائل في هذه المحادثة!');
        print('🔧 جرب إرسال رسالة اختبار...');
        return;
      }

      // فحص كل رسالة
      for (int i = 0; i < messagesSnapshot.docs.length; i++) {
        final doc = messagesSnapshot.docs[i];
        final data = doc.data();

        print('📨 رسالة [$i]:');
        print('   ID: ${doc.id}');
        print('   Text: ${data['text']}');
        print('   SenderId: ${data['senderId']}');
        print('   ReceiverId: ${data['receiverId']}');
        print('   Timestamp: ${data['timestamp']} (Type: ${data['timestamp'].runtimeType})');
        print('   IsRead: ${data['isRead']}');
        print('   ---');
      }

      print('🔍 ===== انتهاء التشخيص =====');
    } catch (e) {
      print('❌ خطأ في تشخيص الرسائل: $e');
    }
  }
}