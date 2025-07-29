// lib/features/Friend/FriendScreen.dart

import 'package:flutter/material.dart';
import '../Psychology/PsychologyResult.dart'; // Character 모델
import 'ChatScreen.dart';                     // ChatScreen 위젯

/// --- 데이터 모델 ---
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

/// --- 전체 친구 화면 (탭 3개) ---
class FriendScreen extends StatefulWidget {
  const FriendScreen({Key? key}) : super(key: key);

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  // 1) 친구 목록
  final List<Friend> _friends = [
    const Friend(name: '가부기', tags: ['맛잘알', '소포어의 식구'], characterId: 4),
    const Friend(name: '햄부기', tags: ['유일무이', '소심이'],     characterId: 6),
    const Friend(name: '돼콩이', tags: ['맛잘알', '소포어의 식구'], characterId: 5),
    const Friend(name: '오덴세', tags: ['인싸',   '소포어의 비기너'], characterId: 2),
  ];
  final Set<int> _favorites = {};

  // 2) 신청 목록
  final List<FriendRequest> _incoming = [
    const FriendRequest(name: '리바이',  tags: ['소심마','집들이'], characterId: 3),
    const FriendRequest(name: '김고양', tags: ['신비주의','집순이'], characterId: 8),
  ];
  final List<FriendRequest> _outgoing = [
    // 예시: 이미 보낸 요청
    const FriendRequest(name: '김고양', tags: ['신비주의','집순이'], characterId: 8),
  ];

  // 3) 추천 친구 (슬라이더에서 사용할 가상 IDs)
  final List<int> _virtualIds = [4, 2, 6];

  // 친구 코드 입력 컨트롤러
  final TextEditingController _codeCtrl = TextEditingController();
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
            onPressed: () {},
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              onPressed: () {},
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

