import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:new_project_1/features/Psychology/PsychologyQuestion.dart';
import 'package:new_project_1/features/Psychology/PsychologyResult.dart';

// 이미지 선택 메뉴 위젯 (갤러리에서 이미지 선택 또는 내 캐릭터에서 선택)
class ImagePickerMenu extends StatefulWidget {
  final Function(int) onSelect;
  const ImagePickerMenu({Key? key, required this.onSelect}) : super(key: key);

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
              child: Text(
                '프로필 이미지',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF837C7C)),
              ),
            ),
            // 갤러리 선택 메뉴
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
                    const Text(
                      '갤러리에서 선택',
                      style: TextStyle(color: Color(0xFF837C7C), fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Image.asset('assets/images/Setting/gallery.png', width: 22, height: 22),
                  ],
                ),
              ),
            ),

            // 내 캐릭터 선택 메뉴
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
                    const Text(
                      '내 캐릭터에서 선택',
                      style: TextStyle(color: Color(0xFF837C7C), fontSize: 15, fontWeight: FontWeight.w500),
                    ),
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

// 리스트 내 캐릭터 중복 제거 헬퍼 함수 (id 기준)
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

// 프로필 편집 화면
class ProfileEdit extends StatefulWidget {
  const ProfileEdit({Key? key}) : super(key: key);
  @override
  State<ProfileEdit> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEdit> {
  String nickname = "닉네임을 입력하세요";
  String introText = "";
  File? _profileImage;
  final ImagePicker picker = ImagePicker();

  bool _isEditingNickname = false; // 닉네임 편집 모드 여부
  late TextEditingController _nicknameController; // 닉네임 텍스트 컨트롤러

  List<int> psychologyResultIds = []; // 심리테스트 결과 캐릭터 ID 리스트
  List<Character> availableCharacters = []; // 현재 선택 가능한 캐릭터 리스트
  Character? selectedCharacter; // 현재 프로필에 선택된 캐릭터

  static const String psychologyResultKey = 'psychology_result_ids'; // 저장 키

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: nickname);
    _loadAvailableCharacterIdsAndInit(); // 저장된 캐릭터 리스트 불러오기 시작
  }

  // 저장된 캐릭터 ID 리스트를 불러와 availableCharacters 초기화
  Future<void> _loadAvailableCharacterIdsAndInit() async {
    final ids = await _loadAvailableCharacterIds();
    setState(() {
      // ID로 캐릭터 객체 변환 후 리스트 할당
      availableCharacters = ids
          .map((id) => Character.getCharacterById(id))
          .whereType<Character>()
          .toList();
    });
  }

  // SharedPreferences에서 저장된 캐릭터 ID 리스트 불러오기
  Future<List<int>> _loadAvailableCharacterIds() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList('available_character_ids') ?? [];
    return storedList
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e != 0) // 유효한 ID만
        .toList();
  }

  // 캐릭터 ID 리스트를 SharedPreferences에 저장 (비동기)
  Future<void> _saveAvailableCharacterIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final strList = ids.map((e) => e.toString()).toList(); // 문자열 리스트로 변환
    await prefs.setStringList('available_character_ids', strList);
  }

  // 심리테스트 결과 ID를 받아 앱 상태에 적용 (캐릭터 선택)
  void _applyPsychologyResult(List<int> resultIds) {
    if (resultIds.isEmpty) return;

    psychologyResultIds = resultIds;

    final firstId = resultIds.first;
    final firstCharacter = Character.getCharacterById(firstId); // 첫 캐릭터

    final otherIds = resultIds.length > 1 ? resultIds.sublist(1) : <int>[];
    final others = otherIds
        .map((id) => Character.getCharacterById(id))
        .whereType<Character>()
        .toList();

    // 상태 업데이트: 선택 캐릭터, 사용 가능한 캐릭터 리스트, 이미지 리셋
    setState(() {
      selectedCharacter = firstCharacter;
      availableCharacters = others;
      _profileImage = null;
    });
  }

  // 갤러리 이미지 선택 및 권한 요청 처리
  Future<void> _pickImageFromGallery() async {
    final status = await Permission.photos.status;

    if (status.isGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          selectedCharacter = null; // 캐릭터 선택 해제
        });
      }
    } else if (status.isDenied) {
      final result = await Permission.photos.request();
      if (result.isGranted) {
        _pickImageFromGallery(); // 권한 획득 후 재시도
      } else if (result.isPermanentlyDenied) {
        _showPermissionDeniedDialog(); // 권한 영구 거부 시 안내
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  // 권한 거부시 설정 안내 다이얼로그 표시
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: const Text('갤러리 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.'),
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

  // 캐릭터 선택 시트 표시, 선택 후 결과 저장 및 상태 업데이트
  Future<void> _showCharacterSelectSheet() async {
    Character? tempSelectedCharacter = selectedCharacter;

    final allCharacters = removeDuplicateCharacters([
      if (selectedCharacter != null) selectedCharacter!,
      ...availableCharacters
    ]);

    final result = await showModalBottomSheet<Character>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
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
                    // 선택한 캐릭터 크게 보여주는 영역
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

                        // 완료 버튼
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

                    // 캐릭터 그리드 목록
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
                            onTap: () {
                              setModalState(() {
                                tempSelectedCharacter = character;
                              });
                            },
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
                                        width: isSelected ? 3.2 : 1.5,
                                      ),
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
            );
          },
        );
      },
    );

    // 결과가 있으면 상태 업데이트 및 캐릭터 ID 저장
    if (result != null) {
      setState(() {
        selectedCharacter = result;
        _profileImage = null;

        final newList = removeDuplicateCharacters([selectedCharacter!, ...availableCharacters]);
        availableCharacters = newList.where((c) => c.id != selectedCharacter?.id).toList();

        psychologyResultIds = [selectedCharacter!.id];
      });

      // 선택된 캐릭터 ID 리스트를 저장
      final saveIds = [selectedCharacter!.id, ...availableCharacters.map((c) => c.id)];
      await _saveAvailableCharacterIds(saveIds);
    }
  }

  // 닉네임 편집 시작
  void _startNicknameEdit() {
    setState(() {
      _isEditingNickname = true;
    });
  }

  // 닉네임 저장 및 UI 해제
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

  // 한줄 소개 편집 모달 창 열기
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
                  // 3줄 이상 입력 방지
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

  // 한줄 소개 줄마다 밑줄 긋기 위젯 함수
  Widget _introWithUnderline(String intro, TextStyle style) {
    final lines = intro.isEmpty ? [' '] : intro.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((line) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Colors.grey.shade400))),
        child: Text(line, style: style, overflow: TextOverflow.ellipsis, maxLines: 1),
      ))
          .toList(),
    );
  }

  // 이미지 선택 메뉴를 띄우는 함수 (터치 위치 인자 있지만 메뉴는 화면 중앙에 띄움)
  void _showImagePickerCustomMenu(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                    // 메뉴 선택에 따른 동작 분기
                    if (index == 0) {
                      _pickImageFromGallery(); // 갤러리 이미지 선택
                    } else if (index == 1) {
                      _showCharacterSelectSheet(); // 캐릭터 선택 시트 띄우기
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

  // 심리테스트 화면으로 이동 후 캐릭터 결과 처리
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

  // 심리테스트 결과 ID 리스트 SharedPreferences에 저장
  Future<void> _savePsychologyResult(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final strList = ids.map((e) => e.toString()).toList();
    await prefs.setStringList(psychologyResultKey, strList);
  }

  // 전체 UI 빌드 함수
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
            // 프로필 이미지와 편집 버튼
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
                        ? Image.asset(selectedCharacter!.imagePath, fit: BoxFit.cover, alignment: Alignment.topCenter)
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

            // 닉네임 편집 박스
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
                      )),
                  IconButton(
                    iconSize: screenWidth * 0.035,
                    icon: Icon(_isEditingNickname ? Icons.check : Icons.edit),
                    onPressed: _isEditingNickname ? _saveNickname : _startNicknameEdit,
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.018),

            // 한줄 소개 영역
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
                      Text('한줄 소개 (50자 이내, 최대 3줄)',
                          style: TextStyle(fontSize: screenWidth * 0.035, color: const Color(0xFF807E7E), fontWeight: FontWeight.w500)),
                      InkWell(
                        onTap: _showEditIntroModal,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                          child: Text('수정', style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.white, fontWeight: FontWeight.w500)),
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
        padding: EdgeInsets.only(left: screenWidth * 0.06, right: screenWidth * 0.06, top: screenHeight * 0.15, bottom: screenHeight * 0.03),
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
            child: Text('내 캐릭터 다시 찾기', style: TextStyle(fontSize: screenWidth * 0.038, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
