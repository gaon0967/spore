import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';

// --- 데이터 모델 클래스 (파일 상단에 위치) ---
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
  final String? eventTitle;
  final DateTime? dueDate;

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.eventTitle,
    this.dueDate,
  });
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

List<TextSpan> _buildStyledTextSpans(AppNotification noti, String userName) {
  if (noti.title.contains("D-Day") && noti.eventTitle != null) {
    if (noti.content.contains("오늘")) {
      return [
        TextSpan(text: "오늘은 ", style: baseStyle),
        TextSpan(text: noti.eventTitle!, style: boldStyle),
        TextSpan(text: " 이(가) 있는 날입니다.", style: baseStyle),
      ];
    } else {
      return [
        TextSpan(text: noti.eventTitle!, style: boldStyle),
        TextSpan(text: " ${noti.content}", style: baseStyle),
      ];
    }
  } else if (noti.title.contains("친구") && userName.isNotEmpty) {
    final splitContent = noti.content.split(userName);
    return [
      TextSpan(text: splitContent[0], style: baseStyle),
      TextSpan(text: userName, style: boldStyle),
      if (splitContent.length > 1)
        TextSpan(text: splitContent[1], style: baseStyle),
    ];
  } else {
    return [TextSpan(text: noti.content, style: baseStyle)];
  }
}

