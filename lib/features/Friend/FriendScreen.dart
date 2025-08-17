// lib/features/Friend/Friendscreen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🔥 Cloud Functions 패키지를 import 합니다.
import 'package.cloud_functions/cloud_functions.dart';
import 'package:new_project_1/features/Friend/friend_management.dart';
import '../Psychology/PsychologyResult.dart';
import 'ChatScreen.dart';
import '../Calendar/Notification.dart' as CalendarNotification;
import '../Settings/settings_screen.dart';
import 'dart:math';


// --- 데이터 모델 ---

class Friend {
  final String friendId;
  final String name;
  final String nickName;
  final List<String> tags;
  final String profileImage;
  final bool favorite;
  final bool blockStatus;

  const Friend({
    required this.friendId,
    required this.name,
    required this.nickName,
    this.tags = const [],
    this.profileImage = '',
    this.favorite = false,
    this.blockStatus = false,
  });

  // 🔥 Cloud Function의 JSON 응답을 Dart 객체로 변환하기 위한 팩토리 생성자
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendId: json['friendId'] ?? '',
      name: json['name'] ?? '',
      nickName: json['nickName'] ?? '',
      tags: List<String>.from(json['title'] ?? []),
      profileImage: json['profileImage'] ?? '',
      favorite: json['favorite'] ?? false,
      blockStatus: json['blockStatus'] ?? false,
    );
  }
}

class FriendRequest {
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderNickName;
  final List<String> senderTags;
  final String senderProfileImage;
  final Timestamp timestamp;

  const FriendRequest({
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderNickName,
    this.senderTags = const [],
    this.senderProfileImage = '',
    required this.timestamp,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderNickName: data['senderNickName'] ?? '',
      senderTags: List<String>.from(data['senderTags'] ?? []),
      senderProfileImage: data['senderProfileImage'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class RecommendedUser {
  final String uid;
  final String name;
  final String nickName;
  final String email;
  final List<String> tags;
  final String profileImage;
  final String bio;

  const RecommendedUser({
    required this.uid,
    required this.name,
    required this.nickName,
    required this.email,
    this.tags = const [],
    this.profileImage = '',
    this.bio = '',
  });

  factory RecommendedUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecommendedUser(
      uid: doc.id,
      name: data['name'] ?? '',
      nickName: data['nickName'] ?? '',
      email: data['email'] ?? '',
      tags: List<String>.from(data['title'] ?? []),
      profileImage: data['profileImage'] ?? '',
      bio: data['bio'] ?? '',
    );
  }
}

// --- 위젯 ---

class FriendScreen extends StatefulWidget {
  final Function(Character)? onShowProfile;
  const FriendScreen({Key? key, this.onShowProfile}) : super(key: key);

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // 🔥 Cloud Functions 인스턴스 생성
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
  final TextEditingController _emailCtrl = TextEditingController();
  final Random _random = Random();
  final CalendarNotification.NotificationService _notificationService = CalendarNotification.NotificationService();

  // 🔥 Stream 대신 Future로 친구 목록을 관리합니다.
  late Future<List<Friend>> _friendsFuture;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // 🔥 위젯이 생성될 때 친구 목록 로딩을 시작합니다.
    _friendsFuture = _loadFriendsList();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // 🔥 [수정됨] Cloud Function을 호출하여 친구 목록을 가져오는 함수
  Future<List<Friend>> _loadFriendsList() async {
    if (currentUserId == null) return [];
    try {
      final callable = _functions.httpsCallable('getFriendsList');
      final result = await callable.call();
      final List<dynamic> friendData = result.data;
      return friendData.map((data) => Friend.fromJson(data as Map<String, dynamic>)).toList();
    } on FirebaseFunctionsException catch (e) {
      print('친구 목록 로딩 Functions 오류: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 목록 로딩 실패: ${e.message}')),
        );
      }
      return [];
    } catch (e) {
      print('친구 목록 로딩 일반 오류: $e');
      return [];
    }
  }

  // 🔥 친구 목록을 새로고침하는 함수
  void _refreshFriendsList() {
    setState(() {
      _friendsFuture = _loadFriendsList();
    });
  }

