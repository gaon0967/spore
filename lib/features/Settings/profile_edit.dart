import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_project_1/features/Psychology/PsychologyQuestion.dart';
import 'package:new_project_1/features/Psychology/PsychologyResult.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:characters/characters.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:new_project_1/features/Settings/TitleHandler.dart'
    hide handleProfileEditTitles;
import 'package:new_project_1/features/Settings/firebase_title.dart'
    show handleProfileEditTitles;

// Firestore에서 유저의 캐릭터 ID 리스트 가져오기
Future<List<int>> fetchUserCharacterIds(String userId) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
      return 'assets/images/profile.png';
  }
}

/// 클래스: ThreeLinesInputFormatter
/// 목적: TextField에서 사용자 입력을 실시간으로 포맷팅하여, 최대 3줄까지만 허용하고, 글자 수는 최대 50자로 제한.
/// 반환: - formatEditUpdate 메서드는 이전 입력 상태와 새로운 입력 상태를 받아, 제한 조건(줄 수 3줄, 글자 수 50자)을 만족하는 새로운 입력 값을 반환.
/// - 조건에 맞지 않는 입력은 이전 상태를 반환해 입력을 차단.
/// 예외: 줄 수가 3줄을 초과하거나, 글자 수가 50자를 넘는 입력이 들어오면, 새로운 입력을 무시하고 이전 입력 상태를 반환하여 입력을 제한.
class ThreeLinesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid) {
      return newValue;
    }

    final lines = newValue.text.split('\n');
    if (lines.length > 3) {
      return oldValue;
    }
    if (newValue.text.characters.length > 50) {
      final trimmed = newValue.text.characters.take(50).toString();
      int offset = newValue.selection.baseOffset;
      if (offset > trimmed.length) {
        offset = trimmed.length;
      }
      return TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: offset),
      );
    }
    return newValue;
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

/// 클래스: TitleSelect
/// 목적: 사용자가 획득한 타이틀 중에서 최대 2개를 선택할 수 있도록 하는 UI 컴포넌트
/// - 현재 선택된 타이틀 목록과 획득한 타이틀 목록을 받아서 표시
/// - 사용자가 타이틀 버튼을 눌러 선택/해제할 수 있으며, 최대 2개까지만 선택 가능
/// - 선택 완료 시 선택한 타이틀 리스트를 부모 위젯에 전달
/// 반환: StatefulWidget 인스턴스 반환
class TitleSelect extends StatefulWidget {
  final List<String> selected; // 현재 선택한 2개
  final List<String> unlocked; // 획득한 타이틀 목록
  final void Function(List<String>) onSelect; // 선택 완료 시 부모로 전달

  const TitleSelect({
    Key? key,
    required this.selected,
    required this.unlocked,
    required this.onSelect,
  }) : super(key: key);

  @override
  _TitleSelectState createState() => _TitleSelectState();
}

/// 클래스: _TitleSelectState
/// 목적: TitleSelect의 상태를 관리하며 UI 동작과 사용자 입력 처리
/// - 사용자가 타이틀을 선택하거나 선택 해제할 때 상태를 업데이트
/// - 선택된 타이틀이 2개를 넘지 않도록 제한
/// - 완료 버튼을 누르면 선택한 타이틀을 부모 위젯에 알리고 모달을 닫음
/// 반환: State<TitleSelect> 인스턴스 반환
class _TitleSelectState extends State<TitleSelect> {
  late List<String> current;

  @override
  void initState() {
    super.initState();
    current = List.from(widget.selected);
  }

