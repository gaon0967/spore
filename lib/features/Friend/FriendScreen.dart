// lib/features/Friend/friend_screen.dart

import 'package:flutter/material.dart';
import 'package:new_project_1/features/Friend/friend_management.dart';
import '../Psychology/PsychologyResult.dart'; // Character 모델
import 'ChatScreen.dart';                     // ChatScreen 위젯
import '../Calendar/Notification.dart' as CalendarNotification; // 별칭 import
import '../Settings/settings_screen.dart';
// 친구 수 카운트 하고, 그에 따른 타이틀을 지급하기 위해 추가했습니다~ -현주-
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_project_1/features/Settings/firebase_title.dart' as TitlesRemote;


class Friend {
  final String name;
  final List<String> tags;
  final int characterId;
  const Friend({
    required this.name,
    this.tags = const [],
    required this.characterId,
  });
}

class FriendRequest {
  final String name;
  final List<String> tags;
  final int characterId;
  const FriendRequest({
    required this.name,
    this.tags = const [],
    required this.characterId,
  });
}

class FriendRecommendation {
  final String name;
  final List<String> tags;
  final int characterId;
  const FriendRecommendation({
    required this.name,
    this.tags = const [],
    required this.characterId,
  });
}

class FriendScreen extends StatefulWidget {
  final Function(Character)? onShowProfile;
  const FriendScreen({Key? key, this.onShowProfile}) : super(key: key);

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}
//
class _FriendScreenState extends State<FriendScreen> {
  final List<Friend> _friends = [
    const Friend(name: '가부기', tags: ['유일무이', '집순이'], characterId: 4),
    const Friend(name: '햄부기', tags: ['유일무이', '소심이'], characterId: 6),
    const Friend(name: '돼콩이', tags: ['맛잘알', '소포어의 식구'], characterId: 5),
    const Friend(name: '오덴세', tags: ['인싸', '스포어의 비기너'], characterId: 2),
  ];
  final Set<int> _favorites = {};
  final List<FriendRequest> _incoming = [
    const FriendRequest(name: '리바이', tags: ['소심마', '집들이'], characterId: 3),
    const FriendRequest(name: '김고양', tags: ['신비주의', '집순이'], characterId: 8),
  ];
  final List<FriendRequest> _outgoing = [
    const FriendRequest(name: '김고양', tags: ['신비주의', '집순이'], characterId: 8),
  ];
  List<int> _virtualIds = [4, 2, 6];
  final TextEditingController _codeCtrl = TextEditingController();

