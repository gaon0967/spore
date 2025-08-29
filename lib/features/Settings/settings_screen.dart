import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_project_1/auth/LoginHome.dart';
// 🔥 Fixed Naver Login SDK import
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'profile_edit.dart'; // 프로필 변경 화면
import '../Friend/friend_management.dart'; // 친구 관리 화면
import 'dart:math' as math;

/// ==============================
/// 클래스명: SettingsScreen
/// 역할: 앱의 설정 화면을 구성 (기존 UI 유지 + Firebase 보안 규칙 적용)
/// ==============================
// 🔥 상태 관리를 위해 StatefulWidget으로 구조를 확정합니다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 🔥 Firebase 인스턴스 추가
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool alarmEnabled = true; // 알림 스위치 현재 상태
  bool _isLoading = true; // 🔥 로딩 상태 (처음엔 true로 설정하여 사용자 문서 확인)

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // 🔥 화면이 시작될 때 사용자 문서가 있는지 확인하고, 없으면 생성합니다.
    // 이것으로 "users/{uid}" 문서에 대한 쓰기 권한 규칙을 만족시킬 수 있습니다.
    _ensureUserDocument();
  }

  // 🔥 사용자 문서가 없으면 생성하여 보안 규칙을 통과하도록 하는 함수
  Future<void> _ensureUserDocument() async {
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final userDocRef = _firestore.collection('users').doc(currentUserId);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // 문서가 없으면, 보안 규칙을 만족시키는 기본 문서를 생성합니다.
        await userDocRef.set({
          'uid': currentUserId, // 🔑 보안 규칙의 핵심인 uid 필드
          'createdAt': FieldValue.serverTimestamp(),
          'updateAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 문서가 있지만 uid 필드가 없는 예전 사용자를 위한 보정 코드
        final data = userDoc.data();
        if (data != null && !data.containsKey('uid')) {
          await userDocRef.update({'uid': currentUserId});
        }
      }
    } catch (e) {
      print('사용자 문서 확인/생성 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 정보를 확인하는 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 프로필 편집 화면으로 이동하는 애니메이션
  Route _createSlideUpRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const ProfileEdit(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // 친구 관리 화면으로 이동하는 애니메이션
  Route _createFriendSlideUpRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const FriendManagementScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEF9),
        title: Text(
          '설정',
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.047,
            color: Color(0xFF504A4A),
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/images/Setting/go.png',
            width: screenWidth * 0.045,
            height: screenWidth * 0.045,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        leadingWidth: screenWidth * 0.1315,
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 변경, 친구 관리 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, _createSlideUpRoute());
                    },
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      backgroundColor: Color(0xFFCDDEE3),
                      foregroundColor: Color(0xFF504A4A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      minimumSize: Size(screenWidth * 0.3945, screenWidth * 0.1526),
                      padding: EdgeInsets.zero,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0475),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('프로필 변경', style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w600, fontSize: screenWidth * 0.038, color: Color(0xFF504A4A))),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: screenWidth * 0.0095),
                              child: Transform.rotate(
                                angle: 270 * math.pi / 180,
                                child: Image.asset('assets/images/Setting/chevron.png', width: screenWidth * 0.038, height: screenWidth * 0.038),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.06175),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, _createFriendSlideUpRoute());
                    },
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      backgroundColor: Color(0xFFCDDEE3),
                      foregroundColor: Color(0xFF504A4A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      minimumSize: Size(screenWidth * 0.3945, screenWidth * 0.1526),
                      padding: EdgeInsets.zero,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0475),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('친구 관리', style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w600, fontSize: screenWidth * 0.038, color: Color(0xFF504A4A))),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: screenWidth * 0.0095),
                              child: Transform.rotate(
                                angle: 270 * math.pi / 180,
                                child: Image.asset('assets/images/Setting/chevron.png', width: screenWidth * 0.038, height: screenWidth * 0.038),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.059375),
            Divider(color: Color(0xFF847E7E), thickness: 1, indent: screenWidth * 0.011875, endIndent: screenWidth * 0.011875),
            SizedBox(height: screenWidth * 0.059375),
            // 알림 설정
            Container(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.038, horizontal: screenWidth * 0.038),
              decoration: BoxDecoration(color: Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(25)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.019),
                    child: Text('알림', style: TextStyle(fontSize: screenWidth * 0.030875, color: Color(0xFF9F9C9C), fontFamily: 'Golos Text', fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(height: screenWidth * 0.038),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.019),
                        child: Text('알림', style: TextStyle(fontSize: screenWidth * 0.038, color: Color(0xFF504A4A), fontFamily: 'Golos Text', fontWeight: FontWeight.w600)),
                      ),
                      GestureDetector(
                        // 탭하는 로직은 그대로 유지합니다.
                        onTap: () {
                          setState(() {
                            alarmEnabled = !alarmEnabled;
                          });
                        },
                        // 자식 위젯을 AnimatedCrossFade로 변경합니다.
                        child: AnimatedCrossFade(
                          // 1. 애니메이션 지속 시간 설정 (0.1초)
                          duration: const Duration(milliseconds: 100),

                          // 2. '꺼짐' 상태일 때 보여줄 위젯 (첫 번째 자식)
                          firstChild: Image.asset(
                            'assets/images/Setting/alarm_off.png', // 꺼짐 이미지 경로
                            width: 52,
                            height: 55,
                            fit: BoxFit.contain, // 이미지가 위젯 크기에 맞게 조절되도록 설정
                          ),

                          // 3. '켜짐' 상태일 때 보여줄 위젯 (두 번째 자식)
                          secondChild: Image.asset(
                            'assets/images/Setting/alarm_on.png', // 켜짐 이미지 경로
                            width: 50,
                            height: 55,
                            fit: BoxFit.contain,
                          ),

                          // 4. 어떤 자식을 보여줄지 상태에 따라 결정
                          crossFadeState: alarmEnabled
                              ? CrossFadeState.showSecond // alarmEnabled가 true이면 두 번째 자식(켜짐)을 보여줌
                              : CrossFadeState.showFirst,  // false이면 첫 번째 자식(꺼짐)을 보여줌
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.059375),
            Divider(color: Color(0xFF847E7E), thickness: 1, indent: screenWidth * 0.011875, endIndent: screenWidth * 0.011875),
            SizedBox(height: screenWidth * 0.059375),
            // 고객 지원, 로그아웃, 버전정보
            Container(
              padding: EdgeInsets.all(screenWidth * 0.038),
              decoration: BoxDecoration(color: Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(25)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenWidth * 0.011875),
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.019),
                    child: Text('고객지원', style: TextStyle(fontSize: screenWidth * 0.030875, color: Color(0xFF9F9C9C), fontFamily: 'Golos Text', fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(height: screenWidth * 0.059375),
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.019),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              backgroundColor: const Color(0xFFFCFCF7),
                              insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.095),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: SizedBox(
                                width: screenWidth * 0.7125,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: screenWidth * .1425),
                                    Text('로그아웃 하시겠습니까?', style: TextStyle(fontSize: screenWidth * 0.035625, color: Color(0xFF716969), fontWeight: FontWeight.w500)),
                                    SizedBox(height: screenWidth * 0.114),
                                    const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                                            onTap: () => Navigator.of(context).pop(),
                                            child: Container(
                                              height: screenWidth * 0.114,
                                              alignment: Alignment.center,
                                              child: Text('아니오', style: TextStyle(fontSize: screenWidth * 0.035625, color: Color(0xFF635E5E), fontWeight: FontWeight.w500)),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1.5, height: screenWidth * 0.114, color: const Color(0xFFE5E5E5)),
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                                            onTap: () async {
                                              // 🔥 Firebase Auth 로그아웃 및 네이버 로그아웃 동시 처리
                                              await _auth.signOut();
                                              await NaverLoginSDK.logout();
                                              if (mounted) {
                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                                      (route) => false,
                                                );
                                              }
                                            },
                                            child: Container(
                                              height: screenWidth * 0.114,
                                              alignment: Alignment.center,
                                              child: Text('네', style: TextStyle(fontSize: screenWidth * 0.035625, color: Color(0xFF2F3BDC), fontWeight: FontWeight.w500)),
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
                      child: Text('로그아웃', style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w500, fontSize: screenWidth * 0.038, color: Color(0xFF506497))),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.0285),
                  const Divider(color: Color(0xFFE4E4E4), thickness: 1),
                  SizedBox(height: screenWidth * 0.0285),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.019),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('버전정보', style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w500, fontSize: screenWidth * 0.038, color: Color(0xFF504A4A))),
                        Text('1.0.0', style: TextStyle(fontFamily: 'Golos Text', fontWeight: FontWeight.w500, fontSize: screenWidth * 0.038, color: Color(0xFF506497))),
                      ],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02375),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 45, 0, 12),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        backgroundColor: const Color(0xFFFCFCF7),
                        insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.095),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: SizedBox(
                          width: screenWidth * 0.7125,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: screenWidth * 0.1425),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0475),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(fontSize: screenWidth * 0.035625, color: Color(0xFF716969), fontWeight: FontWeight.w500, height: 1.5),
                                    children: [
                                      TextSpan(text: '정말 '),
                                      TextSpan(text: '탈퇴 ', style: TextStyle(color: Color(0xFFDA6464), fontWeight: FontWeight.w600)),
                                      TextSpan(text: '하시겠습니까?\n회원 '),
                                      TextSpan(text: '탈퇴 ', style: TextStyle(color: Color(0xFFDA6464), fontWeight: FontWeight.w600)),
                                      TextSpan(text: '시, 모든 정보는 '),
                                      TextSpan(text: '즉시 삭제', style: TextStyle(color: Color(0xFFDA6464), fontWeight: FontWeight.w600)),
                                      TextSpan(text: '되며\n복구할 수 없습니다.'),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.114),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        height: screenWidth * 0.114,
                                        alignment: Alignment.center,
                                        child: Text('아니오', style: TextStyle(fontSize: screenWidth * 0.035625, color: Color(0xFF635E5E), fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                  ),
                                  Container(width: 1.5, height: screenWidth * 0.114, color: const Color(0xFFE5E5E5)),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                                      onTap: () async {
                                        final user = _auth.currentUser;
                                        if (user == null || !mounted) return;

                                        Navigator.of(context).pop(); // 탈퇴 확인 다이얼로그 닫기
                                        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                                        try {
                                          await callDeleteUserAllData(user.uid);
                                          await user.delete();
                                          await NaverLoginSDK.logout();

                                          if (mounted) {
                                            Navigator.pop(context); // 로딩 다이얼로그 닫기
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                                  (route) => false,
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            Navigator.pop(context); // 로딩 다이얼로그 닫기
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('회원 탈퇴 중 오류가 발생했습니다: $e')),
                                            );
                                          }
                                          print('회원 탈퇴 오류: $e');
                                        }
                                      },
                                      child: Container(
                                        height: screenWidth * 0.114,
                                        alignment: Alignment.center,
                                        child: Text('네', style: TextStyle(fontSize: screenWidth * 0.035625, color: Color(0xFF2F3BDC), fontWeight: FontWeight.w500)),
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
                child: Text('회원 탈퇴', style: TextStyle(color: Color(0xFFDA6464), fontSize: screenWidth * 0.038, fontFamily: 'Golos Text', fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 회원 탈퇴 시 모든 사용자 데이터를 삭제하는 Cloud Function 호출
Future<void> callDeleteUserAllData(String uid) async {
  try {
    // asia-northeast3 리전을 명시해주는 것이 좋습니다.
    final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3').httpsCallable('deleteUserAllData');
    print("Cloud Function 'deleteUserAllData' 호출, UID: $uid");
    final response = await callable.call({'uid': uid});
    print('Function 결과: ${response.data}');
  } on FirebaseFunctionsException catch (e) {
    print('Functions 오류: ${e.code} - ${e.message}');
  } catch (e) {
    print('일반 오류: $e');
  }
}