  // ── 탭 1: 친구 목록 ──
  Widget _buildFriendList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final f   = _friends[idx];
        final fav = _favorites.contains(idx);
        return _FriendTile(
          name: f.name,
          tags: f.tags,
          tileColor: Colors.grey.shade50,
          isFavorite: fav,
          onFavoriteToggle: () => setState(() {
            fav ? _favorites.remove(idx) : _favorites.add(idx);
          }),
          onTap: () {
            final ch = Character.getCharacterById(f.characterId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendProfileScreen(character: ch),
              ),
            );
          },
          trailingButtons: [
            TextButton(
              onPressed: () => _showConfirm(
                '차단',
                    () => setState(() => _friends.removeAt(idx)),
              ),
              child: const Text('차단', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => _showConfirm(
                '삭제',
                    () => setState(() => _friends.removeAt(idx)),
              ),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ── 탭 2: 신청 목록 ──
  Widget _buildRequestList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 친구 코드 입력
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  decoration: InputDecoration(
                    hintText: '친구 코드로 추가',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final code = _codeCtrl.text.trim();
                  if (code.isNotEmpty) {
                    setState(() {
                      _outgoing.add(FriendRequest(
                        name: code,
                        tags: const [],
                        characterId: 1,
                      ));
                    });
                    _codeCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('[$code]님께 요청을 보냈습니다.')),
                    );
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
          // incoming
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('나랑 친구해줘!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              children: _incoming.map((r) {
                return _FriendTile(
                  name: r.name,
                  tags: r.tags,
                  tileColor: const Color(0xFFE8F0FE),
                  isFavorite: false,
                  onFavoriteToggle: null,
                  onTap: () {
                    final ch = Character.getCharacterById(r.characterId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FriendProfileScreen(character: ch),
                      ),
                    );
                  },
                  tagBgColor: const Color(0xFFD0E4FF),
                  tagTextColor: const Color(0xFF0066CC),
                  trailingButtons: [
                    TextButton(
                      onPressed: () {
                        if (_friends.any((f) => f.name == r.name)) {
                          _showAlert('이미 친구 목록에 있습니다.');
                        } else {
                          setState(() {
                            _friends.add(Friend(
                              name: r.name,
                              tags: r.tags,
                              characterId: r.characterId,
                            ));
                            _incoming.remove(r);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${r.name}님과 친구가 되었습니다!')),
                          );
                        }
                      },
                      child: const Text('수락', style: TextStyle(color: Colors.green)),
                    ),
                    TextButton(
                      onPressed: () => _showConfirm(
                          '거절', () => setState(() => _incoming.remove(r))),
                      child: const Text('거절', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const Divider(height: 32, thickness: 1),

          // outgoing
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('언제쯤 받아줄까...',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              children: _outgoing.map((r) {
                return _FriendTile(
                  name: r.name,
                  tags: r.tags,
                  tileColor: const Color(0xFFFBF5EB),
                  isFavorite: false,
                  onFavoriteToggle: null,
                  onTap: () {},
                  trailingButtons: [
                    ElevatedButton(
                      onPressed: () => setState(() => _outgoing.remove(r)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(100, 36),
                      ),
                      child: const Text('친구 신청 취소',
                          style: TextStyle(color: Colors.white)),
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

  // ── 탭 3: 추천 친구 슬라이더 ──
  Widget _buildRecommendationSlider() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: _virtualIds.length,
            itemBuilder: (context, i) {
              final c = Character.getCharacterById(_virtualIds[i]);
              return Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EFE6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 프로필 일러스트
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.brown[100]!, width: 3),
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.asset(c.imagePath, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 이름 + 별
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text(c.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 태그
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: c.keywords
                            .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.yellow.shade100,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('#$t',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.brown)),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      // 말풍선
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(c.speech,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(height: 16),
                      // 친구 신청 버튼
                      ElevatedButton(
                        onPressed: () {
                          if (_outgoing.any((r) => r.name == c.name)) {
                            _showAlert('이미 신청 목록에 있습니다.');
                          } else if (_friends.any((f) => f.name == c.name)) {
                            _showAlert('이미 친구 목록에 있습니다.');
                          } else {
                            setState(() {
                              _outgoing.add(FriendRequest(
                                  name: c.name,
                                  tags: c.keywords,
                                  characterId: c.id));
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${c.name}님께 요청했습니다.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          shape: const StadiumBorder(),
                          minimumSize: const Size(140, 44),
                        ),
                        child: const Text('친구 신청',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text('옆으로 스와이프 하세요',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 확인 다이얼로그
  void _showConfirm(String action, VoidCallback onOk) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('정말 $action 하시겠습니까?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  minimumSize: const Size(100, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                const Text('네', style: TextStyle(color: Colors.red)),
              ),
            ])
          ]),
        ),
      ),
    );
  }

  /// 간단 안내 얼럿
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('확인'),
          )
        ],
      ),
    );
  }
}

/// --- 공통 친구/타일 위젯 ---
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
    final bg = tagBgColor ?? Colors.yellow.shade100;
    final tx = tagTextColor ?? Colors.brown.shade800;

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
        child: Row(children: [
          if (onFavoriteToggle != null) ...[
            GestureDetector(
              onTap: onFavoriteToggle,
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags
                      .map((t) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('#$t',
                        style: TextStyle(fontSize: 12, color: tx)),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
          ...trailingButtons,
        ]),
      ),
    );
  }
}

/// --- 친구 프로필 화면 ---
class FriendProfileScreen extends StatelessWidget {
  final Character character;
  const FriendProfileScreen({
    required this.character,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
            const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                Border.all(color: const Color(0xFFE3DFDA), width: 5),
                color: Colors.white,
              ),
              child: ClipOval(
                child:
                Image.asset(character.imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(character.name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown)),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: character.keywords
                  .map((k) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(k,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.brown.shade800)),
              ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(character.speech,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: w * 0.04)),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(character: character),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1C6C3),
                    foregroundColor: Colors.brown[900],
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22))),
                child:
                const Text('채팅', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(
                        color: Colors.redAccent, width: 1.2),
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22))),
                child:
                const Text('나가기', style: TextStyle(fontSize: 16)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
