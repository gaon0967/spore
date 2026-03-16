import 'package:flutter/material.dart';
import '../../auth/naverAndFirebaseAuth.dart';
import 'package:spore/features/Home/main_screen.dart';
import '../Settings/TitleHandler.dart';
import 'package:spore/features/Settings/firebase_title.dart' as TitlesRemote;

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
      speech: '활활 타오른다!!!',
      imagePath: 'assets/images/PsychologyTest/Character/ch2_3.png',
      description: '한 번 빠지면 끝을 보는 엄청난 집중력과 열정의 소유자.',
      keywords: ['# 열정적인', '# 도전적인'],
      color: Color(0xFFCA9E9E),
    ),
    6: const Character(
      id: 6,
      name: '대문자F',
      speech: '나 우울해서 방 샀어...',
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
  final bool isReTest;
  const PsychologyResult({super.key, required this.resultId, this.isReTest = false});
  
@override
  Widget build(BuildContext context) {
    final Character character = Character.getCharacterById(resultId);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final Height = size.height;
    double designWidth = size.width; 
    final double scale = size.width / designWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.06),
                    // --- STEP 2: 재검사가 아닐 때만 STEP 1과 동일한 스타일로 표시 ---
                    if (!isReTest) ...[
                      Padding(
                        padding: EdgeInsets.only(top: size.height * 0.02268), // STEP 1과 동일한 top 위치
                        child: SizedBox(
                          width: screenWidth * 0.49815,
                          child: Center(
                            child: Text(
                              'STEP 2',
                              style: TextStyle(
                                fontFamily: 'GolosText',
                                fontWeight: FontWeight.w500,
                                fontSize: screenWidth*0.044955,
                                color: const Color(0xFF555555), // STEP 1과 동일 색상
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.009072),
                    ] else ...[
                       // 재검사일 때는 상단 여백만 살짝 줌
                       SizedBox(height: size.height * 0.06),
                    ],

                    Text(
                      '난 어떤 유형의 사람일까? -',
                      style: TextStyle(
                        fontSize: screenWidth * 0.0486,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5F5F5F),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04536),
                    
                    _SpeechBubble(text: character.speech),
                    
                    SizedBox(height: size.height * 0.01),
                    
                    // 캐릭터 이미지 + 블러 그림자 영역
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 바닥 그림자 (Ellipse 15) - 위로 올리고 블러 대폭 강화
                        Positioned(
                          bottom: size.height*0.02835, // 그림자 위치를 더 위로 올림
                          child: Container(
                            width: screenWidth*0.40581,
                            height: size.height*0.063504,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEEEEEE).withOpacity(0.9),
                                  blurRadius: 30, // 블러 처리 추가
                                  spreadRadius: 10,
                                ),
                              ],
                              color: const Color(0xFFEEEEEE).withOpacity(0.5),
                              borderRadius: BorderRadius.all(Radius.elliptical(167, 56)),
                            ),
                          ),
                        ),
                        Image.asset(
                          character.imagePath,
                          height: screenWidth*0.8262,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // 하단 정보 박스
            _InfoContainer(character: character),
          ],
        ),
      ),
    );
  }
}

// --- 에러 방지를 위해 클래스 외부로 분리 ---
class SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 그림자 설정
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    const double radius = 20.0;
    double tailWidth = size.width * 0.02916; // 꼬리의 너비
    double tailHeight = size.height*0.01134;
    
    // 꼬리가 시작되는 높이 오프셋 (값이 커질수록 위로 올라감)
    // 전체 높이(size.height)에서 이만큼 뺀 지점에 꼬리가 붙습니다.
    double tailYOffset = size.height * 0.020412; 

    // 1. 메인 말풍선 몸체 (둥근 사각형)
    path.addRRect(RRect.fromLTRBAndCorners(
      0, 0, size.width, size.height,
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: const Radius.circular(radius),
      bottomRight: const Radius.circular(radius), // 몸체는 일단 다 둥글게
    ));

    // 2. 오른쪽 "좀 더 위"에 붙는 꼬리 경로 추가
    // 오른쪽 변(size.width)의 하단에서 tailYOffset만큼 올라온 지점
    path.moveTo(size.width - 2, size.height - tailYOffset); 
    path.lineTo(size.width + tailWidth, size.height - tailYOffset + 5); 
    path.lineTo(size.width - 2, size.height - tailYOffset + 12);
    path.close();

    // 그림자 레이어
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    // 흰색 몸체 레이어
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- 결과 화면에서 호출되는 말풍선 위젯 ---
class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CustomPaint(
      painter: SpeechBubblePainter(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size.width*0.05346, vertical: size.height*0.013608),
        child: Text(
          text,
          style: TextStyle(
            fontSize: size.width*0.03645,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7E7B7B),
          ),
        ),
      ),
    );
  }
}

