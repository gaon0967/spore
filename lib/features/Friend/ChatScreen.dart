import 'package:flutter/material.dart';
import '../Psychology/PsychologyResult.dart'; // Character 모델

/// 채팅 메시지 데이터 클래스
class _ChatMessage {
  final String content;
  final bool isMine;
  _ChatMessage(this.content, this.isMine);
}

/// ChatScreen 위젯: Character 객체를 받아 해당 캐릭터와 채팅을 주고받습니다.
class ChatScreen extends StatefulWidget {
  final Character character;
  const ChatScreen({required this.character, Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      _ChatMessage("안녕, ${widget.character.name}!", false),
      _ChatMessage("안녕하세요 😊", true),
    ]);
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(_ChatMessage(text, true)));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

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
            Text(
              widget.character.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final m = _messages[idx];
                return Align(
                  alignment:
                  m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.isMine ? Colors.white : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m.content,
                      style: TextStyle(fontSize: w * 0.042),
                    ),
                  ),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.brown),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