  String _getProfileImagePath(int characterId) {
    return 'assets/images/Setting/chac$characterId.png';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final friend = _friends[idx];
        final isFavorite = _favorites.contains(idx);
        return _FriendTile(
          name: friend.name,
          tags: friend.tags,
          tileColor: Colors.grey.shade50,
          isFavorite: isFavorite,
          onFavoriteToggle: () => setState(() {
            isFavorite ? _favorites.remove(idx) : _favorites.add(idx);
          }),
          onTap: () {
            final character = Character.getCharacterById(friend.characterId);
            if (widget.onShowProfile != null) {
              widget.onShowProfile!(character);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendProfileScreen(character: character),
                ),
              );
            }
          },
          trailingButtons: [
            TextButton(
              onPressed: () => _showConfirm('차단', () => setState(() => _friends.removeAt(idx))),
              child: const Text('차단', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => _showConfirm('삭제', () => setState(() => _friends.removeAt(idx))),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
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
                  controller: _codeCtrl,
                  decoration: InputDecoration(
                    hintText: '친구 코드로 추가',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final code = _codeCtrl.text.trim();
                  if (code.isNotEmpty) {
                    setState(() {
                      _outgoing.add(FriendRequest(name: code, tags: const [], characterId: 1));
                    });
                    _codeCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('[$code]님께 요청을 보냈습니다.')));
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
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('나랑 친구해줘!', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              children: _incoming.map((request) {
                return _FriendTile(
                  name: request.name,
                  tags: request.tags,
                  tileColor: const Color(0xFFE8F0FE),
                  isFavorite: false,
                  onFavoriteToggle: null,
                  onTap: () {
                    final character = Character.getCharacterById(request.characterId);
                    if (widget.onShowProfile != null) {
                      widget.onShowProfile!(character);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FriendProfileScreen(character: character)),
                      );
                    }
                  },
                  tagBgColor: const Color(0xFFD0E4FF),
                  tagTextColor: const Color(0xFF0066CC),
                  trailingButtons: [
                    TextButton(
                      onPressed: () async{ // await 사용하기 위해 async 추가했어용 -현주-
                  if (_friends.any((f) => f.name == request.name)) {
                    _showAlert('이미 친구 목록에 있습니다.');
                  } else {
                    setState(() {
                      _friends.add(Friend(name: request.name,
                          tags: request.tags,
                          characterId: request.characterId));
                      _incoming.remove(request);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${request
                            .name}님과 친구가 되었습니다!')));

                    // Firestore에서 친구 수 계산 -현주-
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('friends')
                          .doc(request.name)  // 또는 UID 기반이면 uid
                          .set({
                        'name': request.name,
                        'characterId': request.characterId,
                        'tags': request.tags,
                        'blockStatus': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      final snapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('friends')
                          .where('blockStatus', isEqualTo: false)
                          .get();

                      // Firestore 연동 타이틀 지급
                      final count = snapshot.docs.length;
                      final awarded = await TitlesRemote.handleFriendCount(
                          count);

                      if (awarded.isNotEmpty) {
                        final names = awarded.map((t) => t.name).join(', ');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('타이틀 획득: $names')),
                        );
                        // 타이틀 지급 함수 호출

                      }
                    }
                  }
                },
                      child: const Text('수락', style: TextStyle(color: Colors.green)),
                    ),
                    TextButton(
                      onPressed: () => _showConfirm('거절', () => setState(() => _incoming.remove(request))),
                      child: const Text('거절', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const Divider(height: 32, thickness: 1),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('언제쯤 받아줄까...', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              children: _outgoing.map((request) {
                return _FriendTile(
                  name: request.name,
                  tags: request.tags,
                  tileColor: const Color(0xFFFBF5EB),
                  isFavorite: false,
                  onFavoriteToggle: null,
                  onTap: () {},
                  trailingButtons: [
                    ElevatedButton(
                      onPressed: () => setState(() => _outgoing.remove(request)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(100, 36),
                      ),
                      child: const Text('친구 신청 취소', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSlider() {
    if (_virtualIds.isEmpty) {
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
        Expanded(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: _virtualIds.length,
            itemBuilder: (context, i) {
              final character = Character.getCharacterById(_virtualIds[i]);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF7EFE6), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.brown[100]!, width: 3), color: Colors.white),
                        child: ClipOval(
                          child: Transform.translate(
                            offset: const Offset(0, -10),
                            child: Image.asset(_getProfileImagePath(_virtualIds[i]), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/friendScreen/star_on.png', width: 20, height: 20),
                          const SizedBox(width: 6),
                          Text(character.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: character.keywords
                            .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text('#$tag', style: const TextStyle(fontSize: 13, color: Colors.brown)),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                        child: Text(character.speech, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_outgoing.any((r) => r.name == character.name)) {
                            _showAlert('이미 신청 목록에 있습니다.');
                          } else if (_friends.any((f) => f.name == character.name)) {
                            _showAlert('이미 친구 목록에 있습니다.');
                          } else {
                            setState(() {
                              _outgoing.add(FriendRequest(name: character.name, tags: character.keywords, characterId: character.id));
                              _virtualIds.remove(character.id);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${character.name}님께 요청했습니다.')));
                          }
                        },
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
        if (_virtualIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('옆으로 스와이프 하세요', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
        ],
      ],
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('정말 $action 하시겠습니까?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(backgroundColor: Colors.grey.shade200, minimumSize: const Size(100, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('아니요'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onOk();
                },
                style: TextButton.styleFrom(backgroundColor: Colors.red.shade50, minimumSize: const Size(100, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('네', style: TextStyle(color: Colors.red)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))
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
        decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            if (onFavoriteToggle != null) ...[
              GestureDetector(
                onTap: onFavoriteToggle,
                child: Image.asset(isFavorite ? 'assets/images/friendScreen/star_on.png' : 'assets/images/friendScreen/star_off.png', width: 24, height: 24),
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
                    ))
                        .toList(),
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

class FriendProfileScreen extends StatelessWidget {
  final Character character;
  final VoidCallback? onBack;

  const FriendProfileScreen({required this.character, this.onBack, Key? key}) : super(key: key);

  String _getProfileImagePath(int characterId) => 'assets/images/Setting/chac$characterId.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
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
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ClipOval(
                          child: Transform.scale(scale: 0.8, child: Image.asset(_getProfileImagePath(character.id), fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/friendScreen/star_on.png', width: 20, height: 20),
                        const SizedBox(width: 8),
                        Text(character.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFFFF9E6), borderRadius: BorderRadius.circular(16)),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: character.keywords
                                  .map((keyword) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFFFF9E6), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE6C35C), width: 2)),
                                child: Text('# $keyword', style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(12)),
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 80),
                            child: Text(character.speech, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
                          ),
                          Container(width: double.infinity, height: 1, color: const Color(0xFFE0E0E0), margin: const EdgeInsets.symmetric(vertical: 20)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(character: character)));
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8A598), foregroundColor: Colors.white, minimumSize: const Size(100, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                                child: const Text('채팅', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  if (onBack != null) {
                                    onBack!();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B), backgroundColor: const Color(0xFFFFF0F0), side: BorderSide.none, minimumSize: const Size(100, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                child: const Text('나가기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class FriendPage extends StatefulWidget {
  const FriendPage({Key? key}) : super(key: key);

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  bool _recommendationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    print('현재 추천친구 상태: $_recommendationsEnabled');

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 방법 1: async/await 없이 then을 사용
              Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const FriendManagementScreen()),
              ).then((result) {
                print('받아온 값: $result');

                if (result != null) {
                  setState(() {
                    _recommendationsEnabled = result;
                    print('적용된 상태: $_recommendationsEnabled');
                  });
                }
              });

              // 또는 방법 2: FriendManagementScreen에서 값을 정확히 반환하는지 확인
              // async/await를 유지하면서 아래 코드는 그대로 사용
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          if (_recommendationsEnabled)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                '✨ 추천 친구 목록 ✨',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                '🚫 추천 친구를 비활성화했습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          const Divider(),
          if (_recommendationsEnabled)
            Expanded(
              child: ListView.builder(
                itemCount: 5, // 예시
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('친구 ${index + 1}'),
                  );
                },
              ),
            )
          else
            const SizedBox(), // 추천친구 비활성화 시 아무것도 안보이게
        ],
      ),
    );
  }
}