  /// 타이틀 버튼 눌렀을 때 선택/해제 토글
  /// 이미 선택된 타이틀이면 해제, 아니면 최대 2개까지 선택 가능
  void handleToggle(String title) {
    setState(() {
      if (current.contains(title)) {
        current.remove(title);
      } else if (current.length < 2) {
        current.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 상단 상태바(노치) 영역을 침범하지 않도록 Padding 추가
    final double topPadding = MediaQuery.of(context).padding.top;

    return Material(
      // 다이얼로그 안에서 텍스트 스타일이 깨지지 않게 Material로 감쌉니다.
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        // 상단은 직각, 하단만 40으로 둥글게 처리하여 위에서 내려온 느낌을 줍니다.
        decoration: const BoxDecoration(
          color: const Color(0xFFFEFEF9),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        padding: EdgeInsets.fromLTRB(24, topPadding + 10, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물만큼만 높이 차지
          children: [
            // 1. 헤더 (중앙 타이틀 + 우측 완료 버튼)
            Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  '타이틀',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Color(0xFF504A4A),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      widget.onSelect(current);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. 설명글 (중앙 정렬)
            const Text(
              '타이틀 2가지를 지정해주세요.\n지정한 타이틀은 프로필에 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, 
              color: const Color(0xFFA5A5A5),
              height: 1.4),
            ),
            const SizedBox(height: 30),

            // 3. 타이틀 버튼 목록
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 13,
              runSpacing: 13,
              children:
                  allTitles.where((t) => widget.unlocked.contains(t.name)).map((
                    titleInfo,
                  ) {
                    final titleName = titleInfo.name;
                    final isSelected = current.contains(titleName);
                    return GestureDetector(
                      onTap: () => handleToggle(titleName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFFf4ecd2)
                                  : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color:
                                isSelected
                                    ? const Color(0xFF6a6a6a)
                                    : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          titleName,
                          style: TextStyle(
                            fontSize: 14.5,
                            color:
                                isSelected
                                    ? const Color(0xFF413B3B)
                                    : const Color(0xFF6A6A6A),
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
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

  List<String> selectedTitles = [];
  List<String> unlockedTitles = [];

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
    _loadUnlockedTitles();
    loadSelectedTitles();
  }

  Future<void> _loadSelectedIdAndApply() async {
    if (userId.isEmpty || availableCharacters.isEmpty) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final id = doc.data()?['characterId'];
      if (id != null) {
        final char = availableCharacters.firstWhere(
          (c) => c.id == id,
          orElse: () => availableCharacters.first,
        );
        setState(() {
          selectedCharacter = char;
        });
      }
    }
  }

  Future<void> _loadProfileFromFirestore() async {
    if (userId.isEmpty) return;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
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
      final chars =
          ids
              .map((id) => Character.getCharacterById(id))
              .whereType<Character>()
              .toList();
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
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'characterId': selectedCharacter!.id,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('캐릭터 저장 실패: $e');
    }
  }

  Future<void> _loadSavedPsychologyResult() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList(psychologyResultKey) ?? [];
    final ids =
        storedList
            .map((e) => int.tryParse(e) ?? 0)
            .where((e) => e != 0)
            .toList();
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
    final others =
        resultIds.length > 1
            ? resultIds
                .sublist(1)
                .map((id) => Character.getCharacterById(id))
                .whereType<Character>()
                .toList()
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
              padding: const EdgeInsets.only(
                top: 40,
                left: 24,
                right: 24,
                bottom: 20,
              ),
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
                      const Divider(
                        thickness: 1,
                        height: 1,
                        color: Color(0xFFDDDDDD),
                      ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
    );
  }

  void _showCenteredMessageDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _introWithUnderline(String intro, TextStyle style) {
    List<String> lines = intro.isEmpty ? [] : intro.split('\n');

    // 무조건 3줄 공간 확보
    while (lines.length < 3) {
      lines.add("");
    }
    final displayLines = lines.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          displayLines.map((line) {
            return Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 32), // 줄 높이 조절
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: Colors.grey.shade400.withOpacity(0.4),
                  ),
                ),
              ),
              child: Text(
                line.isEmpty ? " " : line,
                style: style,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      backgroundColor: const Color(0xFFE8EEF0),
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

          // 한줄 소개 타이틀 지급
          await handleProfileEditTitles(
            hasIntro: trimmed.isNotEmpty,
            onUpdate: () {
              setState(() {});
            },
          );

          setState(() {
            introText = trimmed;
          });

          Navigator.of(modalContext).pop();
          _showCompleteMessageDialog(context, '한줄 소개 수정이 완료되었습니다.');
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: bottomInset + 16,
            top: 30,
          ),
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
                  inputFormatters: [ThreeLinesInputFormatter()],
                  decoration: InputDecoration(
                    hintText: '한줄 소개를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFE8EEF0),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: finishIntroEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF848CA6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 22,
                  ),
                ),
                child: Text(
                  '완료',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadUnlockedTitles() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('unlocked_titles') ?? [];

    setState(() {
      unlockedTitles = savedList;
    });
  }

  /// 타이틀 선택 (2개만, TitleSelect 모달에서 선택 완료 시 설정)
  void handleTitleSelect(List<String> picked) {
    setState(() {
      selectedTitles = picked;
    });
  }

  // 선택한 타이틀을 Firestore에 저장
  Future<void> saveSelectedTitles(List<String> picked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'selectedTitles': picked,
    });

    print("Firestore에 선택된 타이틀 저장 완료: $picked");
  }

  // 선택한 타이틀 로드
  Future<void> loadSelectedTitles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final data = doc.data();
    if (data != null && data.containsKey('selectedTitles')) {
      setState(() {
        selectedTitles = List<String>.from(data['selectedTitles']);
      });
      print("Firestore에서 선택된 타이틀 불러오기 완료: $selectedTitles");
    } else {
      print("Firestore에 선택된 타이틀 없음, 기본값 사용");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final profileImageSize = screenWidth * 0.35;
    final boxWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      appBar: AppBar(
        // 1. 뒤로가기 화살표 이미지로 교체
        titleSpacing: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/Setting/go.png', // 화살표 이미지 경로
            width: screenWidth * 0.045,
            height: screenWidth * 0.045,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // 2. 프로필 변경 글꼴 및 스타일 수정
        title: Text(
          '프로필 변경',
          style: TextStyle(
            fontSize: screenWidth * 0.047,
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w700,
            color: Color(0xFF504A4A),
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFFFFEF9),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.015,
        ),
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
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFFEEEEEE),
                      width: 4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
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
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              width: boxWidth,
              height: screenHeight * 0.068,
              padding: EdgeInsets.symmetric(horizontal: boxWidth * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF635A5A),
                    fontSize: screenWidth * 0.045,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: boxWidth,
              constraints: const BoxConstraints(minHeight: 170), // 적절한 박스 높이 유지
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 15),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 타이틀 (가장 상단)
                      Text(
                        '한줄 소개 (50자 이내)',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF807E7E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 줄노트 영역
                      _introWithUnderline(
                        introText,
                        TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF635A5A),
                        ),
                      ),

                      // 1. 핵심: 줄 영역과 버튼이 겹치지 않게 하단 여백 확보
                      const SizedBox(height: 55),
                    ],
                  ),

