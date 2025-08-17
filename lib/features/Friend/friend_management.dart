// friend_management.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({Key? key}) : super(key: key);

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> {
  // 🆕 Firebase 인스턴스 추가
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _recommendationsEnabled = true; // 기존 변수 유지
  bool _isLoading = false; // 🆕 로딩 상태

  String? get currentUserId => _auth.currentUser?.uid;

  // 기존 차단 친구 목록 (샘플 데이터 유지)
  final List<Map<String, String?>> _blockedFriends = [
    {'name': '차단1', 'image': null},
    {'name': '차단2', 'image': null},
    {'name': '차단3', 'image': null},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendationSetting(); // 🆕 Firebase에서 설정 불러오기
  }

  /// 🆕 Firebase에서 추천 친구 설정 불러오기 (보안 규칙 준수)
  Future<void> _loadRecommendationSetting() async {
    if (currentUserId == null) return;

    try {
      setState(() => _isLoading = true);

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // 🔑 uid 필드 확인 및 추가 (보안 규칙 준수)
        if (!userData.containsKey('uid') || userData['uid'] != currentUserId) {
          await _firestore.collection('users').doc(currentUserId).update({
            'uid': currentUserId, // 보안 규칙에서 요구하는 uid 필드
            'updateAt': FieldValue.serverTimestamp(),
          });
        }

        // 🆕 recommend 필드가 없으면 기본값으로 생성
        if (!userData.containsKey('recommend')) {
          await _firestore.collection('users').doc(currentUserId).update({
            'uid': currentUserId, // 🔑 보안 규칙 준수
            'recommend': true, // 기본값
            'updateAt': FieldValue.serverTimestamp(),
          });
          setState(() {
            _recommendationsEnabled = true;
          });
        } else {
          setState(() {
            _recommendationsEnabled = userData['recommend'] ?? true;
          });
        }
      } else {
        // 문서가 없으면 생성 (uid 필드 포함)
        await _firestore.collection('users').doc(currentUserId).set({
          'uid': currentUserId, // 🔑 보안 규칙 준수
          'recommend': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updateAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _recommendationsEnabled = true;
        });
      }
    } catch (e) {
      print('추천 설정 불러오기 오류: $e');
      _showSnackBar('설정을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🆕 Firebase에 추천 친구 설정 업데이트 (보안 규칙 준수)
  Future<void> _updateRecommendationSetting(bool enabled) async {
    if (currentUserId == null) return;

    final previousState = _recommendationsEnabled;
    setState(() => _recommendationsEnabled = enabled);

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'uid': currentUserId, // 🔑 보안 규칙 준수
        'recommend': enabled,
        'updateAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar(enabled
          ? '추천 친구 기능이 활성화되었습니다.'
          : '추천 친구 기능이 비활성화되었습니다.');

    } catch (e) {
      // 오류 발생 시 이전 상태로 롤백
      setState(() => _recommendationsEnabled = previousState);
      print('추천 설정 업데이트 오류: $e');
      _showSnackBar('설정 업데이트에 실패했습니다.');
    }
  }

  /// 🆕 차단 해제 함수 (보안 규칙 준수)
  Future<void> _unblockFriend(String friendId, String nickName) async {
    if (currentUserId == null) return;

    try {
      // 내 친구 문서이므로 수정 가능 (uid가 내 것이므로)
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .update({
        'blockStatus': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('${nickName}님의 차단을 해제했습니다.');
    } catch (e) {
      print('차단 해제 오류: $e');
      _showSnackBar('차단 해제 중 오류가 발생했습니다.');
    }
  }

  /// 🆕 SnackBar 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('친구 관리', style: TextStyle(color: Color(0xFF504A4A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF504A4A)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 🔄 Firebase 값을 반환 (settings_screen과 동기화)
            Navigator.pop(context, _recommendationsEnabled);
          },
        ),
      ),
      body: _isLoading // 🆕 로딩 상태 처리
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 추천 친구 활성화 섹션 (기존 UI 유지 + Firebase 연동)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '추천 친구 활성화',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF504A4A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _recommendationsEnabled
                                ? '다른 사용자들에게 추천됩니다'
                                : '다른 사용자들에게 추천되지 않습니다',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9F9C9C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _recommendationsEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF95A797),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCCCCCC),
                      /// 🔄 Firebase 업데이트 함수 연결
                      onChanged: _updateRecommendationSetting,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 차단 목록 (기존 샘플 데이터 유지)
          ExpansionTile(
            title: const Text(
              '차단 목록 (샘플)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF504A4A)),
            ),
            children: _blockedFriends.map((friend) {
              final imagePath = friend['image'];
              final name = friend['name']!;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imagePath != null ? AssetImage(imagePath) : null,
                    child: imagePath == null
                        ? Text(
                      name[0],
                      style: const TextStyle(
                        color: Color(0xFF504A4A),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 16, color: Color(0xFF504A4A))),
                  trailing: TextButton(
                    onPressed: () {
                      setState(() {
                        _blockedFriends.remove(friend);
                      });
                    },
                    child: const Text('해제', style: TextStyle(color: Color(0xFF506497))),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 🆕 Firebase와 연동된 실제 차단 친구 목록 (보안 규칙 준수)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '실제 차단된 친구',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF504A4A),
                  ),
                ),
                const SizedBox(height: 12),

                // Firebase에서 차단된 친구 목록 가져오기 (내 친구 문서만 조회하므로 권한 문제 없음)
                StreamBuilder<QuerySnapshot>(
                  stream: currentUserId != null
                      ? _firestore
                      .collection('users')
                      .doc(currentUserId)
                      .collection('friends')
                      .where('blockStatus', isEqualTo: true)
                      .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('오류: ${snapshot.error}');
                    }

                    final blockedDocs = snapshot.data?.docs ?? [];

                    if (blockedDocs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.block, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                '차단된 친구가 없습니다',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: blockedDocs.map((doc) {
                        final friendData = doc.data() as Map<String, dynamic>;
                        final friendId = friendData['friendId'] ?? '';

                        // 🔄 FutureBuilder 대신 안전한 방식으로 사용자 정보 가져오기
                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('users').doc(friendId).get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            String nickName = '알 수 없음';
                            String profileImage = '';

                            // 🔑 사용자 정보 안전하게 가져오기 (권한 확인)
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              try {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                // uid 필드가 있는 경우만 정보 사용 (읽기 권한 확인)
                                if (userData != null && userData.containsKey('uid')) {
                                  nickName = userData['nickName'] ?? '알 수 없음';
                                  profileImage = userData['profileImage'] ?? '';
                                } else {
                                  nickName = '비공개 사용자';
                                }
                              } catch (e) {
                                print('사용자 정보 읽기 오류: $e');
                                nickName = '정보 없음';
                              }
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: profileImage.isNotEmpty
                                        ? NetworkImage(profileImage)
                                        : null,
                                    child: profileImage.isEmpty
                                        ? Text(
                                      nickName.isNotEmpty ? nickName[0] : '?',
                                      style: const TextStyle(
                                        color: Color(0xFF504A4A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      nickName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF504A4A),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _unblockFriend(friendId, nickName),
                                    child: const Text(
                                      '차단 해제',
                                      style: TextStyle(color: Color(0xFF506497)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}