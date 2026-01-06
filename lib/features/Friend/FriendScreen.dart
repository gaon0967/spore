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
    final senderTagsData = data['senderTags'];
    if (senderTagsData != null) {
      if (senderTagsData is List) {
        tags = List<String>.from(senderTagsData);
      } else if (senderTagsData is Map) {
        // Map일 경우, values만 가져와서 리스트로 변환
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

    // 1. 선택된 타이틀(selectedTitles)을 먼저 찾고, 없으면 획득 목록(unlocked_titles)에서 2개를 가져옴
    var rawTags = data['selectedTitles'] ?? data['title'] ?? data['unlocked_titles'] ?? [];
    
    List<String> tagsList = [];
    if (rawTags is List) {
      // 2. 최대 2개까지만 제한
      tagsList = List<String>.from(rawTags).take(2).toList();
    }

    return RecommendedUser(
      uid: doc.id,
      name: data['name'] ?? data['nickName'] ?? '이름 없음',
      email: data['email'] ?? '',
      tags: tagsList,
      profileImage: (data['profileImage'] ?? data['characterId'] ?? '').toString(),
      bio: data['bio'] ?? data['intro'] ?? '',
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
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-northeast3',
  );
  final TextEditingController _emailCtrl = TextEditingController();
  final Random _random = Random();
  final CalendarNotification.NotificationService _notificationService =
      CalendarNotification.NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  late PageController _pageController;
  double _currentPage = 0;
  
  bool _recommendationsEnabled = true; 
  late Stream<List<RecommendedUser>> _recommendedStream; 

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _currentPage = _pageController.page!;
          });
        }
      });

    // 추천 친구 스트림 초기화 (빌드 시 재생성 방지)
    _recommendedStream = recommendedUsersStream;

    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // 새로고침 시에도 스트림 변수를 업데이트
  void _refreshRecommendations() {
    setState(() {
      _recommendedStream = recommendedUsersStream;
    });
  }

  Future<void> _loadCurrentSettings() async {
    if (currentUserId == null) return;
    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _recommendationsEnabled = userDoc.data()?['recommend'] ?? true;
        });
      }
    } catch (e) {
      print('설정 로드 오류: $e');
    }
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
                
                // --- 타이틀 선택 로직 수정 ---
                // 1. 'selectedTitles' 또는 'title' 필드에서 선택된 2개를 가져옴
                var rawTags = userData['selectedTitles'] ?? userData['title'] ?? [];
                List<String> tagsList = [];
                if (rawTags is List) {
                  // 최대 2개만 선택 (take(2))
                  tagsList = List<String>.from(rawTags).take(2).toList();
                }
                // ----------------------------

                friends.add(
                  Friend(
                    friendId: friendId,
                    name: userData['name'] ?? '',
                    tags: tagsList, 
                    profileImage: userData['profileImage'] ?? '',
                    favorite: friendData['favorite'] ?? false,
                    blockStatus: friendData['blockStatus'] ?? false,
                  ),
                );
              }
            } catch (e) {
              print('친구 정보 로딩 오류: $e');
            }
          }

          friends.sort((a, b) {
            if (a.favorite && !b.favorite) return -1;
            if (!a.favorite && b.favorite) return 1;
            return a.name.compareTo(b.name);
          });

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
            final friendsSnapshot =
                await _firestore
                    .collection('users')
                    .doc(currentUserId)
                    .collection('friends')
                    .get();
            friendIds =
                friendsSnapshot.docs
                    .map((doc) => doc.data()['friendId'] as String)
                    .toSet();
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
          print(
            'FriendScreen: Firestore에서 ${snapshot.docs.length}개의 친구 신청 문서를 찾았습니다.',
          );
          if (snapshot.docs.isNotEmpty) {
            print('첫 번째 문서 데이터: ${snapshot.docs.first.data()}');
          }
          return snapshot.docs
              .map((doc) => FriendRequest.fromFirestore(doc))
              .toList();
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
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FriendRequest.fromFirestore(doc))
                  .toList(),
        );
  }


  // 친구 신청 보내기
  Future<void> sendFriendRequestByEmail(String receiverEmail) async {
    if (currentUserId == null) return;
    if (receiverEmail == _auth.currentUser?.email) {
      _showAlert('자신에게는 친구 신청을 할 수 없습니다.');
      return;
    }

    try {
      final userQuery =
          await _firestore
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

      final friendDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc(receiverId)
              .get();
      if (friendDoc.exists) {
        _showAlert('이미 친구입니다.');
        return;
      }

      final existingRequest =
          await _firestore
              .collection('friendRequests')
              .where('senderId', isEqualTo: currentUserId)
              .where('receiverId', isEqualTo: receiverId)
              .get();

      if (existingRequest.docs.isNotEmpty) {
        _showAlert('이미 친구 신청을 보냈습니다.');
        return;
      }

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId!).get();
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
          SnackBar(
            content: Text(
              '${receiverData['nickName'] ?? receiverData['name']}님께 친구 신청을 보냈습니다.',
            ),
          ),
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

      final myFriendsRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(request.senderId);
      final theirFriendsRef = _firestore
          .collection('users')
          .doc(request.senderId)
          .collection('friends')
          .doc(currentUserId);
      batch.set(myFriendsRef, {
        'friendId': request.senderId,
        'favorite': false,
        'blockStatus': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(theirFriendsRef, {
        'friendId': currentUserId,
        'favorite': false,
        'blockStatus': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final requestQuery =
          await _firestore
              .collection('friendRequests')
              .where('senderId', isEqualTo: request.senderId)
              .where('receiverId', isEqualTo: currentUserId)
              .get();

      for (var doc in requestQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 파이어베이스에서 최신 친구 목록 개수 가져오기
      final newFriendsSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .where('blockStatus', isEqualTo: false)
              .get();

      final newFriendCount = newFriendsSnapshot.docs.length;
      handleFriendCountChange(newFriendCount); // 친구맺기 타이틀 지급

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final myName = currentUserDoc.data()?['name'] ?? 'Unknown';
      await _notificationService.createFriendAcceptedNotification(
        request.senderId,
        myName,
      );

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
      final requestQuery =
          await _firestore
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${friend.name}님을 차단했습니다.')));
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
      await handleFavoriteFriendTitle(favoriteCount);
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
    final querySnapshot =
        await _firestore
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
      final requestQuery =
          await _firestore
              .collection('friendRequests')
              .where('senderId', isEqualTo: currentUserId)
              .where('receiverId', isEqualTo: request.receiverId)
              .get();

      for (var doc in requestQuery.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('친구 신청을 취소했습니다.')));
      }
    } catch (e) {
      _showAlert('친구 신청 취소 중 오류가 발생했습니다: $e');
    }
  }

  Future<String> getReceiverNickName(String receiverId) async {
    if (receiverId.isEmpty) return '알 수 없음';

    try {
      final userDoc =
          await _firestore.collection('users').doc(receiverId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        if (data.containsKey('name') && data['name'] != null) {
          return data['name'];
        } else {
          // 혹시 모를 예외 상황에 대비해, 'name'이 없으면 'nickname'을 대신 보여줌
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
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFEF9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFEF9),
          elevation: 0,
          leading: IconButton(
            icon: Image.asset(
              'assets/images/mainpage/notifications.png', 
              width: screenWidth * 0.052,
              height: screenWidth * 0.052,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CalendarNotification.NotificationPage(
                        onNavigateToFriends: widget.onNavigateToFriends,
                      ),
                ),
              );
            },
          ),

          actions: [
            IconButton(
              icon: Image.asset(
                'assets/images/mainpage/setting.png',
                width: screenWidth * 0.085,
                height: screenWidth * 0.085,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8), // 오른쪽 여백이 필요할 경우 추가
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF504A4A),
            indicatorSize: TabBarIndicatorSize.tab, // 인디케이터를 탭 너비에 맞춤
            indicatorWeight: 2.0, // 선의 두께 조절
            labelColor: const Color(0xFF504A4A),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontSize: 16, // 글꼴 크기 확대
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16, // 선택되지 않은 탭도 크기 동일하게
            ),
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
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: const Color(0xFFF8F8F8),
                ),
                SizedBox(height: 16),
                Text(
                  '아직 친구가 없습니다',
                  style: TextStyle(fontSize: 17, color: Colors.grey),
                ),
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
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, idx) {
              final friend = friends[idx];
              return _FriendTile(
                name: friend.name,
                tags: friend.tags,
                tileColor: const Color(0xFFF8F8F8),
                isFavorite: friend.favorite,
                onFavoriteToggle: () => toggleFavorite(friend),
                onTap: () {},
                trailingButtons: [
                  TextButton(
                    onPressed:
                        () => _showConfirm('차단', () => blockFriend(friend)),
                    child: const Text(
                      '차단',
                      style: TextStyle(color: const Color(0xFF506497)),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => _showConfirm('삭제', () => deleteFriend(friend)),
                    child: const Text(
                      '삭제',
                      style: TextStyle(color: const Color(0xFFDA6464)),
                    ),
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
                    hintStyle: const TextStyle(
                      color: const Color(
                        0xFF9A9A9A,
                      ), // 원하는 색상으로 변경 (예: Colors.black54)
                      fontWeight: FontWeight.w500,
                      fontSize: 15, // 필요하다면 크기도 조절 가능
                    ),
                    filled: true,
                    fillColor: const Color(0xFFEDEDED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                  backgroundColor: const Color(0xFF484848),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(60, 44),
                  elevation: 0,
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
              title: const Text(
                '나랑 친구해줘!',
                style: TextStyle(
                  fontSize: 16, // 글자 크기를 더 크게 조절
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF504A4A),
                ),
              ),
              backgroundColor: const Color(0xFFFFFFEF9),
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
                        child: Center(
                          // 텍스트를 중앙에 배치하면 더 깔끔합니다.
                          child: Text(
                            '받은 친구 신청이 없습니다.',
                            style: TextStyle(
                              // --- 원하는 색상으로 변경하세요 ---
                              color: Color(0xFF9A9A9A), // 연한 회색 (추천)
                              fontSize: 15, // 글자 크기도 조절 가능
                              fontWeight: FontWeight.w500,
                              // ------------------------------
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children:
                          requests.map((request) {
                            return _FriendTile(
                              name: request.senderName,
                              tags: request.senderTags,
                              tileColor: const Color(0xFFE0EBEE),
                              isFavorite: false,
                              onFavoriteToggle: null,
                              onTap: () {},
                              tagBgColor: const Color(0xFFA9C3D4),
                              tagTextColor: const Color(0xFF504A4A),
                              trailingButtons: [
                                TextButton(
                                  onPressed: () => acceptFriendRequest(request),
                                  child: const Text(
                                    '수락',
                                    style: TextStyle(
                                      color: const Color(0xFF506497),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      () => _showConfirm(
                                        '거절',
                                        () => rejectFriendRequest(request),
                                      ),
                                  child: const Text(
                                    '거절',
                                    style: TextStyle(
                                      color: const Color(0xFFDA6464),
                                    ),
                                  ),
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
              title: const Text(
                '언제쯤 받아줄까...',
                style: TextStyle(
                  fontSize: 16, // 글자 크기를 더 크게 조절
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF504A4A),
                ),
              ),
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
                        child: Center(
                          // 텍스트를 중앙에 배치하면 더 깔끔합니다.
                          child: Text(
                            '보낸 친구 신청이 없습니다.',
                            style: TextStyle(
                              // --- 원하는 색상으로 변경하세요 ---
                              color: Color(0xFF9A9A9A), // 연한 회색 (추천)
                              fontSize: 15, // 글자 크기도 조절 가능
                              fontWeight: FontWeight.w500,
                              // ------------------------------
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children:
                          requests.map((request) {
                            return FutureBuilder<String>(
                              future: getReceiverNickName(request.receiverId),
                              builder: (context, snapshot) {
                                final receiverNickName = snapshot.data ?? '...';
                                return _FriendTile(
                                  name: receiverNickName,
                                  tags: const [],
                                  tileColor: const Color(0xFFFF6F3E7),
                                  isFavorite: false,
                                  onFavoriteToggle: null,
                                  onTap: () {},
                                  trailingButtons: [
                                    ElevatedButton(
                                      onPressed:
                                          () => cancelFriendRequest(request),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFB4A0A0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ), // 숫자가 작을수록 각진 모양이 됩니다 (기존은 완전 타원형)
                                        ),
                                        minimumSize: const Size(50, 36),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        '친구 신청 취소',
                                        style: TextStyle(color: Colors.white),
                                      ),
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
    stream: _recommendedStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final recommendedUsers = snapshot.data ?? [];

      if (recommendedUsers.isEmpty) {
        return const Center(
          child: Text('추천할 친구가 없습니다.', style: TextStyle(color: Colors.grey)),
        );
      }

      return Column(
        children: [
          const SizedBox(height: 30),

          Expanded(
            child: PageView.builder(
              controller: _pageController, 
              itemCount: recommendedUsers.length,
              itemBuilder: (context, i) {
                final user = recommendedUsers[i];

                double opacity = (1 - (i - _currentPage).abs() * 0.5).clamp(0.4, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 10,
                    ),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCF9EC),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 52,
                            color: const Color(0xFFDFD7CD),
                            alignment: Alignment.center,
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF504A4A),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          Container(
                            width: 135,
                            height: 135,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF1F1F1), width: 4),
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(user.profileImage),
                            ),
                          ),

                          const SizedBox(height: 20),

                          //타이틀 영역 높이를 고정 (타이틀 유무와 관계없이 동일한 높이 유지)
                          SizedBox(
                            height: 40, // 고정 높이 설정
                            child: user.tags.isNotEmpty
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.center,
                                    children: user.tags.map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4ECD2),
                                        border: Border.all(color: const Color(0xFF6A6A6A), width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '# $tag',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF504A4A),
                                        ),
                                      ),
                                    )).toList(),
                                  )
                                : const SizedBox.shrink(), // 타이틀이 없어도 높이는 유지
                          ),

                          const SizedBox(height: 20),
                          Container(width: 170, height: 1.2, color: const Color(0xFFB8B8B8)),
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            height: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user.bio.isNotEmpty ? user.bio : "만나서 반가워요!",
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF504A4A),
                                height: 1.3,
                              ),
                            ),
                          ),

                          const Spacer(),

                          GestureDetector(
                            onTap: () => sendFriendRequestByEmail(user.email),
                            child: Container(
                              width: 115,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB4A0A0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '친구 신청',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 25, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '옆으로 스와이프 하세요',
                  style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 13),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _refreshRecommendations,
                  child: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: Color(0xFF9A9A9A),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

  String getImagePathByCharacterId(int id) {
    switch (id) {
      case 1:
        return 'assets/images/Setting/chac4.png';
      case 2:
        return 'assets/images/Setting/chac3.png';
      case 3:
        return 'assets/images/Setting/chac2.png';
      case 4:
        return 'assets/images/Setting/chac5.png';
      case 5:
        return 'assets/images/Setting/chac7.png';
      case 6:
        return 'assets/images/Setting/chac8.png';
      case 7:
        return 'assets/images/Setting/chac1.png';
      case 8:
        return 'assets/images/Setting/chac6.png';
      default:
        return 'assets/images/profile.png'; // 기본 프로필 이미지 경로
    }
  }

  // 프로필 이미지를 판단하여 그려주는 헬퍼 함수
  Widget _buildProfileImage(String profileData) {
    // 1. 숫자인지 확인 (캐릭터 ID)
    int? charId = int.tryParse(profileData);

    if (charId != null && charId > 0) {
      return Image.asset(
        getImagePathByCharacterId(charId),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Icon(Icons.person, size: 50),
      );
    }
    // 2. URL인지 확인
    else if (profileData.isNotEmpty && profileData.startsWith('http')) {
      return Image.network(
        profileData,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Icon(Icons.person, size: 50),
      );
    }
    // 3. 기본 아이콘
    else {
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }
  }

  void _showConfirm(String action, VoidCallback onOk) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder:
          (BuildContext dialogContext) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '정말 $action 하시겠습니까?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          minimumSize: const Size(100, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '네',
                          style: TextStyle(color: Colors.red),
                        ),
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
      builder:
          (BuildContext dialogContext) => AlertDialog(
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
    final tagBackground = tagBgColor ?? const Color(0xFFF4ECD2);
    final tagText = tagTextColor ?? const Color(0xFF504A4A);

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
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onFavoriteToggle != null) ...[
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Image.asset(
                      isFavorite
                          ? 'assets/images/friendScreen/star_on.png'
                          : 'assets/images/friendScreen/star_off.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF504A4A),
                    ),
                  ),
                ),
                ...trailingButtons, // 버튼들을 이름 옆에 배치
              ],
            ),

            if (tags.isNotEmpty) ...[
              const SizedBox(height: 0), // 이름과 태그 사이 간격
              Padding(
                padding: EdgeInsets.only(
                  left: onFavoriteToggle != null ? 44 : 0, // 별이 있으면 들여쓰기
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagBackground,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 13,
                              color: tagText,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
