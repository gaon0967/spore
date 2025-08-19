import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// 🔥 ==========================================================
// 🔥 서비스 클래스: Firebase와의 모든 통신을 담당합니다.
// 🔥 ==========================================================
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // 범용 알림 생성 함수
  Future<void> createNotification({
    required String receiverId,
    required String title,
    required String content,
    String? senderId,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    // ✅ 'users' 컬렉션 아래의 'notifications' 하위 컬렉션으로 경로 변경
    if (receiverId.isEmpty) {
      print('알림 생성 오류: receiverId가 비어있습니다.');
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        // 'receiverId'는 경로에 포함되므로 문서 데이터에서는 필수가 아님 (필요시 유지)
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': senderId,
        'type': type,
        'data': data,
        'read': false,
      });
    } catch (e) {
      print('알림 생성 오류: $e');
    }
  }

  // 친구 신청 알림
  Future<void> createFriendRequestNotification(String receiverId, String senderName) async {
    await createNotification(
        receiverId: receiverId,
        title: '친구 알림',
        content: '$senderName 님이 친구신청을 보냈습니다.',
        senderId: currentUserId,
        type: 'friend_request');
  }

  // 메시지 알림
  Future<void> createMessageNotification(String receiverId, String senderName) async {
    await createNotification(
        receiverId: receiverId,
        title: '친구 알림',
        content: '$senderName 님이 메세지를 보냈습니다.',
        senderId: currentUserId,
        type: 'message');
  }

  // 친구 수락 알림
  Future<void> createFriendAcceptedNotification(String receiverId, String accepterName) async {
    await createNotification(
        receiverId: receiverId,
        title: '친구 알림',
        content: '$accepterName 님과 친구가 되었습니다.',
        senderId: currentUserId,
        type: 'friend_accepted');
  }

  // 친구 신청 수락 처리
  Future<void> acceptFriendRequest(String senderId) async {
    if (currentUserId == null) return;
    try {
      final batch = _firestore.batch();
      final myFriendsRef = _firestore.collection('users').doc(currentUserId).collection('friends').doc(senderId);
      final theirFriendsRef = _firestore.collection('users').doc(senderId).collection('friends').doc(currentUserId);
      batch.set(myFriendsRef, {'friendId': senderId, 'favorite': false, 'blockStatus': false, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(theirFriendsRef, {'friendId': currentUserId, 'favorite': false, 'blockStatus': false, 'createdAt': FieldValue.serverTimestamp()});

      // ✅ 참고: 친구 요청 경로는 이전 대화에서 수정한 버전을 사용해야 합니다.
      // 여기서는 최상위 컬렉션으로 가정하고 작성합니다.
      final requestQuery = await _firestore.collection('friendRequests').where('senderId', isEqualTo: senderId).where('receiverId', isEqualTo: currentUserId).get();
      for (var doc in requestQuery.docs) { batch.delete(doc.reference); }

      // ✅ 알림 삭제 경로를 하위 컬렉션으로 변경
      final notificationQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('senderId', isEqualTo: senderId)
          .where('type', isEqualTo: 'friend_request')
          .get();
      for (var doc in notificationQuery.docs) { batch.delete(doc.reference); }

      await batch.commit();

      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final myName = currentUserDoc.data()?['nickName'] ?? 'Unknown';
      await createFriendAcceptedNotification(senderId, myName);
    } catch (e) {
      print('친구 신청 수락 오류: $e');
      rethrow;
    }
  }

  // 친구 신청 거절 처리
  Future<void> rejectFriendRequest(String senderId) async {
    if (currentUserId == null) return;
    try {
      final batch = _firestore.batch();

      final requestQuery = await _firestore.collection('friendRequests').where('senderId', isEqualTo: senderId).where('receiverId', isEqualTo: currentUserId).get();
      for (var doc in requestQuery.docs) { batch.delete(doc.reference); }

      // ✅ 알림 삭제 경로를 하위 컬렉션으로 변경
      final notificationQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('senderId', isEqualTo: senderId)
          .where('type', isEqualTo: 'friend_request')
          .get();
      for (var doc in notificationQuery.docs) { batch.delete(doc.reference); }
      await batch.commit();
    } catch (e) {
      print('친구 신청 거절 오류: $e');
      rethrow;
    }
  }

  // 내 알림 목록 실시간으로 가져오기
  Stream<List<AppNotification>> getMyNotifications() {
    if (currentUserId == null) return Stream.value([]);
    // ✅ 알림 조회 경로를 하위 컬렉션으로 변경 (where 불필요)
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  // 알림 한 개 삭제
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId == null) return;
    // ✅ 알림 삭제 경로를 하위 컬렉션으로 변경
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // 모든 알림 삭제
  Future<void> deleteAllNotifications() async {
    if (currentUserId == null) return;
    final batch = _firestore.batch();
    // ✅ 모든 알림 조회 경로를 하위 컬렉션으로 변경
    final notifications = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .get();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

// 🔥 ==========================================================
// 🔥 데이터 모델 클래스
// 🔥 ==========================================================
class AppNotification {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final String? senderId;
  final String? type;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.senderId,
    this.type,
    this.data,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      senderId: data['senderId'],
      type: data['type'],
      data: data['data'] is Map ? Map<String, dynamic>.from(data['data']) : null,
    );
  }
}

// 🔥 ==========================================================
// 🔥 UI 위젯
// 🔥 ==========================================================
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  late Stream<List<AppNotification>> _notificationStream;

  @override
  void initState() {
    super.initState();
    _notificationStream = _notificationService.getMyNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationStream = _notificationService.getMyNotifications();
    });
  }

  void _clearAllNotificationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('알림 전체 삭제'),
          content: Text('모든 알림을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('아니오'),
            ),
            TextButton(
              onPressed: () async {
                await _notificationService.deleteAllNotifications();
                if (mounted) Navigator.of(context).pop();
              },
              child: Text('네'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFFFFEF9),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFEF9),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Image.asset('assets/images/Setting/go.png', width: screenWidth * 0.045, height: screenWidth * 0.045),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('알림', style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w700, fontSize: screenWidth * 0.047, color: Color(0xFF504A4A))),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: _notificationStream,
            builder: (context, snapshot) {
              final bool isEmpty = !(snapshot.hasData && snapshot.data!.isNotEmpty);
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.07),
                  child: GestureDetector(
                    onTap: isEmpty ? null : _clearAllNotificationsDialog,
                    child: Text('전체 삭제', style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w600, fontSize: screenWidth * 0.034, color: isEmpty ? Colors.grey : Color(0xFFDA6464))),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('알림을 불러오는 중 오류가 발생했습니다.'));
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(child: Text('알림이 없습니다.', style: TextStyle(fontFamily: 'Golos Text', fontSize: 15, color: Color(0xFF504A4A))));
          }
          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final noti = notifications[index];
                return _NotificationItem(
                  key: ValueKey(noti.id),
                  notification: noti,
                  notificationService: _notificationService,
                  onAction: _refreshNotifications, // 액션 후 리스트 갱신
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final NotificationService notificationService;
  final VoidCallback onAction;

  const _NotificationItem({
    required Key key,
    required this.notification,
    required this.notificationService,
    required this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        key: ValueKey(notification.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) async {
                await notificationService.deleteNotification(notification.id);
              },
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF979797),
              label: '삭제',
            ),
          ],
        ),
        child: _buildStyledNotiBox(notification, context, notificationService, onAction),
      ),
    );
  }
}

