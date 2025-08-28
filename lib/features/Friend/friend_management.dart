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
      final friendDoc = await _firestore
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CSS에 명시된 배경색 적용
      backgroundColor: const Color(0xFFFFFEF9),
      appBar: AppBar(
        // AppBar 배경색도 Scaffold와 동일하게 설정
        backgroundColor: const Color(0xFFFFFEF9),
        // 그림자 제거
        elevation: 0,
        // 뒤로가기 버튼 색상 지정
        iconTheme: const IconThemeData(color: Color(0xFF504A4A)),
        // 제목 스타일링
        title: const Text(
          '친구 관리',
          style: TextStyle(
            fontFamily: 'Golos Text', // 폰트가 프로젝트에 추가되어 있어야 함
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF504A4A),
          ),
        ),
        centerTitle: false, // 제목을 왼쪽으로 정렬
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              // 전체적인 좌우 패딩 적용
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              children: [
                _buildRecommendationTile(),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE4E4E4), thickness: 1),
                const SizedBox(height: 8),
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
                fontWeight: FontWeight.w500, // CSS의 530은 w500에 가장 가까움
                fontSize: 16,
                color: Color(0xFF504A4A),
              ),
            ),
          ),
          // 디자인에 맞게 스위치 커스텀
          Switch(
            value: _recommendationsEnabled,
            onChanged: _updateRecommendationSetting,
            activeTrackColor: const Color(0xFF95A797),
            activeColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
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
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xFF504A4A),
          ),
        ),
        children: [
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
                    child: Text('차단된 친구가 없습니다', style: TextStyle(color: Colors.grey)),
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
                separatorBuilder: (context, index) => const SizedBox(height: 12),
              );
            },
          ),
        ],
      ),
    );
  }

  // 차단된 친구 한 명을 표시하는 타일 위젯
  Widget _buildBlockedFriendTile(QueryDocumentSnapshot doc) {
    final friendData = doc.data() as Map<String, dynamic>;
    final friendId = friendData['friendId'] as String? ?? '';

    if (friendId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(friendId).get(),
      builder: (context, userSnapshot) {
        // 로딩 중이거나 데이터가 없을 때의 UI
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          // 데이터가 없는 경우에도 차단 해제는 가능하도록 ID를 전달
          return _buildUserTile(
            profileImageUrl: null,
            nickName: '알 수 없음',
            onUnblock: () => _unblockFriend(friendId, '알 수 없는 사용자'),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final nickName = userData['nickName'] as String? ?? '이름 없음';
        final profileImage = userData['profileImage'] as String?;

        return _buildUserTile(
          profileImageUrl: profileImage,
          nickName: nickName,
          onUnblock: () => _unblockFriend(friendId, nickName),
        );
      },
    );
  }
  
  // 사용자 정보 타일 UI를 구성하는 별도 위젯
  Widget _buildUserTile({
    required String? profileImageUrl,
    required String nickName,
    required VoidCallback onUnblock,
  }) {
    return Container(
      height: 62, // CSS 기반 높이 고정
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFF1F1F1),
            backgroundImage:
                profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
            child: profileImageUrl == null || profileImageUrl.isEmpty
                // 이미지가 없을 때 기본 아이콘
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              nickName,
              style: const TextStyle(
                fontFamily: 'Golos Text',
                fontWeight: FontWeight.w500,
                fontSize: 16,
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
                fontSize: 14,
                color: Color(0xFF506497),
              ),
            ),
          ),
        ],
      ),
    );
  }
}