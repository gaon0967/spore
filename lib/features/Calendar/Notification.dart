import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

Widget _buildStyledNotiBox(AppNotification noti) {
  Color bgColor = Color(0xFFFFFEF9);
  String? label;
  String? buttonText;
  String? badgeText;
  String? rightText;

Widget iconWidget = SizedBox.shrink();
  // 타입별 스타일 커스터마이즈
  if (noti.title.contains("D-Day")) {
    label = '일정';
    iconWidget = Image.asset('assets/images/Notification/calendar.png', width: 25, height: 27);
    rightText = '바로 가기';
  } else if (noti.title.contains('친구')) {
    label = '친구';
    iconWidget = Image.asset('assets/images/Notification/friend.png', width: 40, height: 40);

    if(noti.content.contains('메세지를 보냈습니다')) {
      rightText = '메세지 보내기';
    } else if (noti.content.contains('친구신청을 보냈습니다.')) {
      /*
      // 수락 거절 버튼
      showRequestButtons = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _TextButton('수락', Icons.radio_button_unchecked, () {
            // 수락
          }),
          SizedBox(width: 10),
          _TextButton('거절', Icons.close, () {
            // 거절
          }),
        ],
      );*/
    } else {
      rightText = '바로 가기';
    }
  } else if (noti.title.contains('타이틀')) {
    label = '타이틀';
    iconWidget = Image.asset('assets/images/Notification/title.png', width: 27, height: 27);
    badgeText = '언제든 놀자!';
    rightText = '바로 가기';
  }

  return Container(
    width: 363,
    height: 87,
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 아이콘
        Container(
          width: 40,
          height: 40,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(child: iconWidget),
        ),
        // 중앙부(텍스트 등)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              if (label != null)
              Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Color(0xFFA5A5A5),
                    ),
                  ),
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    noti.content,
                    style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF645E5E),
                    ),
                  ),
                  if (badgeText != null)
                    Container(
                      margin: EdgeInsets.only(left: 10),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(0xFFF4ECD2),
                        border: Border.all(color: Color(0xFF6A6A6A)),
                        borderRadius: BorderRadius.circular(47),
                      ),
                      child: Text(
                        badgeText ?? '',
                        style: TextStyle(
                          fontFamily: 'Golos Text',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Color(0xFF413B3B),
                        ),
                      ),
                    ),
                     // 우측 바로가기 버튼
        if (rightText != null) 
        Container(
          alignment: Alignment.topRight,
            child: GestureDetector(
            onTap: () {/* 원하는 동작 */},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rightText,
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF635E5E),
                  ),
                ),
                SizedBox(width: 8),
                Image.asset(
                  'assets/images/Setting/chevron.png',
                  width: 7,
                  height: 12,
                  fit: BoxFit.contain,
                )
          ],
        ),
            ),
    ),     ],
              ),
            ],
            ),
            ],
            
          ),
        ),

       
      ],
    ),
  );
}


// 알림 데이터 클래스 정의
class AppNotification {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;

  AppNotification({required this.id, required this.title, required this.content, required this.timestamp});
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> notiList = [];

  @override
  void initState() {
    super.initState();

    // noti 데이터 샘플(API 또는 로컬 DB에서 가져와도 동일한 구조)
    notiList = [
      AppNotification(
        id: "noti_001",
        title: "D-Day 알림",
        content: "오늘은 리눅스 과제 제출이 있는 날입니다.",
        timestamp: DateTime.parse("2025-06-09T10:00:00Z").toLocal(),
      ),
      AppNotification(
        id: "noti_002",
        title: "타이틀 알림",
        content: "타이틀을 획득했습니다!",
        timestamp: DateTime.parse("2025-06-09T10:01:00Z").toLocal(),
      ),
      AppNotification(
        id: "noti_003", 
        title: "친구 알림", 
        content: "김세모 님이 메세지를 보냈습니다.", 
        timestamp: DateTime.parse("2025-06-10T10:02:00Z").toLocal(),
        ),
        AppNotification(
        id: "noti_004", 
        title: "친구 알림", 
        content: "김세모 님과 친구가 되었습니다.", 
        timestamp: DateTime.parse("2025-06-10T10:03:00Z").toLocal(),
        ),
        AppNotification(
        id: "noti_005", 
        title: "친구 알림", 
        content: "김네모 님이 친구신청을 보냈습니다.", 
        timestamp: DateTime.parse("2025-06-10T10:04:00Z").toLocal(),
        ),
    ];
    // 알림 순서를 최신순으로
    notiList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void _clearNotis() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            width: 298,
            height: 182,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Color(0xFFFFFFF9),
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
                          fontSize: 16,
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
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '아니오',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF635E5E),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: Color(0xFFE5E5E5),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            notiList.clear();
                          });
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFFFFFF9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '네',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '알림',
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF504A4A),
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16, bottom: 10),
              child: GestureDetector(
                onTap: _clearNotis,
                child: Text(
                  '전체 삭제',
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFFDA6464),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: notiList.isEmpty
    ? Center(child: Text('알림이 없습니다.',
    style: TextStyle(
      fontFamily: 'Golos Text',
      fontSize: 15,
      color: Color(0xFF504A4A)
    ),))
    // 밀어서 삭제
    : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: notiList.length,
        itemBuilder: (context, idx) {
          final noti = notiList[idx];
          return Slidable(
            key: ValueKey(noti.id),
            endActionPane: ActionPane(
              motion: DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    setState(() {
                      notiList.removeAt(idx);
                    });
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: Color(0xFF979797),
                  label: '삭제',
                ),
              ],
              ),
              child: _buildStyledNotiBox(noti),
          );
        }
      ),
    );
  }

  // 푸시 알림 박스 위젯
  Widget _buildPushNotiBox(AppNotification noti) {
    return Container(
      width: 363,
      padding: EdgeInsets.all(14),
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘 or 이름에 따라 아이콘 선택하면 좋아짐
          Padding(
            padding: EdgeInsets.only(top: 4, left: 2, right: 9),
            child: Icon(Icons.notifications, color: Color(0xFFAFAFAF), size: 32),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noti.title,
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFA1A1A1),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  noti.content,
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF504A4A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _humanReadableTime(noti.timestamp),
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: Color(0xFFB9B2B2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _humanReadableTime(DateTime time) {
    // 'yyyy.MM.dd 오전/오후 시:분' 형태로 표시
    final hour = time.hour;
    final amPm = hour < 12 ? '오전' : '오후';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${time.year}.${_twoDigits(time.month)}.${_twoDigits(time.day)} $amPm ${_twoDigits(hour12)}:${_twoDigits(time.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}

