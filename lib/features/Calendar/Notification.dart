import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:new_project_1/features/Friend/FriendScreen.dart';

// --- 데이터 모델 클래스 (파일 상단에 위치) ---
// [수정됨] AppNotification 모델에 친구 알림을 위한 type, senderId 추가 및 fromFirestore 팩토리 생성자 추가
class ScheduledEvent {
  final String eventId; // Firestore의 고유 문서 ID
  final String title;
  final DateTime dueDate;
  final bool isDone;

  ScheduledEvent({
    required this.eventId,
    required this.title,
    required this.dueDate,
    required this.isDone,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final String? eventTitle; // D-Day 알림용
  final DateTime? dueDate; // D-Day 알림용
  final String? type; // 알림 종류 (예: 'friend_request')
  final String? senderId; // 보낸 사람 ID

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.eventTitle,
    this.dueDate,
    this.type,
    this.senderId,
  });

  // Firestore 문서로부터 AppNotification 객체를 생성하는 팩토리 생성자
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      type: data['type'],
      senderId: data['senderId'],
    );
  }
}
// -----------------------------------------

// --- [추가됨] Firebase 통신을 담당하는 서비스 클래스 ---
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  Future<void> createNotification({
    required String receiverId,
    required String title,
    required String content,
    String? senderId,
    String? type,
  }) async {
    if (receiverId.isEmpty) {
      print('알림 생성 오류: receiverId가 비어있습니다.');
      return;
    }

    // 🔑 알림 꺼져 있으면 아예 생성 안 함
    final receiverDoc =
    await _firestore.collection('users').doc(receiverId).get();
    final enabled = receiverDoc.data()?['notificationsEnabled'] ?? true;
    if (!enabled) {
      print("알림 꺼짐 상태 → 알림 생성 안 함");
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': senderId,
        'type': type,
        'read': false,
      });
    } catch (e) {
      print('알림 생성 오류: $e');
    }
  }

  // 친구 신청 알림 생성 함수 (에러의 원인이 된 함수)
  Future<void> createFriendRequestNotification(String receiverId, String senderName) async {
    await createNotification(
      receiverId: receiverId,
      title: '친구 알림',
      content: '$senderName 님이 친구신청을 보냈습니다.',
      senderId: currentUserId,
      type: 'friend_request'
    );
  }
  // 친구 신청 수락 처리
  Future<void> acceptFriendRequest(String senderId) async {
    if (currentUserId == null) return;
    try {
      final batch = _firestore.batch();

      // 나와 상대방의 friends 컬렉션에 서로를 추가
      final myFriendsRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(senderId);
      final theirFriendsRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(currentUserId);
      batch.set(myFriendsRef, {'friendId': senderId, 'favorite': false, 'blockStatus': false, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(theirFriendsRef, {'friendId': currentUserId, 'favorite': false, 'blockStatus': false, 'createdAt': FieldValue.serverTimestamp()});

      // 친구 요청 알림 삭제
      final notificationQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('senderId', isEqualTo: senderId)
          .where('type', isEqualTo: 'friend_request')
          .get();
      for (var doc in notificationQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 상대방에게 '친구가 되었다'는 알림 보내기
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
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
      // 친구 요청 알림만 삭제
      final notificationQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('senderId', isEqualTo: senderId)
          .where('type', isEqualTo: 'friend_request')
          .get();
      for (var doc in notificationQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('친구 신청 거절 오류: $e');
      rethrow;
    }
  }

  // 친구 수락 알림 생성
  Future<void> createFriendAcceptedNotification(
      String receiverId, String accepterName) async {
    if (receiverId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('notifications')
        .add({
      'title': '친구 알림',
      'content': '$accepterName 님과 친구가 되었습니다.',
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': currentUserId,
      'type': 'friend_accepted',
      'read': false,
    });
  }

  // 알림 한 개 삭제
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // (D-Day 제외) 모든 알림 삭제
  Future<void> deleteAllNotifications() async {
    if (currentUserId == null) return;
    final batch = _firestore.batch();
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

  // 유저의 알림 허용 여부 확인
  Future<bool> isNotificationEnabled() async {
    if (currentUserId == null) return false;
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    return userDoc.data()?['notificationsEnabled'] ?? true; // 기본값 true
  }

  // 알림 설정 업데이트
  Future<void> setNotificationEnabled(bool enabled) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).update({
      'notificationsEnabled': enabled,
    });
  }

}
// -----------------------------------------

// --- 스타일 및 UI 헬퍼 함수 ---
final baseStyle = TextStyle(
  fontFamily: 'Golos Text',
  fontWeight: FontWeight.w500,
  fontSize: 13.5,
  color: Color(0xFF645E5E),
);

final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w800);

List<TextSpan> _buildStyledTextSpans(AppNotification noti) {
  // D-Day 알림 처리: eventTitle을 볼드체로 만듭니다.
  if (noti.title.contains("D-Day") && noti.eventTitle != null) {
    if (noti.content == "오늘") {
      return [
        TextSpan(text: "오늘은 ", style: baseStyle),
        TextSpan(text: noti.eventTitle!, style: boldStyle), // 볼드 스타일 적용
        TextSpan(text: " 이(가) 있는 날입니다.", style: baseStyle),
      ];
    } else {
      return [
        TextSpan(text: noti.eventTitle!, style: boldStyle), // 볼드 스타일 적용
        TextSpan(text: " ${noti.content}", style: baseStyle),
      ];
    }
  }

  // 친구 알림 처리: 닉네임을 찾아서 볼드체로 만듭니다.
  final nameMatch = RegExp(r'(\S+)\s님').firstMatch(noti.content);
  final userName = nameMatch?.group(1);
  if (userName != null && userName.isNotEmpty) {
    final splitContent = noti.content.split(userName);
    return [
      TextSpan(text: splitContent[0], style: baseStyle),
      TextSpan(text: userName, style: boldStyle), // 볼드 스타일 적용
      if (splitContent.length > 1)
        TextSpan(text: splitContent[1], style: baseStyle),
    ];
  }

  // 그 외 모든 일반 알림
  return [TextSpan(text: noti.content, style: baseStyle)];
}


Widget _buildStyledNotiBox(
  AppNotification noti,
  BuildContext context,
  Function(DateTime) onGoToCalendar,
  void Function({int tabIndex, bool expandRequests}) onNavigateToFriendsCallback,
) {
  Color bgColor = Color(0xF4F4F4F4);
  String? label;
  String? badgeText;
  String? rightText;
  Widget iconWidget = SizedBox.shrink();

  final nameMatch = RegExp(r'(\S+)\s님').firstMatch(noti.content);
  final userName = nameMatch != null ? nameMatch.group(1)! : '';

  final screenWidth = MediaQuery.of(context).size.width;

  if (noti.title.contains("D-Day")) {
    label = '일정';
    iconWidget = Image.asset(
      'assets/images/Notification/calendar.png',
      width: screenWidth * 0.06,
      height: screenWidth * 0.06,
    );
    rightText = '바로 가기';
  } else if (noti.type?.startsWith('friend_') ??
      noti.title.contains('친구')) { // [수정] type이 'friend_'로 시작하는 모든 알림(friend_request, friend_accepted 등)을 이 조건문에서 처리합니다.
    label = '친구';
    iconWidget = Image.asset(
      'assets/images/Notification/friend.png',
      width: screenWidth * 0.09,
      height: screenWidth * 0.09,
    );
    rightText = '바로 가기'; // [수정] 모든 친구 알림에 '바로 가기'를 표시
  } else if (noti.type == 'title' ||
      noti.title.contains('타이틀')) {
    label = '타이틀';
    iconWidget = Image.asset(
      'assets/images/Notification/title.png',
      width: screenWidth * 0.06,
      height: screenWidth * 0.06,
    );
    badgeText = '언제든 놀자!';
    rightText = '바로 가기';
  }

  // [수정] '수락'/'거절' 버튼을 만들던 로직을 삭제하고, '바로 가기' 버튼을 만드는 로직으로 통합
  Widget? actionArea;
  if (rightText != null) {
    actionArea = Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          if (noti.title.contains("D-Day") && noti.dueDate != null) {
            onGoToCalendar(noti.dueDate!);
          }
          // 친구 관련 알림일 경우
          else if (noti.type?.startsWith('friend_') ?? noti.title.contains('친구')) {
            if (noti.type == 'friend_request') {
              // '친구 신청' 알림 -> 친구 신청 목록으로 이동 (기존 동작)
              onNavigateToFriendsCallback(
                tabIndex: 1, 
                expandRequests: true,
              );
            } else { 
              // '친구가 되었습니다' 및 기타 친구 알림 -> 친구 목록으로 이동
              onNavigateToFriendsCallback(
                tabIndex: 0, // 친구 목록 탭
                expandRequests: false, 
              );
            }
            Navigator.of(context).pop();
          }
          
          // TODO: 다른 '바로 가기' 액션이 있다면 여기에 추가
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rightText,
              style: TextStyle(
                fontFamily: 'Golos Text',
                fontWeight: FontWeight.w500,
                fontSize: screenWidth * 0.028,
                color: Color(0xFF635E5E),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Image.asset(
              'assets/images/Setting/chevron.png',
              width: screenWidth * 0.015,
              height: screenWidth * 0.029,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  return Container(
    padding: EdgeInsets.all(screenWidth * 0.031),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(25),
    ),
    child: Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              margin: EdgeInsets.only(right: screenWidth * 0.009),
              child: Center(child: iconWidget),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: screenWidth * 0.0005),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Golos Text',
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.029,
                          color: Color(0xFFA5A5A5),
                        ),
                      ),
                    ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: _buildStyledTextSpans(noti),
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          margin: EdgeInsets.only(left: screenWidth * 0.025),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF4ECD2),
                            border: Border.all(color: Color(0xFF6A6A6A)),
                            borderRadius: BorderRadius.circular(47),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Golos Text',
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.03,
                              color: Color(0xFF413B3B),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (actionArea != null) actionArea,
      ],
    ),
  );
}

