import 'package:flutter/material.dart';
import '../../auth/naverAndFirebaseAuth.dart';
import 'package:new_project_1/features/Home/main_screen.dart';
import '../Settings/TitleHandler.dart';
import 'package:new_project_1/features/Settings/firebase_title.dart' as TitlesRemote;

// --- 데이터 모델 및 저장소 ---
class Character {
  final int id;
  final String name;
  final String speech;
  final String imagePath;
  final String description;
  final List<String> keywords;
  final Color color; // 추가

  const Character({
    required this.id,
    required this.name,
    required this.speech,
    required this.imagePath,
    required this.description,
    required this.keywords,
    required this.color,
  });

  // 모든 캐릭터 데이터를 Map 형태로 보관
  static final Map<int, Character> _characterData = {
    1: const Character(
      id: 1,
      name: '마더테레사',
      speech: '오늘은 무슨 일 있었어?',
      imagePath: 'assets/images/PsychologyTest/Character/ch1_3.png',
      description: '따뜻한 마음으로 주변을 챙기는 당신. 모두에게 힘이 되어주는 존재.',
      keywords: ['# 다정한', '#친절한'],
      color: Color(0xFFB3A6A6),
    ),
    2: const Character(
      id: 2,
      name: '게으른 철학자',
      speech: '서두를게 뭐가 있어.',
      imagePath: 'assets/images/PsychologyTest/Character/ch2_4.png',
      description: '세상만사 귀찮지만, 가끔은 누구보다 깊은 생각에 빠지는 반전 매력의 소유자.',
      keywords: ['# 느긋한', '# 여유로운'],
      color: Color(0xFFCDDEE3),
    ),
    3: const Character(
      id: 3,
      name: '마이웨이',
      speech: '나는 나만의 길을 간다.',
      imagePath: 'assets/images/PsychologyTest/Character/ch2_1.png',
      description: '주변에 휘둘리지 않고 자신만의 길을 가는 독립적인 스타일. 때로는 고집쟁이.',
      keywords: ['# 독립적인', '# 자유로운'],
      color: Color(0xFFB3A6A6),
    ),
    4: const Character(
      id: 4,
      name: '해피 바이러스',
      speech: '청바지를 돋보이게 하는 걸음걸이는?',
      imagePath: 'assets/images/PsychologyTest/Character/ch1_2.png',
      description: '언제나 긍정적이고 유쾌한 에너지로 주변 사람들을 즐겁게 만드는 분위기 메이커.',
      keywords: ['# 창의적인', '# 재미있는'],
      color: Color(0xFFF4ECD2),
    ),
    5: const Character(
      id: 5,
      name: '과몰입러',
      speech: '🔥🔥🔥🔥🔥🔥🔥🔥🔥',
      imagePath: 'assets/images/PsychologyTest/Character/ch2_3.png',
      description: '한 번 빠지면 끝을 보는 엄청난 집중력과 열정의 소유자.',
      keywords: ['# 열정적인', '# 도전적인'],
      color: Color(0xFFCA9E9E),
    ),
    6: const Character(
      id: 6,
      name: '대문자 F',
      speech: '이렇게 말해도 될까? 😟',
      imagePath: 'assets/images/PsychologyTest/Character/ch2_2.png',
      description: '타인의 감정을 섬세하게 살피고 공감 능력이 뛰어납니다. 상처도 잘 받는 여린 마음.',
      keywords: ['# 공감능력', '# 섬세함'],
      color: Color(0xFFDDD2DA),
    ),
    7: const Character(
      id: 7,
      name: '정의로운 용사',
      speech: '나만 믿어, 등 뒤는 내가 지킬게!',
      imagePath: 'assets/images/PsychologyTest/Character/ch1_1.png',
      description: '불의를 보면 참지 못하고, 체계적이고 계획적으로 문제를 해결하는 리더 타입.',
      keywords: ['# 든든한', '# 안정적인'],
      color: Color(0xFFE6E6E6),
    ),
    8: const Character(
      id: 8,
      name: '명언가',
      speech: '이 노을…. 꼭 너 같아.',
      imagePath: 'assets/images/PsychologyTest/Character/ch1_4.png',
      description: '현상의 이면을 꿰뚫어 보고 논리적으로 분석하는 것을 즐깁니다. 신중하고 조용한 편.',
      keywords: ['# 감성적인', '#섬세한'],
      color: Color(0xFF7887AD),
    ),
  };

