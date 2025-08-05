// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    print('🔥 ====================== فتح المحادثة ======================');
    print('🔥 Chat ID: ${widget.chatId}');
    print('🔥 Firebase UID الحالي: ${currentUser.uid}');
    print('🔥 Firebase UID الآخر: ${widget.otherUserId}');
    print('🔥 اسم المستخدم الآخر: ${widget.otherUserName}');
    print('🔥 مسار Firestore: chats/${widget.chatId}/messages');

    // التحقق من تطابق ChatID
    final expectedChatId = ChatService.generateChatId(currentUser.uid, widget.otherUserId);
    if (widget.chatId == expectedChatId) {
      print('✅ ChatID متطابق مع الخدمة الموحدة');
    } else {
      print('⚠️ ChatID غير متطابق!');
      print('   المُرسل: ${widget.chatId}');
      print('   المتوقع: $expectedChatId');
    }
    print('🔥 ========================================================');

    // ✅ استخدام الخدمة الموحدة
    ChatService.markMessagesAsRead(widget.chatId);
    _checkChatExists();
    _testStreamPeriodically();

    // ✅ تشخيص الرسائل
    ChatService.debugMessages(widget.chatId);
  }

  void _testStreamPeriodically() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkMessagesDirectly();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkMessagesDirectly() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .get();

      print('🔍 فحص دوري - عدد الرسائل: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('🔍 رسالة: ${data['text']} - من: ${data['senderId']}');
      }
    } catch (e) {
      print('❌ خطأ في الفحص الدوري: $e');
    }
  }

  Future<void> _checkChatExists() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        print('✅ المحادثة موجودة: ${data['participants']}');
        print('✅ آخر رسالة: ${data['lastMessage']}');

        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .get();

        print('✅ عدد الرسائل الموجودة: ${messagesSnapshot.docs.length}');

        for (var doc in messagesSnapshot.docs) {
          final msgData = doc.data();
          print('📨 رسالة: ${msgData['text']} - من: ${msgData['senderId']} - وقت: ${msgData['timestamp']}');
        }
      } else {
        print('❌ المحادثة غير موجودة!');
      }
    } catch (e) {
      print('❌ خطأ في التحقق من المحادثة: $e');
    }
  }

  // ✅ تعديل دالة إرسال الرسالة لاستخدام الخدمة الموحدة
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      print('📤 إرسال رسالة: "$text"');
      print('📍 في المحادثة: ${widget.chatId}');
      print('📍 إلى Firebase UID: ${widget.otherUserId}');

      // ✅ استخدام الخدمة الموحدة
      await ChatService.sendMessage(widget.chatId, widget.otherUserId, text);

      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      print('✅ تم إرسال الرسالة بنجاح!');
    } catch (e) {
      print('❌ خطأ في إرسال الرسالة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الرسالة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF006241),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : 'م',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'UID: ${widget.otherUserId.substring(0, 8)}...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ✅ استخدام الخدمة الموحدة مع includeMetadataChanges
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snapshot) {
                final currentTime = DateTime.now().millisecondsSinceEpoch;
                final currentUser = FirebaseAuth.instance.currentUser;

                print('📡 =================== Stream Update ($currentTime) ===================');
                print('📡 Connection State: ${snapshot.connectionState}');
                print('📡 Has Data: ${snapshot.hasData}');
                print('📡 Has Error: ${snapshot.hasError}');
                print('📡 Chat Path: chats/${widget.chatId}/messages');
                print('📡 Current Firebase UID: ${currentUser?.uid}');
                if (snapshot.hasData) {
                  print('📡 isFromCache: ${snapshot.data!.metadata.isFromCache}');
                }

                if (snapshot.hasError) {
                  print('❌ Stream Error Details: ${snapshot.error}');
                  print('❌ Error Type: ${snapshot.error.runtimeType}');
                }

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  print('📨 إجمالي الرسائل: ${docs.length}');

                  if (docs.isNotEmpty) {
                    print('📨 تفاصيل الرسائل:');
                    for (int i = 0; i < docs.length && i < 3; i++) { // أول 3 رسائل فقط
                      final data = docs[i].data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'];
                      print('   [$i] "${data['text']}" - من: ${data['senderId']}');
                      print('       timestamp: $timestamp (${timestamp.runtimeType})');
                    }
                  } else {
                    print('📨 لا توجد رسائل في المجموعة');
                  }
                } else {
                  print('📨 لا توجد بيانات في Snapshot');
                }
                print('📡 ================================================================');

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 60, color: Colors.red),
                        SizedBox(height: 16),
                        Text('خطأ في Stream:', style: TextStyle(color: Colors.red, fontSize: 16)),
                        Text('${snapshot.error}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF006241)),
                        SizedBox(height: 16),
                        Text('جاري تحميل الرسائل...'),
                        Text('Chat ID: ${widget.chatId}', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final allMessages = snapshot.data?.docs ?? [];

                // ✅ إزالة التصفية مؤقتاً لعرض كل شيء
                final messages = allMessages.toList(); // مؤقتاً لعرض كل شيء

                print('📨 إجمالي الرسائل (بدون تصفية): ${messages.length}');

                // ✅ ترتيب واضح للرسائل
                messages.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  final timestampA = dataA['timestamp'];
                  final timestampB = dataB['timestamp'];

                  // التعامل مع الرسائل التي قد لا تحتوي على timestamp
                  if (timestampA == null && timestampB == null) return 0;
                  if (timestampA == null) return 1;
                  if (timestampB == null) return -1;

                  if (timestampA is Timestamp && timestampB is Timestamp) {
                    return timestampB.compareTo(timestampA); // تنازلي
                  }

                  return 0;
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text('لا توجد رسائل بعد', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        SizedBox(height: 8),
                        Text('ابدأ المحادثة بإرسال رسالة', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        SizedBox(height: 8),
                        Text('Chat ID: ${widget.chatId}', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkMessagesDirectly,
                          child: Text('تحديث الرسائل'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = ChatService.normalizeUID(messageData['senderId'] ?? '') ==
                        ChatService.normalizeUID(currentUser?.uid ?? '');

                    // ✅ تشخيص مُفصل للرسائل
                    print('📡 رسالة [$index]: ${messageData['text']}');
                    print('📡 الرسالة موجهة إلى: ${messageData['receiverId']}');
                    print('📡 معرف المستخدم الحالي: ${currentUser?.uid}');
                    print('📡 المرسل: ${messageData['senderId']}');
                    print('📡 هل هي رسالتي؟ $isMe');
                    print('📡 ---');

                    final timestamp = messageData['timestamp'];

                    final text = messageData['text'] ?? '';
                    String timeString = '';

                    // التعامل مع timestamp بمرونة أكثر
                    if (timestamp != null && timestamp is Timestamp) {
                      timeString = _formatMessageTime(timestamp.toDate());
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF006241),
                              child: Text(
                                widget.otherUserName.isNotEmpty
                                    ? widget.otherUserName[0].toUpperCase()
                                    : 'م',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF006241)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: isMe
                                      ? const Radius.circular(18)
                                      : const Radius.circular(4),
                                  bottomRight: isMe
                                      ? const Radius.circular(4)
                                      : const Radius.circular(18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : const Color(0xFF333333),
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (timeString.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            messageData['isRead'] == true
                                                ? Icons.done_all
                                                : Icons.done,
                                            size: 14,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                'أ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF006241),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'أمس';
    } else if (now.difference(timestamp).inDays < 7) {
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[timestamp.weekday % 7];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}