class NotificationPage extends StatefulWidget {
  final void Function({int tabIndex, bool expandRequests}) onNavigateToFriends;
  const NotificationPage({super.key, required this.onNavigateToFriends});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> notiList = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int? _pressedIndex;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_currentUser == null) return;

    final (dismissedIds, scheduledEvents, otherNotifications) = await (
      _fetchDismissedNotificationIds(),
      _fetchScheduledEvents(),
      _fetchOtherNotifications(),
    ).wait;

    await _cleanupDismissedIds(dismissedIds, scheduledEvents);

    List<AppNotification> allPotentialNotifications = [];

    allPotentialNotifications.addAll(
      _generateDDayNotifications(scheduledEvents, dismissedIds),
    );

    allPotentialNotifications.addAll(otherNotifications);

    final now = DateTime.now();
    final visibleNotifications = allPotentialNotifications.where((noti) {
      final hasArrived = noti.timestamp.isBefore(now);
      final notDismissed = !dismissedIds.contains(noti.id);
      return hasArrived && (noti.id.startsWith('dday_') ? notDismissed : true);
    }).toList();

    visibleNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        notiList = visibleNotifications;
      });
    }
  }

  Future<List<AppNotification>> _fetchOtherNotifications() async {
    if (_currentUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('notifications')
          .get();
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Firestore 알림 가져오기 오류: $e");
      return [];
    }
  }

  Future<List<String>> _fetchDismissedNotificationIds() async {
    if (_currentUser == null) return [];
    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists &&
          userDoc.data()!.containsKey('dismissedNotificationIds')) {
        return List<String>.from(userDoc.data()!['dismissedNotificationIds']);
      }
    } catch (e) {
      print("삭제된 알림 ID 가져오기 오류: $e");
    }
    return [];
  }

  Future<void> _cleanupDismissedIds(
    List<String> dismissedIds,
    List<ScheduledEvent> allEvents,
  ) async {
    if (_currentUser == null || dismissedIds.isEmpty) return;

    final eventsMap = {for (var e in allEvents) e.eventId: e};

    final idsToRemove = <String>[];

    for (final dismissedId in dismissedIds) {
      if (!dismissedId.startsWith('dday_')) continue;

      final eventId = dismissedId.replaceFirst('dday_', '');
      final correspondingEvent = eventsMap[eventId];

      if (correspondingEvent == null) {
        idsToRemove.add(dismissedId);
        continue;
      }

      if (correspondingEvent.isDone) {
        idsToRemove.add(dismissedId);
      }
    }

    if (idsToRemove.isNotEmpty) {
      print("삭제 기록 청소 (완료/삭제된 일정): $idsToRemove");
      final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
      try {
        await userDocRef.update({
          'dismissedNotificationIds': FieldValue.arrayRemove(idsToRemove),
        });
      } catch (e) {
        print("알림 기록 청소 오류: $e");
      }
    }
  }

  Future<List<ScheduledEvent>> _fetchScheduledEvents() async {
    if (_currentUser == null) return [];
    final List<ScheduledEvent> events = [];
    final docRef = _firestore.collection('plans').doc(_currentUser!.uid);
    try {
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data['date'] != null) {
          final dateMap = data['date'] as Map<String, dynamic>;
          dateMap.forEach((dateString, dailyEventsMap) {
            final eventDate = DateTime.parse(dateString);
            (dailyEventsMap as Map<String, dynamic>).forEach((
              eventId,
              eventData,
            ) {
              final title = eventData['title'] as String?;
              final isDone = eventData['isDone'] as bool? ?? false;

              if (title != null) {
                events.add(
                  ScheduledEvent(
                    eventId: eventId,
                    title: title,
                    dueDate: eventDate,
                    isDone: isDone,
                  ),
                );
              }
            });
          });
        }
      }
    } catch (e) {
      print("Firestore plans 데이터 가져오기 오류: $e");
    }
    return events;
  }

  List<AppNotification> _generateDDayNotifications(
    List<ScheduledEvent> events,
    List<String> dismissedIds,
  ) {
    final List<AppNotification> ddayNotifications = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final event in events) {
      if (event.isDone) continue;

      final notificationId = 'dday_${event.eventId}';
      if (dismissedIds.contains(notificationId)) {
        continue;
      }

      final eventDate = DateTime(
        event.dueDate.year,
        event.dueDate.month,
        event.dueDate.day,
      );
      String? content;
      DateTime? notificationTimestamp;

      if (eventDate.isAtSameMomentAs(today)) {
        content = "오늘";
        notificationTimestamp = DateTime(today.year, today.month, today.day, 7, 0);

      } else if (eventDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
        content = "까지 1일 남았습니다.";
        notificationTimestamp = DateTime(today.year, today.month, today.day, 19, 0);

      } else if (eventDate.isAtSameMomentAs(today.add(const Duration(days: 7)))) {
        content = "까지 7일 남았습니다.";
        notificationTimestamp = DateTime(today.year, today.month, today.day, 21, 0);
      }

      if (content != null && notificationTimestamp != null) {
        final notification = AppNotification(
          id: notificationId,
          title: 'D-Day 알림',
          content: content,
          eventTitle: event.title,
          dueDate: event.dueDate,
          timestamp: notificationTimestamp,
        );
        ddayNotifications.add(notification);
      }
    }
    
    ddayNotifications.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ddayNotifications;
  }

  Future<void> _dismissNotificationInFirestore(String notificationId) async {
    if (_currentUser == null) return;
    final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
    try {
      await userDocRef.set({
        'dismissedNotificationIds': FieldValue.arrayUnion([notificationId]),
      }, SetOptions(merge: true));
    } catch (e) {
      print("알림 삭제 기록 저장 오류: $e");
    }
  }

  Future<void> _dismissAllNotificationsInFirestore(
    List<String> notificationIds,
  ) async {
    if (_currentUser == null || notificationIds.isEmpty) return;
    final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
    try {
      await userDocRef.set({
        'dismissedNotificationIds': FieldValue.arrayUnion(notificationIds),
      }, SetOptions(merge: true));
    } catch (e) {
      print("전체 알림 삭제 기록 저장 오류: $e");
    }
  }

  void _clearNotis() {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color(0xFFFFFEF9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: screenWidth * 0.7,
            height: screenWidth * 0.43,
            decoration: BoxDecoration(
              color: Color(0xFFFFFEF9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        '알림을 모두 삭제하시겠습니까?',
                        style: TextStyle(
                          fontFamily: 'Golos Text',
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.035,
                          color: Color(0xFF716969),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: Color(0xFFE5E5E5)),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFFFFEF9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.035,
                          ),
                        ),
                        child: Text(
                          '아니오',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: screenWidth * 0.035,
                            color: Color(0xFF635E5E),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: screenWidth * 0.1,
                      color: Color(0xFFE5E5E5),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final dDayIdsToDismiss = notiList
                              .where((noti) => noti.id.startsWith('dday_'))
                              .map((noti) => noti.id)
                              .toList();

                          if (dDayIdsToDismiss.isNotEmpty) {
                            await _dismissAllNotificationsInFirestore(
                              dDayIdsToDismiss,
                            );
                          }

                          await _notificationService.deleteAllNotifications();

                          if (mounted) Navigator.of(context).pop();

                          await _loadNotifications();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFFFFEF9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.035,
                          ),
                        ),
                        child: Text(
                          '네',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: screenWidth * 0.035,
                            color: Color(0xFF2F3BDC),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeItem(int index) {
    if (index >= notiList.length) return;

    final AppNotification removedItem = notiList.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovingItem(removedItem, animation),
      duration: const Duration(milliseconds: 180),
    );

    if (removedItem.id.startsWith('dday_')) {
      _dismissNotificationInFirestore(removedItem.id);
    } else {
      _notificationService.deleteNotification(removedItem.id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFFFFEF9),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFEF9),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFFFFFEF9),
          statusBarIconBrightness: Brightness.dark,
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/Setting/go.png',
            width: screenWidth * 0.045,
            height: screenWidth * 0.045,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: Color(0xFF504A4A)),
        title: Text(
          '알림',
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.047,
            color: Color(0xFF504A4A),
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                right: screenWidth * 0.07,
                bottom: screenWidth * 0.0005,
              ),
              child: GestureDetector(
                onTap: notiList.isEmpty ? null : _clearNotis,
                child: Text(
                  '전체 삭제',
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.034,
                    color: notiList.isEmpty ? Colors.grey : Color(0xFFDA6464),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: notiList.isEmpty
          ? Center(child: Text('알림이 없습니다.'))
          : AnimatedList(
              key: _listKey,
              initialItemCount: notiList.length,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemBuilder: (context, index, animation) {
                final noti = notiList[index];
                return _buildAnimatedItem(noti, index, animation);
              },
            ),
    );
  }

  Widget _buildAnimatedItem(AppNotification noti, int idx, Animation<double> animation) {
    // [수정] 친구 요청 수락/거절 콜백 로직 전체를 삭제합니다.
    // 이 로직은 이제 '바로 가기'를 통해 이동한 다른 페이지에서 처리되어야 합니다.

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05, vertical: 6),
        child: Slidable(
          key: ValueKey(noti.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(onPressed: (_) => _removeItem(idx), backgroundColor: const Color(0xFFFFFEF9), foregroundColor: const Color(0xFF979797), label: '삭제'),
            ],
          ),
          child: Listener(
            onPointerDown: (_) => setState(() => _pressedIndex = idx),
            onPointerUp: (_) => setState(() => _pressedIndex = null),
            onPointerCancel: (_) => setState(() => _pressedIndex = null),
            child: Stack(
              children: [
                _buildStyledNotiBox(
                  noti, 
                  context, 
                  (date) => Navigator.of(context).pop(date),
                  widget.onNavigateToFriends, // <- 이 부분을 추가!
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: _pressedIndex == idx ? Colors.black.withAlpha(32) : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemovingItem(AppNotification noti, Animation<double> animation) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalWidth = screenWidth * 0.9;
    final actionPaneWidth = totalWidth * 0.25;

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 6,
        ),
        color: const Color(0xFFFFFEF9),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: actionPaneWidth,
              child: Container(
                color: const Color(0xFFFFFEF9),
                alignment: Alignment.center,
                child: const Text(
                  '삭제',
                  style: TextStyle(color: Color(0xFF979797)),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-actionPaneWidth, 0),
              child: SizedBox(
                width: totalWidth,
                // [수정] _buildStyledNotiBox 호출 시 콜백 인수를 전달하지 않습니다.
                child: _buildStyledNotiBox(
                  noti,
                  context,
                  (_) {},
                  // 삭제 애니메이션 중에는 동작할 필요가 없으므로, 비어있는 함수를 전달합니다.
                  ({int tabIndex = 0, bool expandRequests = false}) {}, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}