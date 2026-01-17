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
class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditPageState();
}

/// 클래스: TitleSelect
class TitleSelect extends StatefulWidget {
  final List<String> selected;
  final List<String> unlocked;
  final void Function(List<String>) onSelect;

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
class _TitleSelectState extends State<TitleSelect> {
  late List<String> current;

  @override
  void initState() {
    super.initState();
    current = List.from(widget.selected);
  }

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
    final double topPadding = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double w = screenWidth * 0.00243;
    final double h = screenHeight * 0.001134;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFEFEF9),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        padding: EdgeInsets.fromLTRB(24*w, topPadding + 10, 24*w, 40*h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '타이틀',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19*w,
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
                    child: Text(
                      '완료',
                      style: TextStyle(
                        color: Color(0xFF6A6A6A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16*w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10*h),
            Text(
              '타이틀 2가지를 지정해주세요.\n지정한 타이틀은 프로필에 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14*w,
                color: Color(0xFFA5A5A5),
                height: 1.4,
              ),
            ),
            SizedBox(height: 30*h),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 13*w,
              runSpacing: 13*h,
              children:
                  allTitles.where((t) => widget.unlocked.contains(t.name)).map((
                    titleInfo,
                  ) {
                    final titleName = titleInfo.name;
                    final isSelected = current.contains(titleName);
                    return GestureDetector(
                      onTap: () => handleToggle(titleName),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18*w,
                          vertical: 10*h,
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
                            fontSize: 14.5*w,
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
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        final double w = screenWidth * 0.00243;
        final double h = screenHeight * 0.001134;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenWidth * 0.65,
              padding: EdgeInsets.only(
                top: 40*h,
                left: 24*w,
                right: 24*w,
                bottom: 20*h,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      message,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16*w,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF535353),
                      ),
                    ),
                  ),
                  SizedBox(height: 24*h),
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFDDDDDD),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 44*h,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 16*w,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
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
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final double w = screenWidth * 0.00243;
        final double h = screenHeight * 0.001134;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.fromLTRB(24*w, 20*h, 24*w, 0),
          content: SizedBox(
            width: 280*w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16*w,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 24*h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14*h),
                    ),
                    child: Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 16*w,
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
              constraints: const BoxConstraints(minHeight: 32),
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
    // '내 캐릭터 다시 찾기' 버튼이므로 isReTest를 true로 전달합니다.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PsychologyQuestion(isReTest: true),
      ),
    );

    // PsychologyResult에서 Navigator.pushAndRemoveUntil(MainScreen)을 수행하므로
    // 이 이후의 코드는 실행되지 않거나 홈 화면으로 덮어씌워집니다.
  }

  void _showEditIntroModal() {
    final controller = TextEditingController(text: introText);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double w = screenWidth * 0.00243;
    final double h = screenHeight * 0.001134;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;

        Future<void> finishIntroEdit() async {
          final trimmed = controller.text.trim();

          // Firestore에 저장
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'intro': trimmed});

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

        return GestureDetector(
          onTap: () => FocusScope.of(modalContext).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEF0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(16*w, 30*h, 16*w, bottomInset + 16),
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14*w,
                          vertical: 12*h,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  SizedBox(width: 12*w),
                  ElevatedButton(
                    onPressed: finishIntroEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF848CA6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 14*h,
                        horizontal: 22*w,
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
            ),
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

  void handleTitleSelect(List<String> picked) {
    setState(() {
      selectedTitles = picked;
    });
  }

  Future<void> saveSelectedTitles(List<String> picked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'selectedTitles': picked,
    });

    print("Firestore에 선택된 타이틀 저장 완료: $picked");
  }

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
    final double w = screenWidth * 0.00243;
    final double h = screenHeight * 0.001134;
    final profileImageSize = screenWidth * 0.35;
    final boxWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/Setting/go.png',
            width: screenWidth * 0.045,
            height: screenWidth * 0.045,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '프로필 변경',
          style: TextStyle(
            fontSize: screenWidth * 0.047,
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w700,
            color: const Color(0xFF504A4A),
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
                      width: 4*w,
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
            SizedBox(height: 22*h),
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
                    color: const Color(0xFF635A5A),
                    fontSize: screenWidth * 0.045,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 22*h),
            Container(
              width: boxWidth,
              constraints: const BoxConstraints(minHeight: 170),
              padding: EdgeInsets.fromLTRB(20*w, 12*h, 20*w, 15*h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '한줄 소개 (50자 이내)',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF807E7E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8*h),
                      _introWithUnderline(
                        introText,
                        TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF635A5A),
                        ),
                      ),
                      SizedBox(height: 55*h),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _showEditIntroModal,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16*w,
                          vertical: 10*h,
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
            SizedBox(height: 15*h),
            const Divider(color: Color(0xFFC0BBBB), thickness: 1),
            SizedBox(height: 11*h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black.withOpacity(0.5),
                      transitionDuration: const Duration(milliseconds: 450),
                      pageBuilder: (context, anim1, anim2) {
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
                    children: [
                      Text(
                        "타이틀 변경",
                        style: TextStyle(
                          fontSize: screenWidth * 0.039,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF807E7E),
                        ),
                      ),
                      SizedBox(width: 6*w),
                      Image.asset(
                        'assets/images/Setting/chevron2.png',
                        width: 14*w,
                        height: 14*h,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15*h),
                if (selectedTitles.isNotEmpty)
                  Wrap(
                    spacing: 14*w,
                    runSpacing: 14*h, 
                    children:
                        selectedTitles.map((t) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16*w,
                              vertical: 10*h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFf4ecd2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              "# $t",
                              style: TextStyle(
                                color: const Color(0xFF504a4a),
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
