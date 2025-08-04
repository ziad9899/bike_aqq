// lib/screens/updates_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import '../services/chat_service.dart';

class UpdatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'المحادثات',
            style: TextStyle(
              color: Color(0xFF006241),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 80,
                color: Color(0xFF006241),
              ),
              SizedBox(height: 20),
              Text(
                'يجب تسجيل الدخول أولاً',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'المحادثات',
          style: TextStyle(
            color: Color(0xFF006241),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_comment_rounded,
              color: Color(0xFF006241),
              size: 28,
            ),
            onPressed: () => _showNewChatDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ استخدام الخدمة الموحدة
        stream: ChatService.getChatsStream(),
        builder: (context, snapshot) {
          print('🔥 StreamBuilder - current user UID: ${user.uid}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006241),
              ),
            );
          }

          if (snapshot.hasError) {
            print('❌ خطأ في Stream: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'خطأ في تحميل المحادثات',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;
          print('🔥 عدد المحادثات الموجودة: ${chats.length}');

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'لا توجد محادثات بعد',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ابحث عن المستخدمين المسجلين وابدأ محادثة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _showNewChatDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('بدء محادثة جديدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006241),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ترتيب المحادثات يدوياً
          final sortedChats = chats.toList();
          sortedChats.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;

            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;

            return bTimestamp.compareTo(aTimestamp);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedChats.length,
            itemBuilder: (context, index) {
              final chatData = sortedChats[index].data() as Map<String, dynamic>;
              final chatId = sortedChats[index].id;

              // ✅ تحديد المستخدم الآخر مع تنظيف شامل لـ UIDs
              final normalizedCurrentUID = ChatService.normalizeUID(user.uid);
              final normalizedUser1 = ChatService.normalizeUID(chatData['user1Id'] ?? '');
              final normalizedUser2 = ChatService.normalizeUID(chatData['user2Id'] ?? '');

              final otherUserId = normalizedUser1 == normalizedCurrentUID
                  ? chatData['user2Id']
                  : chatData['user1Id'];
              final otherUserName = normalizedUser1 == normalizedCurrentUID
                  ? chatData['user2Name']
                  : chatData['user1Name'];

              // معلومات آخر رسالة مع تنظيف UIDs
              final lastMessage = chatData['lastMessage'] ?? 'لا توجد رسائل';
              final normalizedSenderId = ChatService.normalizeUID(chatData['senderId'] ?? '');
              final normalizedReceiverId = ChatService.normalizeUID(chatData['receiverId'] ?? '');
              final isSeen = chatData['isSeen'] ?? true;

              // التحقق من الرسائل غير المقروءة
              final hasUnreadMessages = normalizedReceiverId == normalizedCurrentUID && !isSeen;
              final isMyLastMessage = normalizedSenderId == normalizedCurrentUID;

              // تنسيق الوقت
              final timestamp = chatData['timestamp'] as Timestamp?;
              final timeString = timestamp != null
                  ? _formatTime(timestamp.toDate())
                  : '';

              print('🔥 محادثة: $chatId - الطرف الآخر: $otherUserId ($otherUserName)');

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: hasUnreadMessages ? const Color(0xFFF0F8F5) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: hasUnreadMessages
                      ? Border.all(color: const Color(0xFF006241).withOpacity(0.3), width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF006241),
                        child: Text(
                          otherUserName != null && otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : 'م',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hasUnreadMessages)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName != null && otherUserName.isNotEmpty ? otherUserName : 'مستخدم',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (hasUnreadMessages)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (isMyLastMessage) ...[
                          Icon(
                            isSeen ? Icons.done_all : Icons.done,
                            size: 16,
                            color: isSeen ? const Color(0xFF25D366) : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              color: hasUnreadMessages ? const Color(0xFF333333) : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          color: hasUnreadMessages ? const Color(0xFF006241) : Colors.grey[500],
                          fontSize: 12,
                          fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: hasUnreadMessages ? const Color(0xFF006241) : Colors.grey[400],
                      ),
                    ],
                  ),
                  onTap: () {
                    // ✅ استخدام الدالة الموحدة الصحيحة دائماً
                    final unifiedChatId = ChatService.generateChatId(user.uid, otherUserId ?? '');

                    print('🔥 فتح المحادثة من updates_screen:');
                    print('   Current UID: ${user.uid}');
                    print('   Other UID: $otherUserId');
                    print('   Generated ChatID: $unifiedChatId');
                    print('   Firestore ChatID: $chatId'); // للمقارنة

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: unifiedChatId, // ✅ دائماً من generateChatId
                          otherUserId: otherUserId ?? '',
                          otherUserName: otherUserName ?? 'مستخدم',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const NewChatBottomSheet(),
    );
  }

  String _formatTime(DateTime timestamp) {
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
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

// Bottom Sheet لبدء محادثة جديدة
class NewChatBottomSheet extends StatefulWidget {
  const NewChatBottomSheet({Key? key}) : super(key: key);

  @override
  _NewChatBottomSheetState createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;
  bool _showAllUsers = true;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  void _loadAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('name')
          .limit(50)
          .get();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      setState(() {
        _allUsers = results.docs
            .where((doc) => doc.id != currentUser.uid)
            .map((doc) => {
          'uid': doc.id,
          'name': doc.data()['name'] ?? 'مستخدم',
          'email': doc.data()['email'] ?? '',
        })
            .toList();
        _isLoading = false;
      });

      print('🔥 تم تحميل ${_allUsers.length} مستخدم');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل المستخدمين: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showAllUsers = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showAllUsers = false;
    });

    try {
      final localResults = _allUsers
          .where((user) =>
      user['name'].toLowerCase().contains(query.toLowerCase()) ||
          user['email'].toLowerCase().contains(query.toLowerCase()))
          .toList();

      setState(() {
        _searchResults = localResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في البحث: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ تعديل دالة بدء المحادثة باستخدام الخدمة الموحدة
  void _startChat(String otherUserUid, String otherUserName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // ✅ استخدام الخدمة الموحدة
      final chatId = ChatService.generateChatId(currentUser.uid, otherUserUid);

      print('🔥 بدء محادثة جديدة من NewChatBottomSheet:');
      print('   Current UID: ${currentUser.uid}');
      print('   Other UID: $otherUserUid');
      print('   Generated ChatID: $chatId');

      // إنشاء المحادثة إذا لم تكن موجودة
      await ChatService.createOrGetChat(otherUserUid, otherUserName);

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserId: otherUserUid,
            otherUserName: otherUserName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء المحادثة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUsers = _showAllUsers ? _allUsers : _searchResults;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'بدء محادثة مع مستخدم مسجل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مستخدم بالاسم أو الإيميل...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF006241)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF006241)),
                    ),
                  ),
                  onChanged: _searchUsers,
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006241),
              ),
            )
                : displayUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAllUsers ? Icons.people_outline : Icons.search_off,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showAllUsers
                        ? 'لا يوجد مستخدمين مسجلين'
                        : 'لا توجد نتائج للبحث',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: displayUsers.length,
              itemBuilder: (context, index) {
                final user = displayUsers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF006241),
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    subtitle: Text(
                      '${user['email']} (${user['uid'].substring(0, 8)}...)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF006241),
                    ),
                    onTap: () => _startChat(user['uid'], user['name']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}