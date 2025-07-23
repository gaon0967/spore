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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Text('친구'),
          bottom: TabBar(
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) {
            setState(() => _navIndex = i);
            // 페이지 이동은 여기서 구현 가능
          },
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '친구',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: '시간표',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.person_add),
          onPressed: () {
            // 친구 추가 기능
          },
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
          final friend = list[index];
          final isFav = favoriteIndices.contains(index);
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
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
                      child: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: isFav ? Colors.amber : Colors.grey,
                      ),
                    ),
                    SizedBox(width: 12),
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
