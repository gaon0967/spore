import 'package:flutter/material.dart';
import 'ProfileEdit.dart'; // 프로필 변경 화면

/// ==============================
/// 클래스명: SettingsScreen
/// 역할: 앱의 설정 화면을 구성
/// 사용된 위젯: Scaffold, AppBar, ElevatedButton, Switch, Dialog, GestureDetector
/// 관련 기능: 프로필 변경, 친구 관리, 알림 설정, 고객 지원, 로그아웃, 버전 정보, 회원 탈퇴
/// ==============================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool alarmEnabled = true; // 알림 스위치 현재 상태 (샘플 데이터)

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEF9),
        title: const Text(
          '설정',
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF504A4A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          /// ------------------------------
          /// 함수명: onPressed
          /// 목적: 뒤로가기 버튼 클릭 시 이전 화면으로 이동
          /// 입력: 없음
          /// 반환: 없음
          /// 예외: 없음
          /// ------------------------------
          onPressed: () => Navigator.of(context).pop(),
        ),
        leadingWidth: 56, // 뒤로가기 화살표 아이콘의 위치 조정
        titleSpacing: 0, // 앱바 타이틀의 글자 위치 조정
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 변경, 친구 관리 버튼
            Row(
              children: [
                Expanded(
                  /// ==============================
                  /// 위젯명: ElevatedButton (프로필 변경 버튼)
                  /// 역할: 프로필 변경 화면으로 이동하는 버튼
                  /// 입력: onPressed (클릭 이벤트), style (버튼 스타일), child (버튼 내용)
                  /// 사용 위치: SettingsScreen 내 프로필 변경 기능
                  /// ==============================
                  child: ElevatedButton(
                    /// ------------------------------
                    /// 함수명: onPressed
                    /// 목적: 프로필 변경 버튼 클릭 시 ProfileEdit 화면으로 이동
                    /// 입력: 없음
                    /// 반환: 없음
                    /// 예외: 없음
                    /// ------------------------------
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ProfileEdit(),
                          // 프로필 변경 버튼 클릭 시 ProfileEdit 화면으로 이동
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFCDDEE3),
                      // 버튼 배경색
                      foregroundColor: Color(0xFF504A4A),
                      // 버튼 글자, 아이콘 색상
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: const Size(168, 66),
                      // 버튼의 최소 가로, 세로 크기
                      padding: EdgeInsets.zero,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '프로필 변경',
                              style: TextStyle(
                                fontFamily: 'Golos Text',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color(0xFF504A4A),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/images/Setting/chevron.png',
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  /// ==============================
                  /// 위젯명: ElevatedButton (친구 관리 버튼)
                  /// 역할: 친구 관리 기능으로 이동하는 버튼 (현재 기능 미구현)
                  /// 입력: onPressed (클릭 이벤트), style (버튼 스타일), child (버튼 내용)
                  /// 사용 위치: SettingsScreen 내 친구 관리 기능
                  /// ==============================
                  child: ElevatedButton(
                    /// ------------------------------
                    /// 함수명: onPressed
                    /// 목적: 친구 관리 버튼 클릭 이벤트 (현재는 아무 동작 없음)
                    /// 입력: 없음
                    /// 반환: 없음
                    /// 예외: 없음
                    /// ------------------------------
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFCDDEE3),
                      // 버튼 배경색
                      foregroundColor: Color(0xFF504A4A),
                      // 버튼 글자, 아이콘 색상
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: const Size(168, 66),
                      // 버튼의 최소 가로, 세로 크기
                      padding: EdgeInsets.zero,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '친구 관리',
                              style: TextStyle(
                                fontFamily: 'Golos Text',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color(0xFF504A4A),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/images/Setting/chevron.png',
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            const Divider(
              color: Color(0xFF847E7E), // 구분선 색깔
              thickness: 1, // 구분선 굵기
              indent: 5, // 구분선 왼쪽 여백
              endIndent: 5, // 구분선 오른쪽 여백
            ),

            const SizedBox(height: 25),
            // 알림 설정
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Text(
                      '알림', // 작은 "알림"
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9F9C9C),
                        fontFamily: 'Golos Text',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 큰 알림 텍스트랑 스위치 Row로 묶음
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: const Text(
                          '알림', // 큰 "알림"
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF504A4A),
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: alarmEnabled,
                        activeColor: Colors.white,
                        // 토글 버튼 켜짐 색
                        activeTrackColor: Color(0xFF95A797),
                        // 트랙 켜짐 색
                        inactiveThumbColor: Colors.white,
                        // 토글 버튼 꺼짐 색
                        inactiveTrackColor: Color(0xFFCCCCCC),
                        // 트랙 꺼짐 색
                        /// ------------------------------
                        /// 함수명: onChanged
                        /// 목적: 알림 스위치 상태 변경 시 호출되는 콜백 함수
                        /// 입력: bool value - 스위치의 새로운 상태 (true: 켜짐, false: 꺼짐)
                        /// 반환: 없음
                        /// 예외: 없음
                        /// ------------------------------
                        onChanged: (value) {
                          // 알림 스위치 동작 추가
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Divider(
              color: Color(0xFF847E7E), // 구분선 색깔
              thickness: 1, // 구분선 굵기
              indent: 5, // 구분선 왼쪽 여백
              endIndent: 5, // 구분선 오른쪽 여백
            ),

            const SizedBox(height: 25),

            // 고객 지원, 로그아웃, 버전정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  // 고객지원 제목
                  const Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '고객지원',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9F9C9C),
                        fontFamily: 'Golos Text',
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      /// ------------------------------
                      /// 함수명: onTap
                      /// 목적: 로그아웃 텍스트 클릭 시 로그아웃 확인 다이얼로그 표시
                      /// 입력: 없음
                      /// 반환: 없음
                      /// 예외: 없음
                      /// ------------------------------
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            /// ==============================
                            /// 위젯명: Dialog (로그아웃 확인 다이얼로그)
                            /// 역할: 사용자에게 로그아웃 여부를 확인하는 팝업
                            /// 입력: child (다이얼로그 내용)
                            /// 사용 위치: SettingsScreen 내 로그아웃 기능
                            /// ==============================
                            return Dialog(
                              backgroundColor: const Color(0xFFFCFCF7), // 다이얼로그 배경색
                              insetPadding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SizedBox(
                                width: 300,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 60),
                                    const Center(
                                      child: Text(
                                        '로그아웃 하시겠습니까?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Color(0xFF716969),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFE5E5E5),
                                    ),
                                    Row(
                                      children: [
                                        // 아니오 버튼
                                        Expanded(
                                          child: InkWell(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    16,
                                                  ),
                                                ),
                                            /// ------------------------------
                                            /// 함수명: onTap
                                            /// 목적: 로그아웃 확인 다이얼로그에서 '아니오' 클릭 시 다이얼로그 닫기
                                            /// 입력: 없음
                                            /// 반환: 없음
                                            /// 예외: 없음
                                            /// ------------------------------
                                            onTap:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: Container(
                                              height: 48,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                '아니오',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF635E5E),
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 세로 구분선
                                        Container(
                                          width: 1.5,
                                          height: 48,
                                          color: const Color(0xFFE5E5E5),
                                        ),
                                        // 네 버튼
                                        Expanded(
                                          child: InkWell(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomRight: Radius.circular(
                                                    16,
                                                  ),
                                                ),
                                            /// ------------------------------
                                            /// 함수명: onTap
                                            /// 목적: 로그아웃 확인 다이얼로그에서 '네' 클릭 시 다이얼로그 닫고 로그아웃 처리
                                            /// 입력: 없음
                                            /// 반환: 없음
                                            /// 예외: 없음
                                            /// ------------------------------
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              // 로그아웃 처리 함수 호출
                                            },
                                            child: Container(
                                              height: 48,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                '네',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF2F3BDC),
                                                  // 파랑
                                                  fontWeight: FontWeight.w500,
                                                ),
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
                      },

                      child: const Text(
                        '로그아웃',
                        style: TextStyle(
                          fontFamily: 'Golos Text',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF506497),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Divider(color: Color(0xFFE4E4E4), thickness: 1),

                  const SizedBox(height: 12),

                  // 버전 정보 텍스트
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '버전정보',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF504A4A),
                          ),
                        ),
                        Text(
                          '1.0.0', // 현재 앱 버전 정보
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF506497),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // 회원 탈퇴(하단 빨간색 텍스트)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 45, 0, 12),
              // 왼쪽 24, 위아래 12
              child: GestureDetector(
                /// ------------------------------
                /// 함수명: onTap
                /// 목적: 회원 탈퇴 텍스트 클릭 시 회원 탈퇴 확인 다이얼로그 표시
                /// 입력: 없음
                /// 반환: 없음
                /// 예외: 없음
                /// ------------------------------
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      /// ==============================
                      /// 위젯명: Dialog (회원 탈퇴 확인 다이얼로그)
                      /// 역할: 사용자에게 회원 탈퇴 여부와 주의사항을 확인하는 팝업
                      /// 입력: child (다이얼로그 내용)
                      /// 사용 위치: SettingsScreen 내 회원 탈퇴 기능
                      /// ==============================
                      return Dialog(
                        backgroundColor: const Color(0xFFFCFCF7),
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 40,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          width: 300,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 60),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF716969),
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(text: '정말 '),
                                      TextSpan(
                                        text: '탈퇴 ',
                                        style: TextStyle(
                                          color: Color(0xFFDA6464), // 빨간색 강조
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: '하시겠습니까?\n회원 '),
                                      TextSpan(
                                        text: '탈퇴 ',
                                        style: TextStyle(
                                          color: Color(0xFFDA6464),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: '시, 모든 정보는 '),
                                      TextSpan(
                                        text: '즉시 삭제',
                                        style: TextStyle(
                                          color: Color(0xFFDA6464),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: '되며\n복구할 수 없습니다.'),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 48),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFE5E5E5),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                      ),
                                      /// ------------------------------
                                      /// 함수명: onTap
                                      /// 목적: 회원 탈퇴 확인 다이얼로그에서 '아니오' 클릭 시 다이얼로그 닫기
                                      /// 입력: 없음
                                      /// 반환: 없음
                                      /// 예외: 없음
                                      /// ------------------------------
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: const Text(
                                          '아니오',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF635E5E),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1.5,
                                    height: 48,
                                    color: const Color(0xFFE5E5E5),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(16),
                                      ),
                                      /// ------------------------------
                                      /// 함수명: onTap
                                      /// 목적: 회원 탈퇴 확인 다이얼로그에서 '네' 클릭 시 다이얼로그 닫고 회원 탈퇴 처리
                                      /// 입력: 없음
                                      /// 반환: 없음
                                      /// 예외: 없음
                                      /// ------------------------------
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        // TODO: 회원탈퇴 동작 처리 필요
                                      },
                                      child: Container(
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: const Text(
                                          '네',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF2F3BDC),
                                            fontWeight: FontWeight.w500,
                                          ),
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
                },
                child: const Text(
                  '회원 탈퇴',
                  style: TextStyle(
                    color: Color(0xFFDA6464),
                    fontSize: 16,
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
