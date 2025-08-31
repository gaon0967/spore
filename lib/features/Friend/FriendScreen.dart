import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:new_project_1/features/Friend/friend_management.dart';
import '../Psychology/PsychologyResult.dart';
import 'ChatScreen.dart';
import '../Calendar/Notification.dart' as CalendarNotification;
import '../Settings/settings_screen.dart';
import 'dart:math';
import '../Settings/TitleHandler.dart';
import '../Settings/firebase_title.dart' as TitlesRemote;

// --- 데이터 모델 ---

class Friend {
  final String friendId;
  final String name;
  final List<String> tags;
  final String profileImage;
  final bool favorite;
  final bool blockStatus;

  const Friend({
    required this.friendId,
    required this.name,
    this.tags = const [],
    this.profileImage = '',
    this.favorite = false,
    this.blockStatus = false,
  });
}

class FriendRequest {
  final String senderId;
  final String receiverId;
  final String senderName;
  final List<String> senderTags;
  final String senderProfileImage;
  final Timestamp timestamp;

  const FriendRequest({
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    this.senderTags = const [],
    this.senderProfileImage = '',
    required this.timestamp,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<String> tags = [];
    // senderTags 필드가 존재하는지 확인하고, 타입에 따라 안전하게 파싱합니다.
    final senderTagsData = data['senderTags'];
    if (senderTagsData != null) {
      if (senderTagsData is List) {
        tags = List<String>.from(senderTagsData);
      } else if (senderTagsData is Map) {
        // Map일 경우, values만 가져와서 리스트로 변환 (DB 스냅샷과 유사한 처리)
        tags = senderTagsData.values.map((e) => e.toString()).toList();
      }
    }

    return FriendRequest(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderTags: tags, // 안전하게 파싱된 tags 리스트를 사용
      senderProfileImage: data['senderProfileImage'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class RecommendedUser {
  final String uid;
  final String name;
  final String email;
  final List<String> tags;
  final String profileImage;
  final String bio;

  const RecommendedUser({
    required this.uid,
    required this.name,
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
      email: data['email'] ?? '',
      tags: List<String>.from(data['title'] ?? []),
      profileImage: data['profileImage'] ?? '',
      bio: data['bio'] ?? '',
    );
  }
}

// --- 위젯 ---

class FriendScreen extends StatefulWidget {
  final void Function({int tabIndex, bool expandRequests}) onNavigateToFriends;
  final Function(Character)? onShowProfile;
  final int initialTabIndex;
  final bool expandRequestsSection;

  const FriendScreen({
    Key? key,
    this.onShowProfile,
    this.initialTabIndex = 0,
    this.expandRequestsSection = false,
    required this.onNavigateToFriends,
  }) : super(key: key);

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
  final TextEditingController _emailCtrl = TextEditingController();
  final Random _random = Random();
  final CalendarNotification.NotificationService _notificationService = CalendarNotification.NotificationService();


  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // 친구 목록 가져오기
  Stream<List<Friend>> get friendsStream {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('blockStatus', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Friend> friends = [];
      for (var doc in snapshot.docs) {
        final friendData = doc.data();
        final friendId = friendData['friendId'];
        try {
          final userDoc = await _firestore.collection('users').doc(friendId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            friends.add(Friend(
              friendId: friendId,
              name: userData['name'] ?? '',
              tags: List<String>.from(userData['title'] ?? []),
              profileImage: userData['profileImage'] ?? '',
              favorite: friendData['favorite'] ?? false,
              blockStatus: friendData['blockStatus'] ?? false,
            ));
          }
        } catch (e) {
          print('친구 정보 로딩 오류: $e');
        }
      }
      return friends;
    });
  }

  // 추천 친구 가져오기
  Stream<List<RecommendedUser>> get recommendedUsersStream {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .where('recommend', isEqualTo: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      List<RecommendedUser> recommended = [];
      Set<String> friendIds = {};
      try {
        final friendsSnapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .get();
        friendIds = friendsSnapshot.docs.map((doc) => doc.data()['friendId'] as String).toSet();
      } catch (e) {
        print('친구 목록 조회 오류: $e');
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

  // 받은 친구 신청 스트림
  Stream<List<FriendRequest>> get incomingRequestsStream {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print('FriendScreen: Firestore에서 ${snapshot.docs.length}개의 친구 신청 문서를 찾았습니다.');
      if (snapshot.docs.isNotEmpty) {
        print('첫 번째 문서 데이터: ${snapshot.docs.first.data()}');
      }
      return snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList();
    });
  }

  // 보낸 친구 신청 스트림
  Stream<List<FriendRequest>> get outgoingRequestsStream {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList());
  }

  void _refreshRecommendations() {
    setState(() {});
  }

  // 친구 신청 보내기
  Future<void> sendFriendRequestByEmail(String receiverEmail) async {
    if (currentUserId == null) return;
    if (receiverEmail == _auth.currentUser?.email) {
      _showAlert('자신에게는 친구 신청을 할 수 없습니다.');
      return;
    }

    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: receiverEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showAlert('해당 이메일의 사용자를 찾을 수 없습니다.');
        return;
      }

      final targetUserDoc = userQuery.docs.first;
      final receiverId = targetUserDoc.id;
      final receiverData = targetUserDoc.data();

      final friendDoc = await _firestore.collection('users').doc(currentUserId).collection('friends').doc(receiverId).get();
      if (friendDoc.exists) {
        _showAlert('이미 친구입니다.');
        return;
      }

      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: receiverId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        _showAlert('이미 친구 신청을 보냈습니다.');
        return;
      }

      final currentUserDoc = await _firestore.collection('users').doc(currentUserId!).get();
      final currentUserData = currentUserDoc.data()!;

      await _firestore.collection('friendRequests').add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'senderName': currentUserData['name'] ?? '',
        'senderTags': currentUserData['title'] ?? [],
        'senderProfileImage': currentUserData['profileImage'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _emailCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${receiverData['nickName'] ?? receiverData['name']}님께 친구 신청을 보냈습니다.')),
        );
      }
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
      batch.set(myFriendsRef, {'friendId': request.senderId, 'favorite': false, 'blockStatus': false, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(theirFriendsRef, {'friendId': currentUserId, 'favorite': false, 'blockStatus': false, 'createdAt': FieldValue.serverTimestamp()});

      final requestQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: request.senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      for (var doc in requestQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 파이어베이스에서 최신 친구 목록 개수 가져오기
      final newFriendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .where('blockStatus', isEqualTo: false)
          .get();

      final newFriendCount = newFriendsSnapshot.docs.length;
      // 친구맺기 타이틀 지급
      await TitlesRemote.handleFriendCount(
        newFriendCount,
        onUpdate: () => setState(() {}),
      );

      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final myName = currentUserDoc.data()?['name'] ?? 'Unknown';
      await _notificationService.createFriendAcceptedNotification(request.senderId, myName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${request.senderName}님과 친구가 되었습니다!')),
        );
      }
    } catch (e) {
      _showAlert('친구 수락 중 오류가 발생했습니다: $e');
    }
  }

  // 친구 신청 거절
  Future<void> rejectFriendRequest(FriendRequest request) async {
    try {
      final requestQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: request.senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      for (var doc in requestQuery.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${request.senderName}님의 친구 신청을 거절했습니다.')),
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
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friend.friendId)
          .update({
        'blockStatus': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${friend.name}님을 차단했습니다.')),
        );
      }
    } catch (e) {
      _showAlert('친구 차단 중 오류가 발생했습니다: $e');
    }
  }

  // 친구 삭제
  Future<void> deleteFriend(Friend friend) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friend.friendId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${friend.name}님을 친구 목록에서 삭제했습니다.')),
        );
      }
    } catch (e) {
      _showAlert('친구 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 즐겨찾기 토글
  Future<void> toggleFavorite(Friend friend) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friend.friendId)
          .update({
        'favorite': !friend.favorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 친구 즐겨찾기 타이틀 지급
      final int favoriteCount = await _getFavoriteCount();
      await TitlesRemote.handleFavoriteFriendTitleFirestore(
        favoriteCount,
        onUpdate: () => setState(() {}),
      );

    } catch (e) {
      _showAlert('즐겨찾기 설정 중 오류가 발생했습니다: $e');
    }
  }

  // 즐겨찾기 친구 수를 파이어베이스에서 직접 가져오는 함수
  Future<int> _getFavoriteCount() async {
    // 현재 로그인한 사용자가 없다면 0을 반환
    if (currentUserId == null) {
      return 0;
    }

    // 'friends' 컬렉션에서 'favorite'가 true인 문서들을 모두 가져옴
    final querySnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('favorite', isEqualTo: true)
        .get();

    // 가져온 문서들의 개수를 반환
    return querySnapshot.docs.length;
  }

  // 친구 신청 취소
  Future<void> cancelFriendRequest(FriendRequest request) async {
    try {
      final requestQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: request.receiverId)
          .get();

      for (var doc in requestQuery.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 신청을 취소했습니다.')),
        );
      }
    } catch (e) {
      _showAlert('친구 신청 취소 중 오류가 발생했습니다: $e');
    }
  }

  Future<String> getReceiverNickName(String receiverId) async {
    if (receiverId.isEmpty) return '알 수 없음';

    try {
      final userDoc = await _firestore.collection('users').doc(receiverId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // ✅ 'nickName' 대신 'name' 필드를 사용하도록 수정합니다.
        if (data.containsKey('name') && data['name'] != null) {
          return data['name'];
        } else {
          // 혹시 모를 예외 상황에 대비해, 'name'이 없으면 'nickname'을 대신 보여줍니다.
          return data['nickname'] ?? '이름 없음';
        }
      } else {
        return '탈퇴한 사용자';
      }
    } catch (e) {
      print('닉네임 가져오기 오류: $e');
      return '오류 발생';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('FriendScreen 현재 사용자 UID: $currentUserId');
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
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
                  builder: (context) => CalendarNotification.NotificationPage(
                    // 전달받은 콜백(widget.onNavigateToFriends)을 넘겨줍니다.
                    onNavigateToFriends: widget.onNavigateToFriends,
                  ),
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

  Widget _buildFriendList() {
    return StreamBuilder<List<Friend>>(
      stream: friendsStream,
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
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final friend = friends[idx];
              return _FriendTile(
                name: friend.name,
                tags: friend.tags,
                tileColor: Colors.grey.shade50,
                isFavorite: friend.favorite,
                onFavoriteToggle: () => toggleFavorite(friend),
                onTap: () {},
                trailingButtons: [
                  TextButton(
                    onPressed: () => _showConfirm('차단', () => blockFriend(friend)),
                    child: const Text('차단', style: TextStyle(color: Colors.blue)),
                  ),
                  TextButton(
                    onPressed: () => _showConfirm('삭제', () => deleteFriend(friend)),
                    child: const Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
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
              initiallyExpanded: widget.expandRequestsSection,
              title: const Text('나랑 친구해줘!', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              children: [
                StreamBuilder<List<FriendRequest>>(
                  stream: incomingRequestsStream,
                  builder: (context, snapshot) {
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
                          name: request.senderName,
                          tags: request.senderTags,
                          tileColor: const Color(0xFFE8F0FE),
                          isFavorite: false,
                          onFavoriteToggle: null,
                          onTap: () {},
                          tagBgColor: const Color(0xFFD0E4FF),
                          tagTextColor: const Color(0xFF0066CC),
                          trailingButtons: [
                            TextButton(
                              onPressed: () => acceptFriendRequest(request),
                              child: const Text('수락', style: TextStyle(color: Colors.green)),
                            ),
                            TextButton(
                              onPressed: () => _showConfirm('거절', () => rejectFriendRequest(request)),
                              child: const Text('거절', style: TextStyle(color: Colors.red)),
                            ),
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
              initiallyExpanded: false,
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
                            final receiverNickName = snapshot.data ?? '...';
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
              child: RefreshIndicator(
                onRefresh: () async => _refreshRecommendations(),
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
                                Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
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
      builder: (BuildContext dialogContext) => Dialog(
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
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('아니요'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
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
      builder: (BuildContext dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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