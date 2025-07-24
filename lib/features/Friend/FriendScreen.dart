import 'package:flutter/material.dart';

class FriendScreen extends StatefulWidget {
  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final List<Friend> friends = [
    Friend(name: '가부기'),
    Friend(name: '햄부기'),
    Friend(name: '돼콩이'),
    Friend(name: '오덴세'),
  ];
  final List<Friend> requests = [
    Friend(name: '홍길동'),
  ];
  final List<Friend> recommendations = [
    Friend(name: '박민수'),
  ];

  final Set<int> favoriteIndices = {};
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFEF9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFEF9),
          foregroundColor: Colors.black,
          elevation: 0,
          title: Text('친구'),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: '친구 목록'),
              Tab(text: '신청 목록'),
              Tab(text: '추천 친구'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {}, // TODO: 검색 기능
            ),
          ],
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildListWithActions(friends),
            _buildListWithActions(requests),
            _buildListWithActions(recommendations),
          ],
        ),
      ),
    );
  }

  Widget _buildListWithActions(List<Friend> list) {
    return SafeArea(
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final screenWidth = MediaQuery.of(context).size.width;
          final friend = list[index];
          final isFav = favoriteIndices.contains(index);
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFav)
                            favoriteIndices.remove(index);
                          else
                            favoriteIndices.add(index);
                        });
                      },
                      child: SizedBox(
                        height: screenWidth * 0.06, // 이미지 크기보다 약간 크게 설정
                        child: Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            isFav
                              ? 'assets/images/friendScreen/star_on.png'
                              : 'assets/images/friendScreen/star_off.png',
                            width: screenWidth * 0.042, // 반응형 크기
                            height: screenWidth * 0.042,
                            color: null,
                            fit: BoxFit.contain,
                            gaplessPlayback: true, // 이미지가 바뀔 때 깜빡임 방지
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(friend.name, style: TextStyle(fontSize: 16)),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          list.removeAt(index);
                        });
                      },
                      child: Text('차단'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          list.removeAt(index);
                        });
                      },
                      child: Text('삭제'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Friend {
  final String name;
  Friend({required this.name});
}
