import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
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
    case 1: return 'assets/images/Setting/chac1.png';
    case 2: return 'assets/images/Setting/chac2.png';
    case 3: return 'assets/images/Setting/chac3.png';
    case 4: return 'assets/images/Setting/chac4.png';
    case 5: return 'assets/images/Setting/chac5.png';
    case 6: return 'assets/images/Setting/chac6.png';
    case 7: return 'assets/images/Setting/chac7.png';
    case 8: return 'assets/images/Setting/chac8.png';
    default:
      return 'assets/images/profile.png';
  }
}

/// 클래스: ImagePickerMenu
/// 목적: 프로필 이미지 선택 메뉴를 제공하여 사용자가 갤러리에서 사진을 선택하거나 내 캐릭터로 프로필 이미지를 변경할 수 있도록 하는 UI 위젯
/// 반환: StatefulWidget 인스턴스 반환
/// 예외: 없음
class ImagePickerMenu extends StatefulWidget {
  final Function(int) onSelect;
  const ImagePickerMenu({super.key, required this.onSelect});

  @override
  State<ImagePickerMenu> createState() => _ImagePickerMenuState();
}

/// 클래스: _ImagePickerMenuState
/// 목적: ImagePickerMenu의 상태 관리 및 UI 빌드
/// 반환: State<ImagePickerMenu> 인스턴스 반환
/// 예외: 없음
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
                    const Text('갤러리에서 선택', style: TextStyle(color: Color(0xFF837C7C), fontSize: 15, fontWeight: FontWeight.w500)),
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
                    const Text('내 캐릭터 선택', style: TextStyle(color: Color(0xFF837C7C), fontSize: 15, fontWeight: FontWeight.w500)),
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

/// 클래스: ProfileEdit
/// 목적: 프로필 편집 화면을 구성하는 StatefulWidget
/// 반환: StatefulWidget 인스턴스 반환
/// 예외: 없음
class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditPageState();
}
String? _bottomMessage;
bool _showBottomMessage = false;

/// 클래스: _ProfileEditPageState
/// 목적: ProfileEdit에서 상태 관리, Firestore와 데이터 연동, 이미지 업로드, 닉네임 및 한줄 소개 편집 기능을 제공
/// 반환: State<ProfileEdit> 인스턴스 반환
/// 예외: Firestore 접근 실패, 이미지 업로드 실패 등의 예외 처리 필요
class _ProfileEditPageState extends State<ProfileEdit> {
  String nickname = "닉네임을 입력하세요";
  String introText = "";
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker picker = ImagePicker();

  bool _isEditingNickname = false;
  late TextEditingController _nicknameController;

  List<int> psychologyResultIds = [];
  List<Character> availableCharacters = [];
  Character? selectedCharacter;
  String userId = '';

  static const String psychologyResultKey = 'psychology_result_ids';
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

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: nickname);

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

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
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
          _profileImage = null;
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
            nickname = data['nickname'] ?? nickname;
            introText = data['intro'] ?? introText;
            _nicknameController.text = nickname;
            _profileImageUrl = data['profileImageUrl'];
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
      _profileImage = null;
    });
  }

  // 이미지 선택 및 업로드
  Future<void> _pickAndUploadProfileImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    try {
      final ref = FirebaseStorage.instance.ref().child('userImages/${user.uid}/profile.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImageUrl': url,
      }, SetOptions(merge: true));

      setState(() {
        _profileImage = file;
        _profileImageUrl = url;
      });
      _showCenteredMessageDialog('프로필 변경이 완료되었습니다.');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('사진 업로드 실패: $e')));
      }
    }

  // 갤러리 권한 요청 후 이미지 선택
  Future<void> _pickImageFromGallery() async {
    final status = await Permission.photos.status;
    if (status.isGranted) {
      await _pickAndUploadProfileImage();
    } else if (status.isDenied) {
      final result = await Permission.photos.request();
      if (result.isGranted) {
        await _pickAndUploadProfileImage();
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
        content:
        const Text('갤러리 권한이 거부되었습니다. 앱 설정에서 권한을 허용해 주세요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소')),
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
                      if (availableCharacters.isNotEmpty) {
                        setState(() {
                          selectedCharacter = availableCharacters.first;
                          _profileImage = null;
                        });
                        _saveSelectedCharacterId();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("이미 변경되었습니다.")),
                        );
                      }
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
        _showCenteredMessageDialog('닉네임 수정이 완료되었습니다.');
        _showBottomMessage = true;
      });

      _saveProfileToFirestore();
      FocusScope.of(context).unfocus();
      _hideBottomMessageAfterDelay();
    }
  }

  void _finishIntroEdit(TextEditingController controller) {
    setState(() {
      introText = controller.text.trim();
      _showCenteredMessageDialog('한줄 소개 수정이 완료되었습니다');
      _showBottomMessage = true;
    });
    _saveProfileToFirestore();
    Navigator.pop(context);
    _hideBottomMessageAfterDelay();
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
                onSubmitted: (_) => _finishIntroEdit(controller),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => _finishIntroEdit(controller),
                child: const Text('완료'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _hideBottomMessageAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showBottomMessage = false;
          _bottomMessage = null;
        });
      }
    });
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

  Future<void> _saveProfileToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nickname': nickname,
        'intro': introText,
      }, SetOptions(merge: true));
      _showCenteredMessageDialog('닉네임 변경이 완료되었습니다.');
    } catch (e) {
      _showCenteredMessageDialog('닉네임 저장 실패');
    }
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
                      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final data = snapshot.data!.data() as Map<String, dynamic>?;

                        final charId = data?['characterId'] as int? ?? 0; // 안전하게 접근

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
            const SizedBox(height: 30),
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
            const SizedBox(height: 20),
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
                  const SizedBox(height: 15),
                  _introWithUnderline(introText, TextStyle(fontSize: screenWidth * 0.038, color: Colors.black87)),
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