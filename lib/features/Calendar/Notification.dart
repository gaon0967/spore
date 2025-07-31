import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

/*
class NotificationPage extends StatelfulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {


  bool hasNotification = true; // true면 박스 보이기, false면 글자 보이기
  void ClearNotifications () {
    setState(() {
      hasNotification = false; // 전체 삭제 누르면 박스를 없애고 글자 보이기
  });
  }
  */

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
          )
        ],
        
      ),
      /*
      body: const Center(
        child: Text(
          '알림 목록이 여기에 표시됩니다.',
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF504A4A),
          ),
        ),
      ),
      */
      body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // 알림 박스(친구3)
            Container(
              width: 363,
              height: 83,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Color(0xFFF4F4F4),borderRadius: 
                BorderRadius.circular(25),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽 이미지
                  Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Image.asset(
                      'assets/images/Notification/friend.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 6),
                    
                    // 텍스트
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                          '친구',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xFFA1A1A1),
                            ),
                           ),
                            SizedBox(height: 1),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Golos Text',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF645E5E),
                                  ),
                                  children: [
                              TextSpan(
                                text: '김네모 ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '님이 친구신청을 보냈습니다.'),
                            ],
                                  ),
                                 ),

                                 // 바로 가기 버튼
                                 Align(
                                  alignment: Alignment.bottomRight,
                                 child: Row(
                                  mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '바로 가기',
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
                                     ),
                                  ],
                                  ),
                                 ),
                               ],
                            ),
                           ), 
                            ],
                          ),
                        ),
            // 알림 박스(친구2)
            Container(
              width: 363,
              height: 83,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Color(0xFFF4F4F4),borderRadius: 
                BorderRadius.circular(25),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽 이미지
                  Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Image.asset(
                      'assets/images/Notification/friend.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 6),
                    
                    // 텍스트
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                          '친구',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xFFA1A1A1),
                            ),
                           ),
                            SizedBox(height: 1),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Golos Text',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF645E5E),
                                  ),
                                  children: [
                              TextSpan(
                                text: '김세모 ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '님이 친구신청을 보냈습니다.'),
                            ],
                                  ),
                                 ),

                                 // 바로 가기 버튼
                                 Align(
                                  alignment: Alignment.bottomRight,
                                 child: Row(
                                  mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '바로 가기',
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
                                     ),
                                  ],
                                  ),
                                 ),
                               ],
                            ),
                           ), 
                            ],
                          ),
                        ),
            // 알림 박스(친구1)
            Container(
              width: 363,
              height: 83,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Color(0xFFF4F4F4),borderRadius: 
                BorderRadius.circular(25),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽 이미지
                  Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Image.asset(
                      'assets/images/Notification/friend.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 6),
                    
                    // 텍스트
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                          '친구',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xFFA1A1A1),
                            ),
                           ),
                            SizedBox(height: 1),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Golos Text',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF645E5E),
                                  ),
                                  children: [
                              TextSpan(
                                text: '김세모 ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '님이 친구신청을 보냈습니다.'),
                            ],
                                  ),
                                 ),

                                 // 바로 가기 버튼
                                 Align(
                                  alignment: Alignment.bottomRight,
                                 child: Row(
                                  mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '바로 가기',
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
                                     ),
                                  ],
                                  ),
                                 ),
                               ],
                            ),
                           ), 
                            ],
                          ),
                        ),
            
            // 알림 박스(타이틀)
            Container(
              width: 363,
              height: 83,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽 이미지
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Image.asset(
                      'assets/images/Notification/title.png',
                      width: 27,
                      height: 27,
                      fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 13),
                    
                    // 텍스트
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                          '타이틀',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xFFA1A1A1),
                            ),
                           ),

                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                '타이틀을 획득했습니다!',
                                style: TextStyle(
                                  fontFamily: 'Golos Text',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF645E5E),
                                  ),
                                  softWrap: true,
                                  ),                  

                                 // 타이틀 도형 
                                 Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF4ECD2),
                                    borderRadius: BorderRadius.circular(47),
                                    border: Border.all(
                                      color: Color(0xFF6A6A6A),
                                      width: 1,
                                      ),
                                  ),
                                  child: Text(
                                    '언제든 놀자!',
                                    style: TextStyle(
                                      fontFamily: 'Golos Text',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Color(0xFF413B3B),
                                    ),
                                  ),
                                 ),
                               ],
                            ),
                           
                           // 바로 가기 버튼
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                 children: [
                                Text(
                                  '바로 가기',
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
                                     ),
                                  ],
                                  ),
                              ),
                                 ],
                          ),
                        ),
                ],
            ),
            ),
                
                        // 알림 박스(일정)
            Container(
              width: 363,
              height: 83,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // 세로 가운데 정렬
                children: [
            // 왼쪽 이미지
            Padding(padding: EdgeInsets.only(left:9),
            child: Image.asset(
              'assets/images/Notification/calendar.png',
              width: 25,
              height: 27,
              fit: BoxFit.contain,
            ),
            ),
            
            SizedBox(width: 13),  // 왼쪽 사진과 글자 사이 간격

            Expanded( // 일정 이름만 진하게 하기 위함
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '일정',
                    style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Color(0xFFA1A1A1),
                      ),
                      ),
                      SizedBox(height: 1),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Golos Text',
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Color(0xFF645E5E),
                            ),
                            children: [
                              TextSpan(text: '오늘은 '),
                              TextSpan(
                                text: '리눅스 과제 제출',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '이 있는 날입니다.'),
                            ],
                          ),
                          ),
                        
                        // 바로 가기 버튼
                          Align(
                                  alignment: Alignment.bottomRight,
                                 child: Row(
                                  mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '바로 가기',
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
                                     ),
                                  ],
                                  ),
                                 ),
                                 ],
                 
                ),
             ),
            ],
          ), 
            ),
          ],
        ),
            
      
    );
  }
}