class _InfoContainer extends StatelessWidget {
  final Character character;
  const _InfoContainer({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      // 1. 박스 자체를 화면 양옆에서 띄우기 위해 margin 추가 
      margin:EdgeInsets.fromLTRB(size.width*0.05103, 0, size.width*0.05103, 0), 
      // 2. 내부 요소들과의 간격
      padding: EdgeInsets.fromLTRB(size.width*0.05103, size.height*0.02835, size.width*0.05103, bottomPadding > 0 ? size.height*0.00567 : size.height*0.01134),
      decoration: BoxDecoration(
        color: character.color, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2), // 위쪽으로 살짝 그림자
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이름표와 완료 버튼 Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: size.height*0.063504,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    character.name,
                    style: TextStyle(
                      fontSize: size.width*0.04374,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
              ),
              SizedBox(width: size.width*0.02916),
              GestureDetector(
                onTap: () async {
                  final authService = AuthService(); //
                  try {
                    // 1. 네이버 로그인 및 데이터 저장
                    await authService.signInWithNaver(character.id); //
                    
                    // 2. 심리테스트 완료 칭호 지급
                    await TitlesRemote.SavePsychologyTestCompletion(); //

                    if (!context.mounted) return; //

                    // 3. 홈 화면으로 이동 (기존의 모든 경로를 제거하고 MainScreen을 새로 띄움)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                      (route) => false, // 이 조건이 false면 이전의 모든 화면을 스택에서 지웁니다.
                    );
                  } catch (e) {
                    debugPrint("로그인 및 홈 이동 실패: $e"); //
                  }
                },
                child: Container(
                  width: size.width*0.1944,
                  height: size.height*0.054432,
                  decoration: BoxDecoration(
                    color: const Color(0xFF494444), //
                    borderRadius: BorderRadius.circular(999), //
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: Colors.white, //
                      fontSize: size.width*0.03402, //
                      fontWeight: FontWeight.w700, //
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: size.height*0.018144),
          Container(
            width: double.infinity,
            height: 0.5,
            color: const Color(0xFF665E5E),
          ),
          SizedBox(height: size.height*0.018144),
          // 상세 카드 Row
          Row(
            children: [
              _ResultDetailCard(title: '캐릭터 소개', content: character.description, height: size.height*0.13608),
              SizedBox(width: size.width*0.02916),
              _ResultDetailCard(
                title: 'Keyword',
                content: character.keywords.join('\n'),
                isKeyword: true,
                height: size.height*0.13608,
              ),
            ],
          ),
          // 기기 하단 노치 대응 여백
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

class _ResultDetailCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isKeyword;
  final double height;

  const _ResultDetailCard({
    required this.title,
    required this.content,
    this.isKeyword = false,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Expanded(
      child: Container(
        height: size.height*0.13041, // 전달받은 높이 적용
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: size.height*0.036288, // 헤더 높이도 살짝 축소
              color: const Color(0xFFF1F1F1),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: size.width*0.03645),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: size.width*0.032805,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                alignment: isKeyword ? Alignment.centerLeft : Alignment.center,
                child: Text(
                  content,
                  textAlign: isKeyword ? TextAlign.left : TextAlign.left,
                  style: TextStyle(
                    fontSize: 0.030375 * size.width,
                    color: Color(0xFF4A4A4A),
                    height: size.height*0.0013608,          
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}