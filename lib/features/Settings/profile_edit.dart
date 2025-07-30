import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Character {
  final String imagePath;
  final String name;

  const Character({
    required this.imagePath,
    required this.name,
  });
}

class ProfileEdit extends StatefulWidget {
  final int? psychologyResultId;
  const ProfileEdit({Key? key, this.psychologyResultId}) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEdit> {
  String nickname = "닉네임을 입력하세요";
  String introText = "";
  File? _profileImage;
  final picker = ImagePicker();
  bool _isEditingNickname = false;

  late final TextEditingController _nicknameController;
  final TextEditingController _introController = TextEditingController();

  Character? selectedCharacter;

  late Map<int, Character> psychTestResultsMap;

  @override
  void initState() {
    super.initState();

    _nicknameController = TextEditingController(text: nickname);
    _introController.text = introText;
    _introController.addListener(_limitIntroLines);

    psychTestResultsMap = {
      1: const Character(imagePath: 'assets/images/Setting/chac1.png', name: '마더테레사'),
      2: const Character(imagePath: 'assets/images/Setting/chac2.png', name: '게으른 철학자'),
      3: const Character(imagePath: 'assets/images/Setting/chac3.png', name: '마이웨이'),
      4: const Character(imagePath: 'assets/images/Setting/chac4.png', name: '해피 바이러스'),
      5: const Character(imagePath: 'assets/images/Setting/chac5.png', name: '과몰입러'),
      6: const Character(imagePath: 'assets/images/Setting/chac6.png', name: '대문자F'),
      7: const Character(imagePath: 'assets/images/Setting/chac7.png', name: '정의로운 용사'),
      8: const Character(imagePath: 'assets/images/Setting/chac8.png', name: '명언가'),
    };

    if (widget.psychologyResultId != null) {
      updateProfileByPsychTestResult(widget.psychologyResultId!);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _introController.removeListener(_limitIntroLines);
    _introController.dispose();
    super.dispose();
  }

  void updateProfileByPsychTestResult(int resultKey) {
    final character = psychTestResultsMap[resultKey];
    setState(() {
      selectedCharacter = character;
      _profileImage = null;
    });
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        selectedCharacter = null;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape:
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('내 캐릭터에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _showCharacterSelectSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCharacterSelectSheet() async {
    final characters = psychTestResultsMap.values.toList();


    Character? tempSelectedCharacter = selectedCharacter;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget displayImage;
            String displayName = '';

            if (tempSelectedCharacter != null) {
              displayImage = ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  tempSelectedCharacter!.imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              );
              displayName = tempSelectedCharacter!.name;
            } else {
              displayImage = ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/profile.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              );
            }

            return GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: GestureDetector(
                  onTap: () {},
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 460,
                      padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              displayImage,
                              const SizedBox(height: 10),
                              Text(
                                displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.8,
                                  ),
                                  itemCount: characters.length,
                                  itemBuilder: (context, index) {
                                    final character = characters[index];
                                    final isSelected = tempSelectedCharacter == character;

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
                                            width: 90,
                                            height: 90,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected ? Colors.blue : Colors.grey.shade400,
                                                width: isSelected ? 3 : 2,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: Image.asset(
                                                character.imagePath,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 158,
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              character.name,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                          Positioned(
                            top: 8,
                            right: 12,
                            child: ElevatedButton(
                              onPressed: tempSelectedCharacter != null
                                  ? () {
                                setState(() {
                                  selectedCharacter = tempSelectedCharacter;
                                  _profileImage = null;
                                });
                                Navigator.pop(context, true);
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: const Size(70, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '완료',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleNicknameEdit() {
    setState(() {
      if (_isEditingNickname) {
        final trimmedNickname = _nicknameController.text.trim();
        if (trimmedNickname.isNotEmpty) {
          nickname = trimmedNickname.length > 10 ? trimmedNickname.substring(0, 10) : trimmedNickname;
          _nicknameController.text = nickname;
        }
      }
      _isEditingNickname = !_isEditingNickname;
      if (!_isEditingNickname) FocusScope.of(context).unfocus();
    });
  }

  void _saveIntroText() {
    setState(() {
      introText = _introController.text.trim();
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('한줄 소개 수정이 완료되었습니다.')),
    );
  }

  void _limitIntroLines() {
    String text = _introController.text;
    List<String> lines = text.split('\n');
    if (lines.length > 3) {
      _introController.text = lines.take(3).join('\n');
      _introController.selection = TextSelection.fromPosition(
        TextPosition(offset: _introController.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // 프로필 이미지
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (_profileImage != null)
                        ? Image.file(_profileImage!, fit: BoxFit.cover)
                        : (selectedCharacter != null
                        ? Image.asset(selectedCharacter!.imagePath, fit: BoxFit.cover)
                        : Image.asset('assets/images/profile.png', fit: BoxFit.cover)),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/images/Setting/Exclude.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 닉네임 입력 칸
            Container(
              width: boxWidth,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F8),
                borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onSubmitted: (_) => _toggleNicknameEdit(),
                    )
                        : Center(
                      child: Text(
                        nickname,
                        style: const TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !_isEditingNickname,
                    child: IconButton(
                      iconSize: 15,
                      icon: Image.asset(
                        'assets/images/Setting/Subtract.png',
                        width: 15,
                        height: 15,
                        fit: BoxFit.contain,
                      ),
                      onPressed: _toggleNicknameEdit,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 한줄소개 입력부
            Container(
              width: boxWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '한줄 소개 (50자 이내)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF807E7E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _introController,
                    maxLength: 50,
                    maxLines: 3,
                    cursorColor: Colors.black,
                    style: const TextStyle(fontSize: 14, color: Colors.black, height: 1.3),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: ElevatedButton(
                      onPressed: _saveIntroText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: const Size(67, 36),
                      ),
                      child: const Text(
                        '수정',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}