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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _recommendationsEnabled = true;
  bool _isLoading = true; // ✅ 초기 상태를 로딩 중으로 변경

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  // ✅ 설정을 불러오고, 없는 경우 기본값을 생성하는 로직을 간소화
  Future<void> _loadCurrentSettings() async {
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDocRef = _firestore.collection('users').doc(currentUserId);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        // 'recommend' 필드가 없으면 true를 기본값으로 설정
        setState(() {
          _recommendationsEnabled = userData['recommend'] ?? true;
        });
        // 만약 필드가 없다면, 기본값을 DB에 저장해줍니다.
        if (!userData.containsKey('recommend')) {
          await userDocRef.update({'recommend': true});
        }
      } else {
        // 사용자 문서가 아예 없는 경우, 기본 설정으로 생성
        await userDocRef.set({
          'recommend': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _recommendationsEnabled = true;
        });
      }
    } catch (e) {
      print('설정 불러오기 오류: $e');
      _showSnackBar('설정을 불러오는 중 오류가 발생했습니다.');
    } finally {
      // ✅ try/catch 블록이 끝나면 항상 로딩 상태를 해제
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ 업데이트 로직은 기존과 거의 동일하지만, 안정성을 위해 `update` 사용
  Future<void> _updateRecommendationSetting(bool enabled) async {
    if (currentUserId == null) return;

    // UI 즉시 반영
    setState(() => _recommendationsEnabled = enabled);

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'recommend': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar(enabled ? '추천 친구 기능이 활성화되었습니다.' : '추천 친구 기능이 비활성화되었습니다.');
    } catch (e) {
      // 오류 발생 시 UI를 이전 상태로 되돌림
      setState(() => _recommendationsEnabled = !enabled);
      print('추천 설정 업데이트 오류: $e');
      _showSnackBar('설정 업데이트에 실패했습니다.');
    }
  }

  Future<void> _unblockFriend(String friendId, String nickName) async {
    if (currentUserId == null) return;

    try {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('친구 관리', style: TextStyle(color: Color(0xFF504A4A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF504A4A)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRecommendationTile(),
          const SizedBox(height: 24),
          _buildBlockedFriendsSection(),
        ],
      ),
    );
  }

  // ✅ 위젯을 별도 메서드로 분리하여 가독성 향상
  Widget _buildRecommendationTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('추천 친구 활성화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF504A4A))),
                const SizedBox(height: 4),
                Text(
                  _recommendationsEnabled ? '다른 사용자들에게 추천됩니다' : '다른 사용자들에게 추천되지 않습니다',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9F9C9C)),
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
            onChanged: _updateRecommendationSetting,
          ),
        ],
      ),
    );
  }

  // ✅ 위젯을 별도 메서드로 분리하여 가독성 향상
  Widget _buildBlockedFriendsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('차단된 친구', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF504A4A))),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: currentUserId != null
                ? _firestore.collection('users').doc(currentUserId).collection('friends').where('blockStatus', isEqualTo: true).snapshots()
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('오류가 발생했습니다.'));
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
                        Text('차단된 친구가 없습니다', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: blockedDocs.map((doc) => _buildBlockedFriendTile(doc)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ 차단된 친구 한 명을 표시하는 타일 위젯
  Widget _buildBlockedFriendTile(QueryDocumentSnapshot doc) {
    final friendData = doc.data() as Map<String, dynamic>;
    final friendId = friendData['friendId'] as String? ?? '';

    if (friendId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(friendId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          // 사용자를 찾을 수 없거나 로딩 중일 때 간단한 표시
          return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                CircleAvatar(backgroundColor: Colors.grey[200], child: const Icon(Icons.person_off)),
                const SizedBox(width: 12),
                const Expanded(child: Text('알 수 없는 사용자')),
                TextButton(
                    onPressed: () => _unblockFriend(friendId, '알 수 없는 사용자'),
                    child: const Text('차단 해제', style: TextStyle(color: Color(0xFF506497)))),
              ]));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final nickName = userData['nickName'] as String? ?? '이름 없음';
        final profileImage = userData['profileImage'] as String? ?? '';

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
                backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                child: profileImage.isEmpty ? Text(nickName.isNotEmpty ? nickName[0] : '?') : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(nickName, style: const TextStyle(fontSize: 16))),
              TextButton(
                onPressed: () => _unblockFriend(friendId, nickName),
                child: const Text('차단 해제', style: TextStyle(color: Color(0xFF506497))),
              ),
            ],
          ),
        );
      },
    );
  }
}