// friend_management.dart

import 'package:flutter/material.dart';

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({Key? key}) : super(key: key);

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> {
  bool _recommendationsEnabled = true;

  final List<Map<String, String?>> _blockedFriends = [
    {'name': '차단1', 'image': null},
    {'name': '차단2', 'image': null},
    {'name': '차단3', 'image': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('친구 관리', style: TextStyle(color: Color(0xFF504A4A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF504A4A)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _recommendationsEnabled);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          ExpansionTile(
            title: const Text(
              '차단 목록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF504A4A)),
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
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imagePath != null ? AssetImage(imagePath) : null,
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
                  title: Text(name, style: const TextStyle(fontSize: 16, color: Color(0xFF504A4A))),
                  trailing: TextButton(
                    onPressed: () {
                      setState(() {
                        _blockedFriends.remove(friend);
                      });
                    },
                    child: const Text('해제', style: TextStyle(color: Color(0xFF506497))),
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
