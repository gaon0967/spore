import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_project_1/features/Psychology/PsychologyQuestion.dart';
import 'package:new_project_1/features/Psychology/PsychologyResult.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Firestore에서 유저의 캐릭터 ID 리스트 가져오기
Future<List<int>> fetchUserCharacterIds(String userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists) {
    final List<dynamic>? ids = doc.data()?['characterIds'];
    if (ids != null) {
      return ids.map((e) => e as int).toList();
    }
  }
  return [];
}

String getImagePathByCharacterId(int id) {
  switch (id) {
    case 1: return 'assets/images/Setting/chac4.png';
    case 2: return 'assets/images/Setting/chac3.png';
    case 3: return 'assets/images/Setting/chac2.png';
    case 4: return 'assets/images/Setting/chac5.png';
    case 5: return 'assets/images/Setting/chac7.png';
    case 6: return 'assets/images/Setting/chac8.png';
    case 7: return 'assets/images/Setting/chac1.png';
    case 8: return 'assets/images/Setting/chac6.png';
    default: return 'assets/images/profile.png';
  }
}

/// 클래스: ProfileEdit
/// 목적: 프로필 편집 화면을 구성하는 StatefulWidget
/// 반환: StatefulWidget 인스턴스 반환
/// 예외: 없음
class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditPageState();
}

/// 클래스: _ProfileEditPageState
/// 목적: ProfileEdit에서 상태 관리, Firestore와 데이터 연동, 닉네임 및 한줄 소개 편집 기능을 제공
/// 반환: State<ProfileEdit> 인스턴스 반환
/// 예외: Firestore 접근 실패 예외 처리 필요
class _ProfileEditPageState extends State<ProfileEdit> {
  String name = "";
  String introText = "";

  List<int> psychologyResultIds = [];
  List<Character> availableCharacters = [];
  Character? selectedCharacter;
  String userId = '';

