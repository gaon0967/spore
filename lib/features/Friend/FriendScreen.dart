
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:spore/features/Friend/friend_management.dart';
import '../Psychology/PsychologyResult.dart';
import 'ChatScreen.dart';
import '../Calendar/Notification.dart' as CalendarNotification;
import '../Settings/settings_screen.dart';
import 'dart:async';
import 'dart:math';
import '../Settings/TitleHandler.dart';
import 'email_verification_service.dart';

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

  //가령: email 추가및 삭제를 위한 코드 (250319)
  bool _hasEmail = true;
  StreamSubscription<DocumentSnapshot>? _emailSubscription;
  final TextEditingController _verifyEmailCtrl = TextEditingController();
  final TextEditingController _verifyCodeCtrl = TextEditingController();
  bool _codeSent = false;
  bool _isSendingCode = false;
  bool _isVerifying = false;

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
    _listenEmailStatus();
  }

  //가령: email 추가및 삭제를 위한 코드 (250319)
  void _listenEmailStatus() {
    if (currentUserId == null) return;
    _emailSubscription = _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data();
      final email = data?['email'] as String? ?? '';
      setState(() {
        _hasEmail = email.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _emailSubscription?.cancel();
    _pageController.dispose();
    _emailCtrl.dispose();
    _verifyEmailCtrl.dispose();
    _verifyCodeCtrl.dispose();
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
        final data = userDoc.data();
        setState(() {
          _recommendationsEnabled = data?['recommend'] ?? true;
          //가령: email 추가및 삭제를 위한 코드 (250319)
          final email = data?['email'] as String? ?? '';
          _hasEmail = email.isNotEmpty;
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
  // 추천 친구 가져오기 (신청 중인 유저 제외 로직 추가)
  Stream<List<RecommendedUser>> get recommendedUsersStream {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .where('recommend', isEqualTo: true)
        .limit(30) // 필터링을 고려해 조금 더 넉넉히 가져옴
        .snapshots()
        .asyncMap((snapshot) async {
          List<RecommendedUser> recommended = [];
          Set<String> excludedIds = {}; // 제외할 UID 목록 (친구 + 이미 신청 보낸 대상)

          try {
            // 1. 이미 친구인 사람들 가져오기
            final friendsSnapshot = await _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('friends')
                .get();
            for (var doc in friendsSnapshot.docs) {
              excludedIds.add(doc.data()['friendId'] as String);
            }

            // 2. 내가 이미 친구 신청을 보낸 사람들 가져오기 (추가된 로직)
            final sentRequestsSnapshot = await _firestore
                .collection('friendRequests')
                .where('senderId', isEqualTo: currentUserId)
                .get();
            for (var doc in sentRequestsSnapshot.docs) {
              excludedIds.add(doc.data()['receiverId'] as String);
            }
          } catch (e) {
            print('목록 필터링 조회 오류: $e');
          }

          // 3. 필터링 수행
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final email = data['email'] as String? ?? '';
            // 나 자신, 친구, 신청 대기 중, 이메일 없는 유저 제외
            if (doc.id != currentUserId &&
                !excludedIds.contains(doc.id) &&
                email.isNotEmpty) {
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
  final String myUid = currentUserId ?? "";
  if (myUid.isEmpty) return;

  // 1. 입력값 정제 (공백 제거 및 소문자화)
  final String cleanTargetEmail = receiverEmail.trim().toLowerCase();
  final String myEmail = (_auth.currentUser?.email ?? "").trim().toLowerCase();

  // 2. [1차 차단] 내 이메일과 입력한 이메일 문자열 비교
  if (cleanTargetEmail == myEmail) {
    if (mounted) {
      _showAlert('자신에게는 친구 신청을\n할 수 없습니다.');
    }
    return;
  }

  try {
    // 3. Firestore에서 상대방 찾기 (정제된 cleanTargetEmail 사용)
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanTargetEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      if (mounted) {
        _showAlert('해당 이메일의 사용자를\n찾을 수 없습니다.');
      }
      return;
    }

    final targetUserDoc = userQuery.docs.first;
    final String receiverId = targetUserDoc.id; // 상대방 UID
    final receiverData = targetUserDoc.data();

    // 4. [2차 차단] 찾은 사용자의 UID가 내 UID와 같은지 확인 (가장 확실함)
    if (receiverId == myUid) {
      if (mounted) {
        _showAlert('자신에게는 친구 신청을\n할 수 없습니다.');
      }
      return;
    }

    // 5. 이미 친구인지 확인
    final friendDoc = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(receiverId)
        .get();
    
    if (friendDoc.exists) {
      if (mounted) {
        _showAlert('이미 친구입니다.');
      }
      return;
    }

    // 6. 이미 신청을 보냈는지 확인
    final existingRequest = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: myUid)
        .where('receiverId', isEqualTo: receiverId)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      if (mounted) {
        _showAlert('이미 친구 신청을 보냈습니다.');
      }
      return;
    }

    // 7. 모든 검사를 통과한 경우 실제 신청서 생성
    final currentUserDoc = await _firestore.collection('users').doc(myUid).get();
    final currentUserData = currentUserDoc.data()!;

    await _firestore.collection('friendRequests').add({
      'senderId': myUid,
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
    if (mounted) {
      _showAlert('친구 신청 중 오류가 발생했습니다: $e');
    }
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
              height: screenHeight * 0.024235848,
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
                height: screenHeight*0.03961629,
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
            SizedBox(width: screenWidth * 0.01944), // 오른쪽 여백이 필요할 경우 추가
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF504A4A),
            indicatorSize: TabBarIndicatorSize.tab, // 인디케이터를 탭 너비에 맞춤
            indicatorWeight: 2.0, // 선의 두께 조절
            labelColor: const Color(0xFF504A4A),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(
              fontSize: screenWidth*0.03888, // 글꼴 크기 확대
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: screenWidth*0.03888, // 선택되지 않은 탭도 크기 동일하게
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
        //가령: email 추가및 삭제를 위한 코드 (250319)
        body: TabBarView(
          children: _hasEmail
              ? [
                  _buildFriendList(),
                  _buildRequestList(),
                  _buildRecommendationSlider(),
                ]
              : [
                  _emailVerification(),
                  _emailVerification(),
                  _emailVerification(),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: MediaQuery.of(context).size.width * 0.15552,
                  color: const Color(0xFFF8F8F8),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.018144),
                Text(
                  '아직 친구가 없습니다',
                  style: TextStyle(fontSize: MediaQuery.of(context).size.width *0.04131, color: Colors.grey),
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
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            itemCount: friends.length,
            separatorBuilder: (_, __) => SizedBox(height: MediaQuery.of(context).size.height * 0.004536),
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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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
                    hintStyle: TextStyle(
                      color: const Color(
                        0xFF9A9A9A,
                      ), // 원하는 색상으로 변경 (예: Colors.black54)
                      fontWeight: FontWeight.w500,
                      fontSize: MediaQuery.of(context).size.width * 0.03645, // 필요하다면 크기도 조절 가능
                    ),
                    filled: true,
                    fillColor: const Color(0xFFEDEDED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03888,
                      vertical: MediaQuery.of(context).size.height * 0.006804,
                    ),
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01944),
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
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.1458, 
                      MediaQuery.of(context).size.height * 0.049896),
                  elevation: 0,
                ),
                child: const Text('추가', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.027216),
          // 받은 친구 신청
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: widget.expandRequestsSection,
              title: Text(
                '나랑 친구해줘!',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.03888, // 글자 크기를 더 크게 조절
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
                      return Padding(
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                        child: Center(
                          child: Text(
                            '받은 친구 신청이 없습니다.',
                            style: TextStyle(
                              color: Color(0xFF9A9A9A),
                              fontSize: MediaQuery.of(context).size.width * 0.03645,
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
          Divider(height: MediaQuery.of(context).size.height * 0.036288, thickness: 1),
          // 보낸 친구 신청
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text(
                '언제쯤 받아줄까...',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.03888, // 글자 크기를 더 크게 조절
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF504A4A),
                ),
              ),
              backgroundColor: const Color(0xFFFFFFEF9),
              children: [
                StreamBuilder<List<FriendRequest>>(
                  stream: outgoingRequestsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final requests = snapshot.data ?? [];
                    if (requests.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                        child: Center(
                          child: Text(
                            '보낸 친구 신청이 없습니다.',
                            style: TextStyle(
                              color: Color(0xFF9A9A9A), 
                              fontSize: MediaQuery.of(context).size.width * 0.03645,
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
                                        minimumSize: Size(MediaQuery.of(context).size.width * 0.1215, 
                                            MediaQuery.of(context).size.height * 0.040824),
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
    // 현재 사용자의 recommend 설정을 먼저 확인___ 이번에 추가한거 가령 (1/15)
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 현재 사용자의 recommend 값 확인 (기본값: true)
        bool isRecommendEnabled = true;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          isRecommendEnabled = userData?['recommend'] ?? true;
        }

        // recommend가 false이면 비활성화 메시지 표시
        if (!isRecommendEnabled) {
          return _buildDisabledRecommendationCard();
        }

        // recommend가 true이면 기존 추천 친구 목록 표시
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

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                return Column(
                  children: [
                    SizedBox(height: screenHeight * 0.08),

                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: recommendedUsers.length,
                        itemBuilder: (context, i) {
                          final user = recommendedUsers[i];

                          double opacity = (1 - (i - _currentPage).abs() * 0.5).clamp(0.4, 1.0);

                          return Opacity(
                            opacity: opacity,
                            child: Center(
                              child: Container(
                                width: screenWidth * (290 / 411),
                                height: screenHeight * (370 / 507), // 이거 따라서 많이 변하니까 주의 
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCF9EC),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, cardConstraints) {
                                    final cardWidth = cardConstraints.maxWidth;
                                    final cardHeight = cardConstraints.maxHeight;

                                    return Column(
                                      children: [
                                        // 헤더 (이름) - 56/414
                                        Container(
                                          width: double.infinity,
                                          height: cardHeight * (56 / 414),
                                          color: const Color(0xFFDFD7CD),
                                          alignment: Alignment.center,
                                          child: Text(
                                            user.name,
                                            style: TextStyle(
                                              fontSize: cardWidth * (20 / 290),
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF504A4A),
                                            ),
                                          ),
                                        ),

                                        // 프로필 이미지 영역 - (239-172-56)/414 = 11/414 간격 후
                                        SizedBox(height: cardHeight * (11 / 414)),

                                        // 프로필 이미지 - 150x150
                                        Container(
                                          width: cardWidth * (150 / 290),
                                          height: cardWidth * (150 / 290),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFFF1F1F1), width: 3),
                                            color: Colors.white,
                                          ),
                                          child: ClipOval(
                                            child: _buildProfileImage(user.profileImage),
                                          ),
                                        ),

                                        // 프로필과 구분선 사이 간격
                                        SizedBox(height: cardHeight * (12 / 414)),

                                        // 구분선 - 211px 너비
                                        Container(
                                          width: cardWidth * (211 / 290),
                                          height: 1,
                                          color: const Color(0xFFB8B8B8),
                                        ),

                                        // 구분선과 태그 사이 간격
                                        SizedBox(height: cardHeight * (13 / 414)),

                                        // 태그 영역
                                        SizedBox(
                                          height: cardHeight * (30 / 414),
                                          child: user.tags.isNotEmpty
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: user.tags.map((tag) => Container(
                                                    margin: EdgeInsets.symmetric(horizontal: cardWidth * (4 / 290)),
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: cardWidth * (10 / 290),
                                                      vertical: cardHeight * (5 / 414),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF4ECD2),
                                                      border: Border.all(color: const Color(0xFF6A6A6A), width: 1.2),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      '# $tag',
                                                      style: TextStyle(
                                                        fontSize: cardWidth * (15 / 290),
                                                        fontWeight: FontWeight.w500,
                                                        color: const Color(0xFF504A4A),
                                                      ),
                                                    ),
                                                  )).toList(),
                                                )
                                              : const SizedBox.shrink(),
                                        ),

                                        // 태그와 소개글 사이 간격
                                        SizedBox(height: cardHeight * (10 / 414)),

                                        // 소개글 박스 - 270x65
                                        Container(
                                          width: cardWidth * (270 / 290),
                                          height: cardHeight * (65 / 414),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEBEBEB),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          padding: EdgeInsets.symmetric(horizontal: cardWidth * (10 / 290)),
                                          child: Text(
                                            user.bio.isNotEmpty ? user.bio : "만나서 반가워요!",
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: cardWidth * (14 / 290),
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF504A4A),
                                            ),
                                          ),
                                        ),

                                        // 소개글과 버튼 사이 간격
                                        SizedBox(height: cardHeight * (15 / 414)),

                                        // 친구 신청 버튼 - 117x38
                                        GestureDetector(
                                          onTap: () => sendFriendRequestByEmail(user.email),
                                          child: Container(
                                            width: cardWidth * (117 / 290),
                                            height: cardHeight * (38 / 414),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFB4A0A0),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '친구 신청',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: cardWidth * (15 / 290),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 하단 안내 텍스트
                    Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.05),
                      child: Text(
                        '옆으로 스와이프 하세요',
                        style: TextStyle(
                          color: const Color(0xFF9A9A9A),
                          fontSize: screenWidth * (14 / 411),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // 추천 친구 비활성화 상태 UI (1/16)

  Widget _buildDisabledRecommendationCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 반응형 크기 계산 (기준: 290x414)
        final double cardWidth = constraints.maxWidth * 0.75;
        final double cardHeight = cardWidth * (414 / 290);
        final double innerBoxSize = cardWidth * (230 / 290);

        // 반응형 값들
        final double outerRadius = cardWidth * (24 / 290);
        final double innerRadius = cardWidth * (20 / 290);
        final double fontSize = cardWidth * (15 / 290);
        final double textSpacing = cardWidth * (4 / 290);

        return Center(
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6EC),
              borderRadius: BorderRadius.circular(outerRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: innerBoxSize,
                  height: innerBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '추천친구가 비활성화 상태입니다.',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: const Color(0xFF6B6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: textSpacing),
                      Text(
                        '설정에서 활성화 할 수 있습니다.',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: const Color(0xFF6B6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  //가령: email 추가및 삭제를 위한 코드 (250319)
  // 이메일이 설정되어 있지 않은 경우 이메일 인증 후 등록
  Widget _emailVerification() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth * 0.75;
        final double cardHeight = cardWidth * (320 / 290);

        final double outerRadius = cardWidth * (20 / 290);
        final double innerRadius = cardWidth * (7 / 290);
        final double fontSize = cardWidth * (14 / 290);
        final double fieldHeight = cardHeight * 0.12;
        final double requestButtonHeight = cardHeight * 0.08;
        final double confirmButtonHeight = cardHeight * 0.12;

        return Center(
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6EC),
              borderRadius: BorderRadius.circular(outerRadius),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: cardWidth * (22 / 290),
              vertical: cardHeight * 0.08,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: cardHeight * 0.03),

                Align(
                  alignment: Alignment.center,
                  child: Text(
                    _codeSent
                        ? '인증번호가 발송되었습니다.\n이메일을 확인해주세요.'
                        : '이메일이 존재하지 않습니다.\n친구 기능을 활성화할 수 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: const Color(0xFF504A4A),
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),

                SizedBox(height: cardHeight * 0.13),

                Text(
                  'e-mail',
                  style: TextStyle(
                    fontSize: fontSize * 0.85,
                    color: const Color(0xFF504A4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: cardHeight * 0.01),

                // 이메일 입력 칸
                SizedBox(
                  height: fieldHeight,
                  child: TextField(
                    controller: _verifyEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_codeSent,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: cardWidth * 0.04,
                        vertical: cardHeight * 0.035,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(innerRadius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: cardHeight * 0.02),

                // 인증번호 받기 버튼
                SizedBox(
                  width: double.infinity,
                  height: requestButtonHeight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(innerRadius),
                      onTap: _isSendingCode
                          ? null
                          : () async {
                              final email = _verifyEmailCtrl.text.trim();
                              if (email.isEmpty) {
                                _showAlert('이메일을 입력해주세요.');
                                return;
                              }
                              setState(() => _isSendingCode = true);
                              try {
                                await EmailVerificationService.sendCode(email);
                                if (mounted) {
                                  setState(() {
                                    _codeSent = true;
                                    _isSendingCode = false;
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _isSendingCode = false);
                                  _showAlert(e.toString().contains('already-exists')
                                      ? '이미 사용 중인 이메일입니다.'
                                      : '인증번호 발송에 실패했습니다.');
                                }
                              }
                            },
                      child: Ink(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0EBEE),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Center(
                          child: _isSendingCode
                              ? SizedBox(
                                  width: fontSize,
                                  height: fontSize,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _codeSent ? '인증번호 재발송' : '인증번호 받기',
                                  style: TextStyle(
                                    fontSize: fontSize * 0.77,
                                    color: const Color(0xFF504A4A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: cardHeight * 0.05),

                // 인증번호 입력 칸
                Text(
                  '인증번호 입력',
                  style: TextStyle(
                    fontSize: fontSize * 0.77,
                    color: const Color(0xFF504A4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: cardHeight * 0.01),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: fieldHeight,
                        child: TextField(
                          controller: _verifyCodeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFFFFFFF),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: cardWidth * 0.04,
                              vertical: cardHeight * 0.028,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(innerRadius),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: cardWidth * 0.03),

                    // 확인 버튼
                    SizedBox(
                      width: cardWidth * 0.22,
                      height: confirmButtonHeight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(innerRadius),
                          onTap: _isVerifying
                              ? null
                              : () async {
                                  final code = _verifyCodeCtrl.text.trim();
                                  if (code.isEmpty) {
                                    _showAlert('인증번호를 입력해주세요.');
                                    return;
                                  }
                                  setState(() => _isVerifying = true);
                                  try {
                                    await EmailVerificationService.verifyCode(code);
                                    if (mounted) {
                                      setState(() {
                                        _hasEmail = true;
                                        _isVerifying = false;
                                        _codeSent = false;
                                      });
                                      _verifyEmailCtrl.clear();
                                      _verifyCodeCtrl.clear();
                                      _showAlert('이메일이 등록되었습니다.');
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isVerifying = false);
                                      String msg = '인증에 실패했습니다.';
                                      if (e.toString().contains('permission-denied')) {
                                        msg = '인증번호가 일치하지 않습니다.';
                                      } else if (e.toString().contains('deadline-exceeded')) {
                                        msg = '인증번호가 만료되었습니다.';
                                      }
                                      _showAlert(msg);
                                    }
                                  }
                                },
                          child: Ink(
                            decoration: BoxDecoration(
                              color: const Color(0xFFA9C3D4),
                              borderRadius: BorderRadius.circular(innerRadius),
                            ),
                            child: Center(
                              child: _isVerifying
                                  ? SizedBox(
                                      width: fontSize,
                                      height: fontSize,
                                      child: const CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      '확인',
                                      style: TextStyle(
                                        fontSize: fontSize * 0.85,
                                        color: const Color(0xFF504A4A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
            (context, error, stackTrace) => Icon(Icons.person, size: MediaQuery.of(context).size.width * 0.0567 ),
      );
    }
    // 2. URL인지 확인
    else if (profileData.isNotEmpty && profileData.startsWith('http')) {
      return Image.network(
        profileData,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Icon(Icons.person, size: MediaQuery.of(context).size.width * 0.0567 ),
      );
    }
    // 3. 기본 아이콘
    else {
      return Icon(Icons.person, size: MediaQuery.of(context).size.width * 0.06804, color: Colors.grey);
    }
  }

  void _showConfirm(String action, VoidCallback onOk) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // 배경을 아주 살짝 어둡게
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent, // 배경을 투명하게 하고 내부 Container에서 디자인 적용
        elevation: 0,
        child: Container(
          width: screenWidth*0.72414,
          height: screenHeight*0.202986,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFF9), // CSS: background: #FFFFF9
            border: Border.all(color: const Color(0xFFE5E5E5), width: 1), // border: 1px solid #E5E5E5
            borderRadius: BorderRadius.circular(10), // border-radius: 10px
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06), // rgba(0, 0, 0, 0.06)
                offset: const Offset(1, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 메시지 영역 (Rectangle 45 텍스트 공간)
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal:screenWidth*0.0486),
                  child: Text(
                    '정말 $action 하시겠습니까?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w500, 
                      fontSize: screenWidth*0.0388, 
                      height: 1.2,
                      color: const Color(0xFF716969),
                    ),
                  ),
                ),
              ),
              // 하단 버튼 구분선 및 버튼 영역 (Subtract 부분)
              Container(
                height: screenHeight*0.053298, // height: 47px
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // '아니오' 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                            ),
                          ),
                          child: Text(
                            '아니오',
                            style: TextStyle(
                              fontFamily: 'Golos Text',
                              fontWeight: FontWeight.w400,
                              fontSize: screenWidth*0.0388,
                              color: const Color(0xFF635E5E), // color: #635E5E
                            ),
                          ),
                        ),
                      ),
                    ),
                    // '네' 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          onOk();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            '네',
                            style: TextStyle(
                              fontFamily: 'Golos Text',
                              fontWeight: FontWeight.w400,
                              fontSize: screenWidth*0.0388,
                              color: const Color(0xFF2F3BDC), // color: #2F3BDC
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlert(String message) {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double scale = screenWidth / 411;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          // CSS: Rectangle 45 & 137 기반 수치 (298x179)
          width: screenWidth*0.72414,
          height: screenHeight*0.202986,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFF9), // CSS: #FFFFF9
            border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(1, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // 상단 메시지 영역
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth*0.02268),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontWeight: FontWeight.w500, 
                      fontSize: screenWidth*0.03645,
                      height: screenHeight*0.0015876,
                      color: const Color(0xFF716969), 
                    ),
                  ),
                ),
              ),
              // 하단 '확인' 버튼 영역 (Subtract 부분)
              GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: screenHeight*0.053298, 
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontWeight: FontWeight.w500,
                      fontSize: screenWidth*0.03645,
                      color: const Color(0xFF2F3BDC), // '네' 버튼과 동일한 강조색
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.006804),
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03888, vertical: MediaQuery.of(context).size.height * 0.01134),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(20),
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
                      width: MediaQuery.of(context).size.width * 0.0486,
                      height: MediaQuery.of(context).size.height*0.0226,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05346),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.03888,
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
                  spacing: MediaQuery.of(context).size.width * 0.01458,
                  runSpacing: MediaQuery.of(context).size.width*0.00972,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding:EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.007938,
                            vertical: MediaQuery.of(context).size.height * 0.003402,
                          ),
                          decoration: BoxDecoration(
                            color: tagBackground,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.030375,
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
