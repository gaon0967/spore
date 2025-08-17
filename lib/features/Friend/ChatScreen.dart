// lib/features/Friend/ChatScreen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Psychology/PsychologyResult.dart';

/// 채팅 메시지 데이터 클래스 (Firebase ERD 구조 + 보안 규칙 준수)
class ChatMessage {
  final String senderId;
  final String receiverId;
  final String content;
  final Timestamp timestamp;
  final String messageId;

  const ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.messageId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      messageId: doc.id,
    );
  }

  Map<String, dynamic> toFirestore(String currentUserId) {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'uid': currentUserId, // 🔑 보안 규칙 준수 - 메시지를 작성한 사용자의 uid
    };
  }

  // 내가 보낸 메시지인지 확인
  bool isMine(String currentUserId) => senderId == currentUserId;
}

/// ChatScreen 위젯: Character 객체를 받아 해당 캐릭터와 채팅을 주고받습니다.
class ChatScreen extends StatefulWidget {
  final Character character;
  final String? friendId; // 실제 친구의 Firebase UID

  const ChatScreen({
    required this.character,
    this.friendId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? get currentUserId => _auth.currentUser?.uid;
  String? get friendId => widget.friendId;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 메시지 스트림 - 내 메시지 컬렉션만 조회 (보안 규칙 준수)
  Stream<List<ChatMessage>> get messagesStream {
    if (currentUserId == null || friendId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromFirestore(doc))
        .toList());
  }

  // 메시지 보내기 (보안 규칙 준수)
  Future<void> _sendMessage(String content) async {
    if (currentUserId == null || friendId == null || content.trim().isEmpty) {
      return;
    }

    try {
      final timestamp = FieldValue.serverTimestamp();

      // 🔄 내 메시지함에만 저장 (내 uid로)
      final messageData = {
        'senderId': currentUserId,
        'receiverId': friendId,
        'content': content.trim(),
        'timestamp': timestamp,
        'uid': currentUserId, // 🔑 보안 규칙 준수
      };

      // 내 메시지함에 저장
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .collection('messages')
          .add(messageData);

      // 🆕 상대방에게 메시지 전달을 위한 별도 컬렉션 사용
      // 상대방 문서에 직접 접근하지 않고, 중간 컬렉션 활용
      await _firestore.collection('messageQueue').add({
        'fromUserId': currentUserId,
        'toUserId': friendId,
        'content': content.trim(),
        'timestamp': timestamp,
        'uid': currentUserId, // 메시지를 보낸 사람의 uid
        'processed': false, // Cloud Function에서 처리할 플래그
      });

      // 메시지 전송 후 스크롤을 아래로
      _scrollToBottom();

    } catch (e) {
      _showError('메시지 전송에 실패했습니다: $e');
      print('메시지 전송 오류: $e');
    }
  }

  // 친구 정보 가져오기 (권한 확인 후)
  Future<Map<String, dynamic>?> _getFriendInfo() async {
    if (friendId == null) return null;

    try {
      final friendDoc = await _firestore.collection('users').doc(friendId).get();

      if (friendDoc.exists) {
        final userData = friendDoc.data();
        // 🔑 uid 필드가 있는 경우만 정보 반환 (읽기 권한 확인)
        if (userData != null && userData.containsKey('uid')) {
          return userData;
        }
      }
      return null;
    } catch (e) {
      print('친구 정보 가져오기 오류: $e');
      return null;
    }
  }

  // 스크롤을 가장 아래로
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    _sendMessage(text);
    _ctrl.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 시간 포맷팅
  String _formatTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // 로그인하지 않은 경우
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('채팅')),
        body: const Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    // friendId가 없는 경우 (캐릭터 채팅)
    if (friendId == null) {
      return _buildCharacterChat(w);
    }

    // 실제 친구와의 채팅
    return _buildRealFriendChat(w);
  }

  // 실제 친구와의 채팅 화면
  Widget _buildRealFriendChat(double w) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _getFriendInfo(),
          builder: (context, snapshot) {
            final friendData = snapshot.data;
            final friendName = friendData?['nickName'] ?? widget.character.name;
            final profileImage = friendData?['profileImage'] ?? '';

            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 18,
                  child: profileImage.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      profileImage,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.grey);
                      },
                    ),
                  )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Text(
                  friendName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // 친구 정보 보기 (필요시 구현)
              _showFriendInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🆕 메시지 동기화 안내
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '메시지는 실시간으로 동기화됩니다.',
                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text('오류: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('아직 대화가 없습니다', style: TextStyle(color: Colors.grey)),
                        Text('첫 메시지를 보내보세요!', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 메시지가 업데이트될 때마다 스크롤을 아래로
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final message = messages[idx];
                    final isMine = message.isMine(currentUserId!);
                    final showTime = idx == messages.length - 1 ||
                        (idx < messages.length - 1 &&
                            messages[idx + 1].timestamp.toDate().difference(
                                message.timestamp.toDate()).inMinutes > 5);

                    return Column(
                      children: [
                        Align(
                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: w * 0.75),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? const Color(0xFF007AFF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(
                                fontSize: w * 0.042,
                                color: isMine ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        if (showTime)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: w * 0.03,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: "메시지 보내기",
                      fillColor: const Color(0xFFF6F6F6),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 친구 정보 표시
  void _showFriendInfo() {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
        future: _getFriendInfo(),
        builder: (context, snapshot) {
          final friendData = snapshot.data;
          final friendName = friendData?['nickName'] ?? '알 수 없음';
          final profileImage = friendData?['profileImage'] ?? '';

          return AlertDialog(
            title: const Text('친구 정보'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 30,
                  child: profileImage.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      profileImage,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.grey, size: 30);
                      },
                    ),
                  )
                      : const Icon(Icons.person, color: Colors.grey, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  friendName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (friendData?['bio'] != null && friendData!['bio'].isNotEmpty)
                  Text(
                    friendData['bio'],
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 캐릭터와의 가상 채팅 화면 (기존 방식)
  Widget _buildCharacterChat(double w) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.character.imagePath),
              backgroundColor: Colors.grey[300],
              radius: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.character.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  '가상 캐릭터',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.character.name}와의 가상 대화입니다. 실제 사용자와 연결하려면 친구를 추가하세요.',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(widget.character.imagePath),
                    radius: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.character.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.character.speech,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('친구 추가하러 가기', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}