// UI 헬퍼 함수
Widget _buildStyledNotiBox(AppNotification noti, BuildContext context, NotificationService notificationService, VoidCallback onAction) {
  final screenWidth = MediaQuery.of(context).size.width;
  Widget iconWidget;
  String label;
  Widget? actionButtons;

  final nameMatch = RegExp(r'(\S+)\s님').firstMatch(noti.content);
  final userName = nameMatch?.group(1) ?? '';

  switch (noti.type) {
    case 'friend_request':
      label = '친구';
      iconWidget = Image.asset('assets/images/Notification/friend.png', width: screenWidth * 0.09, height: screenWidth * 0.09);
      actionButtons = _buildRequestButtons(context, noti, userName, notificationService, onAction);
      break;
    case 'friend_accepted':
      label = '친구';
      iconWidget = Image.asset('assets/images/Notification/friend.png', width: screenWidth * 0.09, height: screenWidth * 0.09);
      break;
    case 'message':
      label = '친구';
      iconWidget = Image.asset('assets/images/Notification/friend.png', width: screenWidth * 0.09, height: screenWidth * 0.09);
      // Optional: Add a button to go to chat
      break;
    default:
      label = '알림';
      iconWidget = Icon(Icons.notifications, size: screenWidth * 0.07);
  }

  return Container(
    padding: EdgeInsets.all(screenWidth * 0.031),
    decoration: BoxDecoration(color: Color(0xFFFFFEF9), borderRadius: BorderRadius.circular(25)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: screenWidth * 0.12, height: screenWidth * 0.12, child: Center(child: iconWidget)),
            SizedBox(width: screenWidth * 0.01),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w500, fontSize: screenWidth * 0.029, color: Color(0xFFA5A5A5))),
                  SizedBox(height: 2),
                  Text.rich(
                    TextSpan(children: _buildStyledTextSpans(noti.content, userName)),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (actionButtons != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: actionButtons,
          ),
      ],
    ),
  );
}

Widget _buildRequestButtons(BuildContext context, AppNotification noti, String userName, NotificationService service, VoidCallback onAction) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: () async {
          if (noti.senderId == null) return;
          try {
            await service.acceptFriendRequest(noti.senderId!);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userName님과 친구가 되었습니다!')));
            onAction(); // 리스트 새로고침
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('요청 수락 중 오류 발생')));
          }
        },
        child: Text('수락', style: TextStyle(color: Colors.blue)),
      ),
      SizedBox(width: 8),
      TextButton(
        onPressed: () async {
          if (noti.senderId == null) return;
          try {
            await service.rejectFriendRequest(noti.senderId!);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('친구 요청을 거절했습니다.')));
            onAction(); // 리스트 새로고침
          } catch(e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('요청 거절 중 오류 발생')));
          }
        },
        child: Text('거절', style: TextStyle(color: Colors.red)),
      ),
    ],
  );
}

List<TextSpan> _buildStyledTextSpans(String content, String userName) {
  final baseStyle = TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w500, fontSize: 13.5, color: Color(0xFF645E5E));
  final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w800);

  if (userName.isNotEmpty && content.contains(userName)) {
    final parts = content.split(userName);
    return [
      TextSpan(text: parts[0], style: baseStyle),
      TextSpan(text: userName, style: boldStyle),
      if (parts.length > 1) TextSpan(text: parts[1], style: baseStyle),
    ];
  }
  return [TextSpan(text: content, style: baseStyle)];
}