import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:new_project_1/features/Psychology/PsychologyQuestion.dart';
import 'package:new_project_1/features/Psychology/PsychologyResult.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 이미지 선택 메뉴 (갤러리, 캐릭터 선택)
class ImagePickerMenu extends StatefulWidget {
  final Function(int) onSelect;
  const ImagePickerMenu({super.key, required this.onSelect});

  @override
  State<ImagePickerMenu> createState() => _ImagePickerMenuState();
}

class _ImagePickerMenuState extends State<ImagePickerMenu> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final menuWidth = MediaQuery.of(context).size.width * 0.65;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: menuWidth,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFF9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text('프로필 이미지',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF837C7C))),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(48),
              onTap: () {
                setState(() => selectedIndex = 0);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onSelect(0);
                });
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selectedIndex == 0 ? const Color(0xFFEFEFEF) : const Color(0xFFFFFFF9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('갤러리에서 선택',
                        style: TextStyle(color: Color(0xFF837C7C), fontSize: 15, fontWeight: FontWeight.w500)),
                    Image.asset('assets/images/Setting/gallery.png', width: 22, height: 22),
                  ],
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(48),
              onTap: () {
                setState(() => selectedIndex = 1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onSelect(1);
                });
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: selectedIndex == 1 ? const Color(0xFFEFEFEF) : const Color(0xFFFFFFF9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('내 캐릭터에서 선택',
                        style: TextStyle(color: Color(0xFF837C7C), fontSize: 15, fontWeight: FontWeight.w500)),
                    Image.asset('assets/images/Setting/Union.png', width: 22, height: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 캐릭터 중복 제거
List<Character> removeDuplicateCharacters(List<Character> characters) {
  final seen = <int>{};
  final distinctCharacters = <Character>[];

  for (var character in characters) {
    if (!seen.contains(character.id)) {
      seen.add(character.id);
      distinctCharacters.add(character);
    }
  }
  return distinctCharacters;
}

// Firestore에서 유저 캐릭터 ID 리스트 불러오기
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

// 프로필 편집 화면
class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});
  @override
  State<ProfileEdit> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEdit> {
  String nickname = "닉네임을 입력하세요";
  String introText = "";
  File? _profileImage;
  final ImagePicker picker = ImagePicker();

  bool _isEditingNickname = false;
  late TextEditingController _nicknameController;

  List<int> psychologyResultIds = [];
  List<Character> availableCharacters = [];
  Character? selectedCharacter;

  // userId 변수를 빈 문자열로 초기화, 실제 UID가 할당될 예정
  String userId = '';

  static const String psychologyResultKey = 'psychology_result_ids';

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: nickname);

    // 현재 로그인된 사용자 UID를 가져와 userId에 저장
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      // 로그인되지 않은 상태라면 필요에 따라 처리
      userId = '';
    }

    _loadSavedPsychologyResult();

    // userId가 빈 값이 아닐 때만 Firestore에서 캐릭터 리스트 로드
    if (userId.isNotEmpty) {
      _loadCharactersFromFirestore();
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadCharactersFromFirestore() async {
    if (userId.isEmpty) {
      debugPrint('사용자 ID가 없어서 캐릭터를 불러올 수 없습니다.');
      return;
    }

    // Firestore에서 ID 리스트 불러오기
    final ids = await fetchUserCharacterIds(userId);

    // ID 리스트를 캐릭터 객체 리스트로 변환
    final chars = ids
        .map((id) => Character.getCharacterById(id))
        .whereType<Character>()
        .toList();

    // 상태 업데이트
    setState(() {
      availableCharacters = chars;
      if (chars.isNotEmpty && selectedCharacter == null) {
        selectedCharacter = chars.first;
      }
    });
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
      _profileImage = null;
    });
  }

  Future<void> _pickImageFromGallery() async {
    final status = await Permission.photos.status;

    if (status.isGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          selectedCharacter = null;
        });
      }
    } else if (status.isDenied) {
      final result = await Permission.photos.request();
      if (result.isGranted) {
        _pickImageFromGallery();
      } else if (result.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: const Text('갤러리 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해 주세요.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCharacterSelectSheet() async {
    Character? tempSelectedCharacter = selectedCharacter;

    // Firestore에서 최신 불러오는 코드도 필요하면 추가 가능
    final allCharacters = removeDuplicateCharacters([
      if (selectedCharacter != null) selectedCharacter!,
      ...availableCharacters
    ]);

    final result = await showModalBottomSheet<Character>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: 0.65,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            alignment: Alignment.center,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF5F5F5),
                                border: Border.all(
                                  color: tempSelectedCharacter != null ? const Color(0xFF6075B8) : Colors.grey.shade300,
                                  width: tempSelectedCharacter != null ? 3.2 : 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: tempSelectedCharacter != null
                                    ? Image.asset(tempSelectedCharacter!.imagePath, fit: BoxFit.cover)
                                    : const SizedBox(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 0,
                      child: TextButton(
                        onPressed: tempSelectedCharacter != null ? () => Navigator.pop(context, tempSelectedCharacter) : null,
                        child: Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tempSelectedCharacter != null ? const Color(0xFF6075B8) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(thickness: 1, color: Colors.grey, height: 24),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    itemCount: allCharacters.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final character = allCharacters[index];
                      final isSelected = tempSelectedCharacter?.id == character.id;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempSelectedCharacter = character),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 95,
                              height: 95,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              alignment: Alignment.center,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF5F5F5),
                                  border: Border.all(
                                      color: isSelected ? const Color(0xFF6075B8) : Colors.grey.shade300,
                                      width: isSelected ? 3.2 : 1.5),
                                ),
                                child: ClipOval(
                                  child: Image.asset(character.imagePath, width: 74, height: 74, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 130,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(17)),
                              child: Text(
                                character.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6A6A6A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedCharacter = result;
        _profileImage = null;
        availableCharacters = removeDuplicateCharacters([selectedCharacter!, ...availableCharacters])
            .where((character) => character.id != selectedCharacter?.id)
            .toList();
        psychologyResultIds = [selectedCharacter!.id];
      });

      // 심리 테스트 결과 저장
      _savePsychologyResult(psychologyResultIds);
    }
  }

  void _startNicknameEdit() {
    setState(() {
      _isEditingNickname = true;
    });
  }

  void _saveNickname() {
    final trimmed = _nicknameController.text.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        nickname = trimmed.length > 10 ? trimmed.substring(0, 10) : trimmed;
        _nicknameController.text = nickname;
        _isEditingNickname = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임 수정이 완료되었습니다.')));
      FocusScope.of(context).unfocus();
    }
  }

  void _showEditIntroModal() {
    final controller = TextEditingController(text: introText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: 50,
                autofocus: true,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: '한줄 소개를 입력하세요',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: (text) {
                  final lines = text.split('\n');
                  if (lines.length > 3) {
                    controller.text = lines.take(3).join('\n');
                    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                  }
                },
                onSubmitted: (_) {
                  setState(() {
                    introText = controller.text.trim();
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    introText = controller.text.trim();
                  });
                  Navigator.pop(context);
                },
                child: const Text('완료'),
              ),
              const SizedBox(height: 16),
            ],
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
          decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Colors.grey.shade400))),
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

  void _showImagePickerCustomMenu(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (contextDialog) {
        final menuWidth = screenWidth * 0.65;
        return Center(
          child: SizedBox(
            width: menuWidth,
            child: Material(
              borderRadius: BorderRadius.circular(18),
              child: ImagePickerMenu(
                onSelect: (index) {
                  Navigator.of(contextDialog).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (index == 0) {
                      _pickImageFromGallery();
                    } else if (index == 1) {
                      _showCharacterSelectSheet();
                    }
                  });
                },
              ),
            ),
          ),
        );
      },
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
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.015),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: profileImageSize,
                  height: profileImageSize,
                  padding: EdgeInsets.all(profileImageSize * 0.035),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _profileImage != null
                        ? Image.file(_profileImage!, fit: BoxFit.cover)
                        : (selectedCharacter != null
                        ? Image.asset(selectedCharacter!.imagePath,
                        fit: BoxFit.cover, alignment: Alignment.topCenter)
                        : Image.asset('assets/images/profile.png', fit: BoxFit.cover)),
                  ),
                ),
                Positioned(
                  bottom: profileImageSize * 0.04,
                  right: profileImageSize * 0.04,
                  child: GestureDetector(
                    onTapDown: (details) => _showImagePickerCustomMenu(details.globalPosition),
                    child: Container(
                      width: profileImageSize * 0.3,
                      height: profileImageSize * 0.3,
                      padding: EdgeInsets.all(profileImageSize * 0.04),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(profileImageSize * 0.04),
                        child: Image.asset('assets/images/Setting/Exclude.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.029),
            Container(
              width: boxWidth,
              height: screenHeight * 0.055,
              padding: EdgeInsets.symmetric(horizontal: boxWidth * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _isEditingNickname
                        ? TextField(
                      controller: _nicknameController,
                      autofocus: true,
                      maxLength: 10,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: screenWidth * 0.038),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onSubmitted: (_) => _saveNickname(),
                    )
                        : GestureDetector(
                      onTap: _startNicknameEdit,
                      child: Center(
                        child: Text(
                          nickname,
                          style: TextStyle(fontSize: screenWidth * 0.038),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: screenWidth * 0.035,
                    icon: Icon(_isEditingNickname ? Icons.check : Icons.edit),
                    onPressed: _isEditingNickname ? _saveNickname : _startNicknameEdit,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.018),
            Container(
              width: boxWidth,
              padding: EdgeInsets.symmetric(horizontal: boxWidth * 0.05, vertical: 24),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration:
                          BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '수정',
                            style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  _introWithUnderline(introText, TextStyle(fontSize: screenWidth * 0.038, color: Colors.black87)),
                  SizedBox(height: screenHeight * 0.025),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            ),
            child: Text(
              '내 캐릭터 다시 찾기',
              style: TextStyle(fontSize: screenWidth * 0.038, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}