Widget _buildStyledNotiBox(
  AppNotification noti,
  BuildContext context,
  Function(DateTime) onGoToCalendar,
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
  } else if (noti.title.contains('친구')) {
    label = '친구';
    iconWidget = Image.asset(
      'assets/images/Notification/friend.png',
      width: screenWidth * 0.09,
      height: screenWidth * 0.09,
    );
    if (noti.content.contains('메세지를 보냈습니다')) {
      rightText = '메세지 보내기';
    } else {
      rightText = '바로 가기';
    }
  } else if (noti.title.contains('타이틀')) {
    label = '타이틀';
    iconWidget = Image.asset(
      'assets/images/Notification/title.png',
      width: screenWidth * 0.06,
      height: screenWidth * 0.06,
    );
    badgeText = '언제든 놀자!';
    rightText = '바로 가기';
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
                          children: _buildStyledTextSpans(noti, userName),
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
        if (rightText != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              // 2. 전달받은 onGoToCalendar 함수를 여기서 호출합니다.
              onTap: () {
                if (noti.title.contains("D-Day") && noti.dueDate != null) {
                  onGoToCalendar(noti.dueDate!);
                }
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
          ),
      ],
    ),
  );
}
// ---------------------------------

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> notiList = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int? _pressedIndex;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_currentUser == null) return;

    final (List<String> dismissedIds, List<ScheduledEvent> scheduledEvents) =
        await (_fetchDismissedNotificationIds(), _fetchScheduledEvents()).wait;

    await _cleanupDismissedIds(dismissedIds, scheduledEvents);

    List<AppNotification> allPotentialNotifications = [];

    //  D-Day 알림 추가 (아직 도착 안 한 알림 포함)
    allPotentialNotifications.addAll(
      _generateDDayNotifications(scheduledEvents, dismissedIds),
    );

    // 친구/타이틀 알림 추가 (아직 도착 안 한 알림 포함)
    final otherNotifications = [
      AppNotification(
        id: "noti_002",
        title: "타이틀 알림",
        content: "타이틀을 획득했습니다!",
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: "noti_003",
        title: "친구 알림",
        content: "김세모 님과 친구가 되었습니다.",
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AppNotification(
        id: "noti_004",
        title: "친구 알림",
        content: "김세모 님이 메세지를 보냈습니다.",
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      ),
      AppNotification(
        id: "noti_005",
        title: "친구 알림",
        content: "김네모 님이 친구신청을 보냈습니다.",
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    allPotentialNotifications.addAll(otherNotifications);

    // 2. 현재 시간을 기준으로 최종적으로 화면에 보여줄 알림만 필터링합니다.
    final now = DateTime.now();
    final visibleNotifications =
        allPotentialNotifications.where((noti) {
          // 조건 1: 알림의 '도착 예정 시간(timestamp)'이 '현재 시간'보다 이전이어야 함 (즉, 이미 도착했어야 함)
          final hasArrived = noti.timestamp.isBefore(now);
          // 조건 2: 사용자가 '삭제'한 기록이 없어야 함
          final notDismissed = !dismissedIds.contains(noti.id);

          return hasArrived && notDismissed;
        }).toList();

    // 3. 화면에 보여줄 알림들을 최신순으로 정렬합니다.
    visibleNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        notiList = visibleNotifications;
      });
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

      // 조건 1: 해당 이벤트가 'plans' DB에서 완전히 삭제된 경우
      if (correspondingEvent == null) {
        idsToRemove.add(dismissedId);
        continue; // 다음 기록 확인
      }

      // 조건 2: 해당 이벤트가 'isDone: true' (완료) 상태인 경우
      if (correspondingEvent.isDone) {
        idsToRemove.add(dismissedId);
      }
    }

    // 지워야 할 기록이 하나라도 있으면 Firestore에서 제거
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
              // isDone 필드를 읽어오고, 만약 필드가 없으면 기본값 false를 사용합니다.
              final isDone = eventData['isDone'] as bool? ?? false;

              if (title != null) {
                events.add(
                  ScheduledEvent(
                    eventId: eventId,
                    title: title,
                    dueDate: eventDate,
                    isDone: isDone, // 읽어온 isDone 상태를 저장합니다.
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
    final List<AppNotification> todayNotifications = [];
    final List<AppNotification> tomorrowNotifications = [];
    final List<AppNotification> sevenDaysLaterNotifications = [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final event in events) {
      final notificationId = 'dday_${event.eventId}';
      if (dismissedIds.contains(notificationId)) {
        continue;
      }

      final eventDate = DateTime(
        event.dueDate.year,
        event.dueDate.month,
        event.dueDate.day,
      );
      String? contentTemplate;
      DateTime? notificationTimestamp; // 알림 시간을 저장할 변수

      // 1. 조건에 따라 알림 내용과 시간을 각각 설정합니다.
      if (eventDate.isAtSameMomentAs(today)) {
        contentTemplate = "오늘은 %이(가) 있는 날입니다.";
        notificationTimestamp = DateTime(
          today.year,
          today.month,
          today.day,
          7,
          0,
        ); // 오늘 알림: 오전 7시
      } else if (eventDate.isAtSameMomentAs(
        today.add(const Duration(days: 1)),
      )) {
        contentTemplate = "까지 1일 남았습니다.";
        notificationTimestamp = DateTime(
          today.year,
          today.month,
          today.day,
          19,
          0,
        ); // 내일 알림: 오후 7시
      } else if (eventDate.isAtSameMomentAs(
        today.add(const Duration(days: 7)),
      )) {
        contentTemplate = "까지 7일 남았습니다.";
        notificationTimestamp = DateTime(
          today.year,
          today.month,
          today.day,
          21,
          0,
        ); // 7일 뒤 알림: 오후 9시
      }

      // 2. 내용과 시간이 설정된 경우에만 알림 객체를 생성합니다.
      if (contentTemplate != null && notificationTimestamp != null) {
        final notification = AppNotification(
          id: notificationId,
          title: 'D-Day 알림',
          content: contentTemplate,
          eventTitle: event.title,
          dueDate: event.dueDate,
          timestamp: notificationTimestamp, // 위에서 설정한 시간 적용
        );

        // 3. 날짜에 따라 맞는 리스트에 추가합니다.
        if (eventDate.isAtSameMomentAs(today)) {
          todayNotifications.add(notification);
        } else if (eventDate.isAtSameMomentAs(
          today.add(const Duration(days: 1)),
        )) {
          tomorrowNotifications.add(notification);
        } else {
          sevenDaysLaterNotifications.add(notification);
        }
      }
    }

    return [
      ...todayNotifications,
      ...tomorrowNotifications,
      ...sevenDaysLaterNotifications,
    ];
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
                          final dDayIdsToDismiss =
                              notiList
                                  .where((noti) => noti.id.startsWith('dday_'))
                                  .map((noti) => noti.id)
                                  .toList();

                          if (dDayIdsToDismiss.isNotEmpty) {
                            await _dismissAllNotificationsInFirestore(
                              dDayIdsToDismiss,
                            );
                          }

                          if (mounted) Navigator.of(context).pop();

                          setState(() {
                            notiList.clear();
                          });
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
    _dismissNotificationInFirestore(removedItem.id);
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
      body:
          notiList.isEmpty
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

  Widget _buildAnimatedItem(
    AppNotification noti,
    int idx,
    Animation<double> animation,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 6,
        ),
        child: Slidable(
          key: ValueKey(noti.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => _removeItem(idx),
                backgroundColor: const Color(0xFFFFFEF9),
                foregroundColor: const Color(0xFF979797),
                label: '삭제',
              ),
            ],
          ),
          // Slidable의 자식 부분을 수정하여 터치 효과를 추가합니다.
         child: Listener(
            onPointerDown: (_) => setState(() => _pressedIndex = idx),
            onPointerUp: (_) => setState(() => _pressedIndex = null),
            onPointerCancel: (_) => setState(() => _pressedIndex = null),
            child: Stack(
              children: [
                // 1. 배경 (실제 버튼이 있는 위젯)
                _buildStyledNotiBox(noti, context, (date) {
                  Navigator.of(context).pop(date);
                }),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true, 
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color:
                            _pressedIndex == idx
                                ? Colors.black.withAlpha(32)
                                : Colors.transparent,
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
                // ▼▼▼ 이 부분에 세 번째 인수를 추가했습니다 ▼▼▼
                child: _buildStyledNotiBox(noti, context, (_) {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