  // ID로 캐릭터 정보를 찾아주는 함수
  static Character getCharacterById(int id) {
    return _characterData[id] ?? _characterData[6]!;
  }
}

// --- 결과 화면 위젯 ---

class PsychologyResult extends StatelessWidget {
  final int resultId;

  const PsychologyResult({super.key, required this.resultId});

  @override
  Widget build(BuildContext context) {
    // 전달받은 resultId로 해당하는 캐릭터 정보를 찾아옵니다.
    final Character character = Character.getCharacterById(resultId);
    // 반응형을 위한 코드 수정  _ 가령
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.05,
          ), // 두꺼운 검은 색으로 수정.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 상단 텍스트
              const Text(
                'STEP 2',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '난 어떤 유형의 사람일까? -',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 말풍선
              _SpeechBubble(text: character.speech),
              SizedBox(height: screenHeight * 0.02),

              // 3. 캐릭터 이미지
              Image.asset(
                character.imagePath,
                height: 250,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: screenHeight * 0.3,
                    width: screenWidth * 0.5,
                    color: Colors.grey[200],
                    child: const Center(child: Text('이미지 없음')),
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.03),

              // 하단 정보 카드
              _InfoContainer(character: character),
            ],
          ),
        ),
      ),
    );
  }
}

/// 클래스 : _SpeechBubble
/// 목적 : 캐릭터의 대사를 말풍선 형태로 출력
/// 반환타입 : StatelessWidget
/// 예외 : 없음

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(text, style: TextStyle(fontSize: screenWidth * 0.04)),
    );
  }
}

// 하단 정보 컨테이너 위젯 // 하단 정보 컨테이너 위젯 (레이아웃이 수정된 버전)
class _InfoContainer extends StatelessWidget {
  final Character character;


  const _InfoContainer({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    // 화면 너비를 기준으로 반응형 UI를 구성합니다.
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      // 캐릭터별 고유 색상이 적용된 전체 배경
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: character.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // --- 제목 카드와 완료 버튼을 포함하는 새로운 Row ---
          Row(
            children: [
              // 1. 제목을 담는 카드 (남는 공간을 모두 차지)
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.038),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50), // 둥근 모서리
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      character.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. 카드와 버튼 사이의 간격
              SizedBox(width: screenWidth * 0.03),

              // 3. 완료 버튼
              ElevatedButton(
                onPressed: () async {
                  final authService = AuthService();
                  try {
                    final userData = await authService.signInWithNaver(
                      character.id,
                    );
                    // 심리테스트 타이틀 지급(firestore) - 로컬 동기화 포함
                    await TitlesRemote.SavePsychologyTestCompletion();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  } catch (e) {
                    print(" 로그인 실패: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("로그인에 실패했습니다. 다시 시도해주세요."),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF555555),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenWidth * 0.03,
                  ),
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // 카드들 사이의 간격
          SizedBox(height: screenWidth * 0.04),

          // 캐릭터 소개 & 키워드 카드 (기존 구조 유지)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCard(
                  title: '캐릭터 소개',
                  content: Text(
                    character.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _InfoCard(
                  title: 'Keyword',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                    character.keywords
                        .map(
                          (keyword) => Text(
                        keyword,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 소개 & 키워드 카드 위젯 (이 위젯은 수정할 필요가 없습니다)
class _InfoCard extends StatelessWidget {
  final String title;
  final Widget content;

  const _InfoCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity, // Expanded 위젯 안에서 너비를 꽉 채우도록 설정
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.045,
        vertical: screenWidth * 0.05,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}