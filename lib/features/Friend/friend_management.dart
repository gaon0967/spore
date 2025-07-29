// lib/Friend/friend_management.dart

import 'package:flutter/material.dart';

/// ==============================
/// 클래스명: friend_management
/// 역할: 추천 친구 토글 및 차단 목록 관리 화면
/// ==============================
/// 수정코드
class friend_management extends StatefulWidget {
  const friend_management({Key? key}) : super(key: key);

  @override
  _friend_managementState createState() => _friend_managementState();
}

class _friend_managementState extends State<friend_management> {
  bool _recommendationsEnabled = true;

  // (예시) 차단된 친구 리스트: 이름과 (선택적) 프로필 이미지 경로
  final List<Map<String, String?>> _blockedFriends = [
    {'name': '차단1', 'image': null},
    {'name': '차단2', 'image': null},
    {'name': '차단3', 'image': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,  // 전체 백그라운드 흰색
      appBar: AppBar(
        title: const Text('친구 관리', style: TextStyle(color: Color(0xFF504A4A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF504A4A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1) 추천 친구 활성화 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '추천 친구 활성화',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF504A4A),
                ),
              ),
              Switch(
                value: _recommendationsEnabled,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF95A797),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCCCCCC),
                onChanged: (value) {
                  setState(() {
                    _recommendationsEnabled = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2) 차단 목록
          ExpansionTile(
            title: const Text(
              '차단 목록',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF504A4A),
              ),
            ),
            children: _blockedFriends.map((friend) {
              final imagePath = friend['image'];
              final name = friend['name']!;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                    imagePath != null ? AssetImage(imagePath) : null,
                    // 이미지가 없으면 이 child를 대신 표시
                    child: imagePath == null
                        ? Text(
                      name[0],
                      style: const TextStyle(
                        color: Color(0xFF504A4A),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF504A4A),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      setState(() {
                        _blockedFriends.remove(friend);
                      });
                    },
                    child: const Text(
                      '해제',
                      style: TextStyle(color: Color(0xFF506497)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