  static const String psychologyResultKey = 'psychology_result_ids';

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      _loadProfileFromFirestore();
      _loadCharactersFromFirestore().then((_) {
        _loadSelectedIdAndApply();
      });
    }
    _loadSavedPsychologyResult();
  }

  Future<void> _loadSelectedIdAndApply() async {
    if (userId.isEmpty || availableCharacters.isEmpty) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final id = doc.data()?['characterId'];
      if (id != null) {
        final char = availableCharacters.firstWhere(
                (c) => c.id == id, orElse: () => availableCharacters.first);
        setState(() {
          selectedCharacter = char;
        });
      }
    }
  }

  Future<void> _loadProfileFromFirestore() async {
    if (userId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            name = data['name'] ?? "";
            introText = data['intro'] ?? introText;
          });
        }
      }
    } catch (e) {
      debugPrint('프로필 로딩 실패: $e');
    }
  }

  Future<void> _loadCharactersFromFirestore() async {
    if (userId.isEmpty) return;
    try {
      final ids = await fetchUserCharacterIds(userId);
      final chars = ids.map((id) => Character.getCharacterById(id)).whereType<Character>().toList();
      setState(() {
        availableCharacters = chars;
      });
    } catch (e) {
      debugPrint('캐릭터 리스트 불러오기 실패: $e');
    }
  }

  Future<void> _saveSelectedCharacterId() async {
    if (userId.isEmpty || selectedCharacter == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
          {'characterId': selectedCharacter!.id},
          SetOptions(merge: true));
    } catch (e) {
      debugPrint('캐릭터 저장 실패: $e');
    }
  }

  Future<void> _loadSavedPsychologyResult() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList(psychologyResultKey) ?? [];
    final ids = storedList.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
    if (ids.isNotEmpty) {
      _applyPsychologyResult(ids);
    }
  }

  Future<void> _savePsychologyResult(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final strList = ids.map((e) => e.toString()).toList();
    await prefs.setStringList(psychologyResultKey, strList);
  }

  void _applyPsychologyResult(List<int> resultIds) {
    if (resultIds.isEmpty) return;
    psychologyResultIds = resultIds;
    final firstCharacter = Character.getCharacterById(resultIds.first);
    final others = resultIds.length > 1
        ? resultIds.sublist(1).map((id) => Character.getCharacterById(id)).whereType<Character>().toList()
        : <Character>[];
    setState(() {
      selectedCharacter = firstCharacter;
      availableCharacters = others;
    });
  }

  void _showCompleteMessageDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenWidth * 0.65,
              padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Builder(
                builder: (dialogContext) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF535353),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(thickness: 1, height: 1, color: Color(0xFFDDDDDD)),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text(
                            '확인',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    );
  }

  void _showCenteredMessageDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _introWithUnderline(String intro, TextStyle style) {
    final lines = intro.isEmpty ? [' '] : intro.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(width: 1, color: Colors.grey.shade400))),
          child: Text(
            line,
            style: style,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      )
          .toList(),
    );
  }

  Future<void> _goToPsychologyTest() async {
    final result = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute(builder: (context) => const PsychologyQuestion()),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        psychologyResultIds = result;
      });
      _applyPsychologyResult(result);
      _savePsychologyResult(result);
    }
  }

  void _showEditIntroModal() {
    final controller = TextEditingController(text: introText);
    bool _isDialogShowing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;

        Future<void> saveIntroText(String userId, String intro) async {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'intro': intro,
          }, SetOptions(merge: true));
        }

        void finishIntroEdit() async {
          final trimmed = controller.text.trim();
          if (trimmed.isEmpty) {
            if (!_isDialogShowing) {
              _isDialogShowing = true;
              Navigator.of(modalContext).pop();
              _showCompleteMessageDialog(context, '한 글자 이상 입력해주세요.');
              _isDialogShowing = false;
            }
            return;
          }

          await saveIntroText(userId, trimmed);

          setState(() {
            introText = trimmed;
          });

          Navigator.of(modalContext).pop();
          _showCompleteMessageDialog(context, '한줄 소개 수정이 완료되었습니다.');
        }

        void onTextChanged(String value) {
          int lineCount = '\n'.allMatches(value).length + 1;
          if (lineCount > 3) {
            final lines = value.split('\n').take(3).join('\n');
            controller.text = lines;
            controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length));
          }
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, bottom: bottomInset + 16, top: 30),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: 50,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  onChanged: onTextChanged,
                  decoration: InputDecoration(
                    hintText: '한줄 소개를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F8),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: finishIntroEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final profileImageSize = screenWidth * 0.35;
    final boxWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필 변경'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06, vertical: screenHeight * 0.015),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: profileImageSize,
                  height: profileImageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final charId = data?['characterId'] as int? ?? 0;
                          final character = Character.getCharacterById(charId);

                          if (character == null) {
                            return Image.asset(
                              'assets/images/profile.png',
                              width: profileImageSize,
                              height: profileImageSize,
                              fit: BoxFit.cover,
                            );
                          }

                          return Image.asset(
                            getImagePathByCharacterId(character.id),
                            width: profileImageSize,
                            height: profileImageSize,
                            fit: BoxFit.cover,
                          );
                        }
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              width: boxWidth,
              height: screenHeight * 0.055,
              padding: EdgeInsets.symmetric(horizontal: boxWidth * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(fontSize: screenWidth * 0.038),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: boxWidth,
              padding: EdgeInsets.symmetric(
                  horizontal: boxWidth * 0.05, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '한줄 소개 (50자 이내, 최대 3줄)',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF807E7E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      InkWell(
                        onTap: _showEditIntroModal,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '수정',
                            style: TextStyle(fontSize: screenWidth * 0.035,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _introWithUnderline(introText, TextStyle(
                      fontSize: screenWidth * 0.038, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          left: screenWidth * 0.06,
          right: screenWidth * 0.06,
          top: screenHeight * 0.15,
          bottom: screenHeight * 0.03,
        ),
        child: SizedBox(
          width: double.infinity,
          height: screenHeight * 0.07,
          child: ElevatedButton(
            onPressed: _goToPsychologyTest,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF6B6060),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            ),
            child: Text(
              '내 캐릭터 다시 찾기',
              style: TextStyle(fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