                  // 2. 수정 버튼을 우측 하단 구석에 배치
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _showEditIntroModal,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '수정',
                          style: TextStyle(
                            fontSize: screenWidth * 0.036,
                            color: const Color(0xFFFFFFF9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            Divider(color: Color(0xFFC0BBBB), thickness: 1),
            const SizedBox(height: 11),

            // 타이틀 변경 UI
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀 변경 버튼
                GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true, // 배경 터치 시 닫기
                      barrierLabel: '',
                      barrierColor: Colors.black.withOpacity(
                        0.5,
                      ), // 배경 어두워지는 정도
                      transitionDuration: const Duration(
                        milliseconds: 450,
                      ), // 내려오는 속도
                      pageBuilder: (context, anim1, anim2) {
                        // 위에서 아래로 정렬되도록 Alignment 설정
                        return Align(
                          alignment: Alignment.topCenter,
                          child: TitleSelect(
                            selected: selectedTitles,
                            unlocked: unlockedTitles,
                            onSelect: (newTitles) {
                              setState(() {
                                selectedTitles = newTitles;
                              });
                              saveSelectedTitles(newTitles);
                            },
                          ),
                        );
                      },
                      // 위에서 아래로 내려오는 애니메이션 설정
                      transitionBuilder: (context, anim1, anim2, child) {
                        return SlideTransition(
                          position: Tween(
                            begin: const Offset(0, -1),
                            end: const Offset(0, 0),
                          ).animate(anim1),
                          child: child,
                        );
                      },
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "타이틀 변경",
                        style: TextStyle(
                          fontSize: screenWidth * 0.039,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF807E7E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Image.asset(
                        'assets/images/Setting/chevron2.png',
                        width: 14,
                        height: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // 선택된 타이틀 표시
                if (selectedTitles.isNotEmpty)
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children:
                        selectedTitles.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFf4ecd2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              "# $t",
                              style: TextStyle(
                                color: Color(0xFF504a4a),
                                fontWeight: FontWeight.w500,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                          );
                        }).toList(),
                  )
                else
                  Text(
                    "선택된 타이틀이 없습니다.",
                    style: TextStyle(
                      fontSize: screenWidth * 0.033,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFFFEF9),
        padding: EdgeInsets.only(
          left: screenWidth * 0.06,
          right: screenWidth * 0.06,
          top: screenHeight * 0.02,
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
                borderRadius: BorderRadius.circular(16),
              ),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            ),
            child: Text(
              '내 캐릭터 다시 찾기',
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
