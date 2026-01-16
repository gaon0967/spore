import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({Key? key}) : super(key: key);

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _recommendationsEnabled = true;
  bool _isLoading = true;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDocRef = _firestore.collection('users').doc(currentUserId);
      final userDoc = await userDocRef.get();

      bool currentSetting = true;
      if (userDoc.exists && userDoc.data()!.containsKey('recommend')) {
        currentSetting = userDoc.data()!['recommend'];
      } else {
        // 필드가 없거나 문서가 없으면 기본값으로 설정
        await userDocRef.set({'recommend': true}, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() {
          _recommendationsEnabled = currentSetting;
        });
      }
    } catch (e) {
      print('설정 불러오기 오류: $e');
      _showSnackBar('설정을 불러오는 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateRecommendationSetting(bool enabled) async {
    if (currentUserId == null) return;

    setState(() => _recommendationsEnabled = enabled);

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'recommend': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar(enabled ? '추천 친구 기능이 활성화되었습니다.' : '추천 친구 기능이 비활성화되었습니다.');
    } catch (e) {
      setState(() => _recommendationsEnabled = !enabled);
      print('추천 설정 업데이트 오류: $e');
      _showSnackBar('설정 업데이트에 실패했습니다.');
    }
  }

  Future<void> _unblockFriend(String friendId, String nickName) async {
    if (currentUserId == null) return;

    try {
      // friends 서브컬렉션에서 blockStatus 업데이트
      final friendDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .where('friendId', isEqualTo: friendId)
              .limit(1)
              .get();

      if (friendDoc.docs.isNotEmpty) {
        await friendDoc.docs.first.reference.update({
          'blockStatus': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _showSnackBar('${nickName}님의 차단을 해제했습니다.');
    } catch (e) {
      print('차단 해제 오류: $e');
      _showSnackBar('차단 해제 중 오류가 발생했습니다.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      // CSS에 명시된 배경색 적용
      backgroundColor: const Color(0xFFFFFEF9),
      appBar: AppBar(
        // 1. 뒤로가기 화살표 이미지로 교체
        titleSpacing: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/Setting/go.png', // 화살표 이미지 경로
            width: screenWidth * 0.045,
            height: screenWidth * 0.045,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // 2. 친구관리 글꼴 및 스타일 수정
        title: Text(
          '친구 관리',
          style: TextStyle(
            fontSize: screenWidth * 0.047,
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w700,
            color: Color(0xFF504A4A),
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFFFFEF9),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                // 전체적인 좌우 패딩 적용
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                children: [
                  _buildRecommendationTile(),
                  const SizedBox(height: 2),
                  const Divider(color: Color(0xFFE4E4E4), thickness: 1),
                  const SizedBox(height: 2),
                  _buildBlockedFriendsSection(),
                ],
              ),
    );
  }

  // '추천 친구 활성화' 섹션 위젯
  Widget _buildRecommendationTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              '추천 친구 활성화',
              style: TextStyle(
                fontFamily: 'Golos Text',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Color(0xFF504A4A),
              ),
            ),
          ),
          // --- 이미지 스위치 부분 ---
          GestureDetector(
            onTap: () => _updateRecommendationSetting(!_recommendationsEnabled),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Image.asset(
                _recommendationsEnabled
                    ? 'assets/images/Setting/alarm_on.png' // ON 이미지 경로
                    : 'assets/images/Setting/alarm_off.png', // OFF 이미지 경로
                key: ValueKey<bool>(_recommendationsEnabled),
                width: 52, // 스위치 크기에 맞게 조절하세요
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // '차단 목록' 섹션 위젯 (ExpansionTile 사용)
  Widget _buildBlockedFriendsSection() {
    return Theme(
      // ExpansionTile의 기본 Divider 제거
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // 기본 패딩 제거
        tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
        // 항상 펼쳐진 상태로 시작
        initiallyExpanded: true,
        title: const Text(
          '차단 목록',
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Color(0xFF504A4A),
          ),
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream:
                currentUserId != null
                    ? _firestore
                        .collection('users')
                        .doc(currentUserId)
                        .collection('friends')
                        .where('blockStatus', isEqualTo: true)
                        .snapshots()
                    : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('오류가 발생했습니다.'));
              }
              final blockedDocs = snapshot.data?.docs ?? [];
              if (blockedDocs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      '차단된 친구가 없습니다',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ),
                );
              }
              // ListView.separated로 각 아이템 사이에 공간을 줌
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: blockedDocs.length,
                itemBuilder: (context, index) {
                  return _buildBlockedFriendTile(blockedDocs[index]);
                },
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
              );
            },
          ),
        ],
      ),
    );
  }

  String getImagePathByCharacterId(int id) {
  switch (id) {
    case 1: return 'assets/images/Setting/chac4.png';
    case 2: return 'assets/images/Setting/chac3.png';
    case 3: return 'assets/images/Setting/chac2.png';
    case 4: return 'assets/images/Setting/chac5.png';
    case 5: return 'assets/images/Setting/chac7.png';
    case 6: return 'assets/images/Setting/chac8.png';
    case 7: return 'assets/images/Setting/chac1.png';
    case 8: return 'assets/images/Setting/chac6.png';
    default: return 'assets/images/profile.png'; // 기본 이미지
  }
}

  // 차단된 친구 한 명을 표시하는 타일 위젯
  // 1. 차단된 친구 한 명을 표시하는 타일 위젯 수정
  Widget _buildBlockedFriendTile(QueryDocumentSnapshot doc) {
    final friendData = doc.data() as Map<String, dynamic>;
    final friendId = friendData['friendId'] as String? ?? '';

    if (friendId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(friendId).get(),
      builder: (context, userSnapshot) {
        // 데이터가 로딩 중이거나 없는 경우 (에러 방지)
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return _buildUserTile(
            profileImageWidget: const Icon(
              Icons.person,
              color: Colors.grey,
            ), // 이름 변경 완료
            nickName: '알 수 없음',
            onUnblock: () => _unblockFriend(friendId, '알 수 없는 사용자'),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        // 이름 필드 체크 (name -> nickName -> nickname 순서)
        final String nickName =
            userData['name'] ??
            userData['nickName'] ??
            userData['nickname'] ??
            '이름 없음';

        // --- 프로필 이미지 로직 (캐릭터 ID 우선 체크) ---
        Widget profileWidget;
        final charId = userData['characterId'] as int?;
        final profileImageUrl = userData['profileImage'] as String?;

        if (charId != null && charId != 0) {
          profileWidget = Image.asset(
            getImagePathByCharacterId(charId),
            fit: BoxFit.cover,
          );
        } else if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          profileWidget = Image.network(profileImageUrl, fit: BoxFit.cover);
        } else {
          profileWidget = const Icon(Icons.person, color: Colors.grey);
        }

        return _buildUserTile(
          profileImageWidget: profileWidget, // 이름 변경 완료
          nickName: nickName,
          onUnblock: () => _unblockFriend(friendId, nickName),
        );
      },
    );
  }

  // 2. 사용자 정보 UI 위젯 수정 (정의 부분)
  Widget _buildUserTile({
    required Widget profileImageWidget, // 정의 부분의 이름도 확인
    required String nickName,
    required VoidCallback onUnblock,
  }) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1F1F1),
            ),
            child: ClipOval(child: profileImageWidget), // 위젯을 그대로 출력
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              nickName,
              style: const TextStyle(
                fontFamily: 'Golos Text',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Color(0xFF6F6B6B),
              ),
            ),
          ),
          TextButton(
            onPressed: onUnblock,
            child: const Text(
              '해제',
              style: TextStyle(
                fontFamily: 'Golos Text',
                fontWeight: FontWeight.w500,
                fontSize: 15.5,
                color: Color(0xFF506497),
              ),
            ),
          ),
        ],
      ),
    );
  }
}