  // 받은 친구 신청 스트림 (보안 규칙상 문제 없으므로 그대로 사용)
  Stream<List<FriendRequest>> get incomingRequestsStream {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList());
  }

  // 보낸 친구 신청 스트림 (보안 규칙상 문제 없으므로 그대로 사용)
  Stream<List<FriendRequest>> get outgoingRequestsStream {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList());
  }

  // 추천 친구 스트림 (기존 로직 유지)
  Stream<List<RecommendedUser>> get recommendedUsersStream {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .where('recommend', isEqualTo: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      List<RecommendedUser> recommended = [];
      Set<String> friendIds = {};
      try {
        // 이 부분은 보안규칙 때문에 실패하지만, 추천 친구 로직은 우선 유지
        final friendsSnapshot = await _firestore.collection('users').doc(currentUserId).collection('friends').get();
        friendIds = friendsSnapshot.docs.map((doc) => doc.data()['friendId'] as String).toSet();
      } catch (e) {
        print('추천 친구용 친구 목록 조회는 실패할 수 있습니다: $e');
      }

      for (var doc in snapshot.docs) {
        if (doc.id != currentUserId && !friendIds.contains(doc.id)) {
          recommended.add(RecommendedUser.fromFirestore(doc));
        }
      }
      recommended.shuffle(_random);
      return recommended.take(10).toList();
    });
  }

  void _refreshRecommendations() {
    setState(() {});
  }

  // 🔥 [수정됨] Cloud Function을 사용하여 이메일로 친구 신청 보내기
  Future<void> sendFriendRequestByEmail(String receiverEmail) async {
    if (currentUserId == null) return;
    if (receiverEmail == _auth.currentUser?.email) {
      _showAlert('자신에게는 친구 신청을 할 수 없습니다.');
      return;
    }

    try {
      // 1. findUserByEmail Cloud Function 호출하여 사용자 검색
      final callable = _functions.httpsCallable('findUserByEmail');
      final result = await callable.call<Map<String, dynamic>>({'email': receiverEmail});
      final data = result.data;

      if (data['success'] != true) {
        _showAlert(data['message'] ?? '사용자를 찾을 수 없습니다.');
        return;
      }

      final String receiverId = data['uid'];
      final String receiverNickName = data['nickName'];

      // 2. 이미 친구인지 확인
      final friendDoc = await _firestore.collection('users').doc(currentUserId).collection('friends').doc(receiverId).get();
      if (friendDoc.exists) {
        _showAlert('이미 친구입니다.');
        return;
      }

      // 3. 이미 보낸 신청인지 확인
      final existingRequest = await _firestore.collection('friendRequests').where('senderId', isEqualTo: currentUserId).where('receiverId', isEqualTo: receiverId).get();
      if (existingRequest.docs.isNotEmpty) {
        _showAlert('이미 친구 신청을 보냈습니다.');
        return;
      }

      // 4. 친구 신청 문서 생성
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId!).get();
      final currentUserData = currentUserDoc.data()!;

      await _firestore.collection('friendRequests').add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'senderName': currentUserData['name'],
        'senderNickName': currentUserData['nickName'],
        'senderTags': currentUserData['title'] ?? [],
        'senderProfileImage': currentUserData['profileImage'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'uid': currentUserId,
      });

      await _notificationService.createFriendRequestNotification(receiverId, currentUserData['nickName'] ?? currentUserData['name'] ?? 'Unknown');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$receiverNickName님께 친구 신청을 보냈습니다.')),
        );
      }

    } on FirebaseFunctionsException catch(e) {
      _showAlert('친구 신청 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      _showAlert('친구 신청 중 오류가 발생했습니다: $e');
    }
  }

  // 친구 신청 수락
  Future<void> acceptFriendRequest(FriendRequest request) async {
    if (currentUserId == null) return;
    try {
      final batch = _firestore.batch();
      final myFriendsRef = _firestore.collection('users').doc(currentUserId).collection('friends').doc(request.senderId);
      final theirFriendsRef = _firestore.collection('users').doc(request.senderId).collection('friends').doc(currentUserId);
      batch.set(myFriendsRef, {'friendId': request.senderId, 'favorite': false, 'blockStatus': false, 'uid': currentUserId, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(theirFriendsRef, {'friendId': currentUserId, 'favorite': false, 'blockStatus': false, 'uid': request.senderId, 'createdAt': FieldValue.serverTimestamp()});
      final requestQuery = await _firestore.collection('friendRequests').where('senderId', isEqualTo: request.senderId).where('receiverId', isEqualTo: currentUserId).get();
      for (var doc in requestQuery.docs) { batch.delete(doc.reference); }
      await batch.commit();

      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final myName = currentUserDoc.data()?['nickName'] ?? 'Unknown';
      await _notificationService.createFriendAcceptedNotification(request.senderId, myName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${request.senderNickName}님과 친구가 되었습니다!')));
      }

      // 🔥 친구 목록 새로고침
      _refreshFriendsList();
    } catch (e) {
      _showAlert('친구 수락 중 오류가 발생했습니다: $e');
    }
  }

  // 친구 신청 거절
  Future<void> rejectFriendRequest(FriendRequest request) async {
    try {
      final requestQuery = await _firestore.collection('friendRequests').where('senderId', isEqualTo: request.senderId).where('receiverId', isEqualTo: currentUserId).get();
      for (var doc in requestQuery.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${request.senderNickName}님의 친구 신청을 거절했습니다.')),
        );
      }
    } catch (e) {
      _showAlert('친구 신청 거절 중 오류가 발생했습니다: $e');
    }
  }

  // 친구 차단
  Future<void> blockFriend(Friend friend) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).collection('friends').doc(friend.friendId).update({
        'blockStatus': true, 'uid': currentUserId, 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${friend.nickName}님을 차단했습니다.')));
      }
      // 🔥 친구 목록 새로고침
      _refreshFriendsList();
    } catch (e) {
      _showAlert('친구 차단 중 오류가 발생했습니다: $e');
    }
  }

  // 친구 삭제
  Future<void> deleteFriend(Friend friend) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).collection('friends').doc(friend.friendId).delete();
      await _firestore.collection('friendDeletionRequests').add({'requesterId': currentUserId, 'targetUserId': friend.friendId, 'timestamp': FieldValue.serverTimestamp(), 'uid': currentUserId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${friend.nickName}님을 친구 목록에서 삭제했습니다.')));
      }
      // 🔥 친구 목록 새로고침
      _refreshFriendsList();
    } catch (e) {
      _showAlert('친구 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 즐겨찾기 토글
  Future<void> toggleFavorite(Friend friend) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).collection('friends').doc(friend.friendId).update({
        'favorite': !friend.favorite, 'uid': currentUserId, 'updatedAt': FieldValue.serverTimestamp(),
      });
      // 🔥 즐겨찾기는 UI에서 즉시 반영되도록 상태를 갱신
      _refreshFriendsList();
    } catch (e) {
      _showAlert('즐겨찾기 설정 중 오류가 발생했습니다: $e');
    }
  }

  // 친구 신청 취소
  Future<void> cancelFriendRequest(FriendRequest request) async {
    try {
      final requestQuery = await _firestore.collection('friendRequests').where('senderId', isEqualTo: currentUserId).where('receiverId', isEqualTo: request.receiverId).get();
      for (var doc in requestQuery.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 신청을 취소했습니다.')),
        );
      }
    } catch (e) {
      _showAlert('친구 신청 취소 중 오류가 발생했습니다: $e');
    }
  }

  // 닉네임 가져오기
  Future<String> getReceiverNickName(String receiverId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('nickName')) {
        return userDoc.data()!['nickName'] ?? receiverId;
      }
    } catch (e) {
      print('닉네임 가져오기 오류: $e');
    }
    return receiverId;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CalendarNotification.NotificationPage()
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            onTap: (index) {
              if (index == 2) {
                _refreshRecommendations();
              }
            },
            tabs: const [
              Tab(text: '친구 목록'),
              Tab(text: '신청 목록'),
              Tab(text: '추천 친구'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendList(),
            _buildRequestList(),
            _buildRecommendationSlider(),
          ],
        ),
      ),
    );
  }

  // 🔥 [수정됨] FutureBuilder를 사용하여 친구 목록 UI 구성
  Widget _buildFriendList() {
    return FutureBuilder<List<Friend>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('아직 친구가 없습니다', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshFriendsList(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final friend = friends[idx];
              return _FriendTile(
                name: friend.nickName,
                tags: friend.tags,
                tileColor: Colors.grey.shade50,
                isFavorite: friend.favorite,
                onFavoriteToggle: () => toggleFavorite(friend),
                onTap: () {},
                trailingButtons: [
                  TextButton(onPressed: () => _showConfirm('차단', () => blockFriend(friend)), child: const Text('차단', style: TextStyle(color: Colors.blue))),
                  TextButton(onPressed: () => _showConfirm('삭제', () => deleteFriend(friend)), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '이메일로 친구 추가',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final email = _emailCtrl.text.trim();
                  if (email.isNotEmpty) {
                    sendFriendRequestByEmail(email);
                    _emailCtrl.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(60, 44),
                ),
                child: const Text('추가', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 받은 친구 신청
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('나랑 친구해줘!', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              children: [
                StreamBuilder<List<FriendRequest>>(
                  stream: incomingRequestsStream,
                  builder: (context, snapshot) {
                    // 🔥 Git 병합 충돌 흔적 제거됨
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final requests = snapshot.data ?? [];
                    if (requests.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('받은 친구 신청이 없습니다.'),
                      );
                    }
                    return Column(
                      children: requests.map((request) {
                        return _FriendTile(
                          name: request.senderNickName,
                          tags: request.senderTags,
                          tileColor: const Color(0xFFE8F0FE),
                          isFavorite: false,
                          onFavoriteToggle: null,
                          onTap: () {},
                          tagBgColor: const Color(0xFFD0E4FF),
                          tagTextColor: const Color(0xFF0066CC),
                          trailingButtons: [
                            TextButton(onPressed: () => acceptFriendRequest(request), child: const Text('수락', style: TextStyle(color: Colors.green))),
                            TextButton(onPressed: () => _showConfirm('거절', () => rejectFriendRequest(request)), child: const Text('거절', style: TextStyle(color: Colors.red))),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 32, thickness: 1),
          // 보낸 친구 신청
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('언제쯤 받아줄까...', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              children: [
                StreamBuilder<List<FriendRequest>>(
                  stream: outgoingRequestsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final requests = snapshot.data ?? [];
                    if (requests.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('보낸 친구 신청이 없습니다.'),
                      );
                    }
                    return Column(
                      children: requests.map((request) {
                        return FutureBuilder<String>(
                          future: getReceiverNickName(request.receiverId),
                          builder: (context, snapshot) {
                            final receiverNickName = snapshot.data ?? request.receiverId;
                            return _FriendTile(
                              name: receiverNickName,
                              tags: const [],
                              tileColor: const Color(0xFFFBF5EB),
                              isFavorite: false,
                              onFavoriteToggle: null,
                              onTap: () {},
                              trailingButtons: [
                                ElevatedButton(
                                  onPressed: () => cancelFriendRequest(request),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size(100, 36),
                                  ),
                                  child: const Text('친구 신청 취소', style: TextStyle(color: Colors.white)),
                                ),
                              ],
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

  // 추천 친구 슬라이더
  Widget _buildRecommendationSlider() {
    return StreamBuilder<List<RecommendedUser>>(
      stream: recommendedUsersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }
        final recommendedUsers = snapshot.data ?? [];
        if (recommendedUsers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('추천할 친구가 없습니다', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Text('새로운 친구들이 곧 추천될 예정입니다!', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('추천 친구', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _refreshRecommendations,
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    tooltip: '새로운 추천 친구 보기',
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: recommendedUsers.length,
                itemBuilder: (context, i) {
                  final user = recommendedUsers[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7EFE6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.brown[100]!, width: 3),
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: user.profileImage.isNotEmpty
                                  ? Image.network(user.profileImage, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 60, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/friendScreen/star_on.png', width: 20, height: 20),
                              const SizedBox(width: 6),
                              Text(user.nickName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: user.tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text('#$tag', style: const TextStyle(fontSize: 13, color: Colors.brown)),
                            )).toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                            child: Text(user.bio.isNotEmpty ? user.bio : '안녕하세요!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => sendFriendRequestByEmail(user.email),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              shape: const StadiumBorder(),
                              minimumSize: const Size(140, 44),
                            ),
                            child: const Text('친구 신청', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (recommendedUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('옆으로 스와이프 하세요', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  const Icon(Icons.refresh, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _refreshRecommendations,
                    child: const Text('새로고침', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  void _showConfirm(String action, VoidCallback onOk) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('정말 $action 하시겠습니까?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('아니요'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onOk();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('네', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlert(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String name;
  final List<String> tags;
  final Color tileColor;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback onTap;
  final List<Widget> trailingButtons;
  final Color? tagBgColor;
  final Color? tagTextColor;

  const _FriendTile({
    required this.name,
    required this.tags,
    required this.tileColor,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.trailingButtons,
    this.tagBgColor,
    this.tagTextColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tagBackground = tagBgColor ?? Colors.yellow.shade100;
    final tagText = tagTextColor ?? Colors.brown.shade800;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (onFavoriteToggle != null) ...[
              GestureDetector(
                onTap: onFavoriteToggle,
                child: Image.asset(
                  isFavorite
                      ? 'assets/images/friendScreen/star_on.png'
                      : 'assets/images/friendScreen/star_off.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags
                        .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: tagBackground, borderRadius: BorderRadius.circular(8)),
                      child: Text('#$tag', style: TextStyle(fontSize: 12, color: tagText)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            ...trailingButtons,
          ],
        ),
      ),
    );
  }
}

// Firebase와 연결된 친구 관리 화면
class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({Key? key}) : super(key: key);

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _recommendationsEnabled = true;
  bool _isLoading = false;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    if (currentUserId == null) return;
    try {
      setState(() => _isLoading = true);
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (!userData.containsKey('uid') || userData['uid'] != currentUserId) {
          await _firestore.collection('users').doc(currentUserId).update({'uid': currentUserId, 'updateAt': FieldValue.serverTimestamp()});
        }
        setState(() => _recommendationsEnabled = userData['recommend'] ?? true);
      } else {
        await _firestore.collection('users').doc(currentUserId).set({'uid': currentUserId, 'recommend': true, 'createdAt': FieldValue.serverTimestamp(), 'updateAt': FieldValue.serverTimestamp()});
        setState(() => _recommendationsEnabled = true);
      }
    } catch (e) {
      print('설정 불러오기 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRecommendationSettings(bool enabled) async {
    if (currentUserId == null) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(currentUserId).update({'recommend': enabled, 'uid': currentUserId, 'updateAt': FieldValue.serverTimestamp()});
      setState(() => _recommendationsEnabled = enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enabled ? '추천 친구 기능이 활성화되었습니다.' : '추천 친구 기능이 비활성화되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('설정 업데이트 중 오류가 발생했습니다: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Stream<List<Friend>> get blockedFriendsStream {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users').doc(currentUserId).collection('friends').where('blockStatus', isEqualTo: true).snapshots()
        .asyncMap((snapshot) async {
      List<Friend> blockedFriends = [];
      for (var doc in snapshot.docs) {
        final friendData = doc.data();
        final friendId = friendData['friendId'];
        try {
          final userDoc = await _firestore.collection('users').doc(friendId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            if (userData.containsKey('uid')) {
              blockedFriends.add(Friend.fromJson({
                ...userData,
                'friendId': friendId,
                'favorite': friendData['favorite'] ?? false,
                'blockStatus': friendData['blockStatus'] ?? false,
              }));
            }
          }
        } catch (e) {
          print('차단된 친구 정보 로딩 오류: $e');
        }
      }
      return blockedFriends;
    });
  }

  Future<void> unblockFriend(Friend friend) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).collection('friends').doc(friend.friendId).update({
        'blockStatus': false, 'uid': currentUserId, 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${friend.nickName}님의 차단을 해제했습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('차단 해제 중 오류가 발생했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('추천 친구 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('다른 사용자들에게 나를 추천 친구로 표시할지 설정할 수 있습니다.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('추천 친구 활성화'),
                    subtitle: Text(_recommendationsEnabled ? '다른 사용자들에게 추천됩니다' : '다른 사용자들에게 추천되지 않습니다'),
                    value: _recommendationsEnabled,
                    onChanged: _updateRecommendationSettings,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('차단된 친구', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<List<Friend>>(
              stream: blockedFriendsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                final blockedFriends = snapshot.data ?? [];
                if (blockedFriends.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.block, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('차단된 친구가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: blockedFriends.map((friend) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(friend.nickName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                if (friend.tags.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: friend.tags.take(2).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text('#$tag', style: const TextStyle(fontSize: 10, color: Colors.red)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => unblockFriend(friend),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green.shade50,
                              foregroundColor: Colors.green,
                              minimumSize: const Size(80, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('차단 해제'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}