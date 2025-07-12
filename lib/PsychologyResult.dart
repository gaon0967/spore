import 'package:flutter/material.dart';
import 'naver_auth/naverAndFirebaseAuth.dart';
import 'HomeCalendar.dart';


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
        imagePath: 'assets/images/ch1_3.png',
        description: '따뜻한 마음으로 주변을 챙기는 당신. 모두에게 힘이 되어주는 존재.',
        keywords: ['# 다정한', '#친절한'],
        color:Color(0xB3A6A6)
        ),
    2: const Character(
        id: 2,
        name: '게으른 철학자',
        speech: '서두를게 뭐가 있어.',
        imagePath: 'assets/images/ch2_4.png',
        description: '세상만사 귀찮지만, 가끔은 누구보다 깊은 생각에 빠지는 반전 매력의 소유자.',
        keywords: ['# 느긋한', '# 여유로운'],
        color:Color(0xCDDEE3)
        ),
    3: const Character(
        id: 3,
        name: '마이웨이',
        speech: '나는 나만의 길을 간다.',
        imagePath: 'assets/images/ch2_1.png',
        description: '주변에 휘둘리지 않고 자신만의 길을 가는 독립적인 스타일. 때로는 고집쟁이.',
        keywords: ['# 독립적인', '# 자유로운'],
        color:Color(0xB3A6A6)
        ),
    4: const Character(
        id: 4,
        name: '해피 바이러스',
        speech: '청바지를 돋보이게 하는 걸음걸이는?',
        imagePath: 'assets/images/ch1_2.png',
        description: '언제나 긍정적이고 유쾌한 에너지로 주변 사람들을 즐겁게 만드는 분위기 메이커.',
        keywords: ['# 창의적인', '# 재미있는'],
        color:Color(0xF4ECD2)
        ),
    5: const Character(
        id: 5,
        name: '과몰입러',
        speech: '🔥🔥🔥🔥🔥🔥🔥🔥🔥',
        imagePath: 'assets/images/ch2_3.png',
        description: '한 번 빠지면 끝을 보는 엄청난 집중력과 열정의 소유자.',
        keywords: ['# 열정적인', '# 도전적인'],
        color: Color(0xCA9E9E)
        ),
    6: const Character(
        id: 6,
        name: '대문자 F',
        speech: '이렇게 말해도 될까? 😟',
        imagePath: 'assets/images/ch2_2.png',
        description: '타인의 감정을 섬세하게 살피고 공감 능력이 뛰어납니다. 상처도 잘 받는 여린 마음.',
        keywords: ['# 공감능력', '# 섬세함'],
        color:Color(0xDDD2DA)
        ),
    7: const Character(
        id: 7,
        name: '정의로운 용사',
        speech:  '나만 믿어, 등 뒤는 내가 지킬게!',
        imagePath: 'assets/images/ch1_1.png',
        description: '불의를 보면 참지 못하고, 체계적이고 계획적으로 문제를 해결하는 리더 타입.',
        keywords: ['# 든든한', '# 안정적인'],
        color:Color(0xE6E6E6)
        
        ),
    8: const Character(
        id: 8,
        name: '명언가',
        speech: '이 노을…. 꼭 너 같아.',
        imagePath: 'assets/images/ch1_4.png',
        description: '현상의 이면을 꿰뚫어 보고 논리적으로 분석하는 것을 즐깁니다. 신중하고 조용한 편.',
        keywords: ['# 감성적인','#섬세한'],
        color:Color(0x7887AD)
        
        ),
  };
  
 
/// 클래스 : Character  
/// 목적 : 캐릭터의 성격 유형 정보로 ID 기반 조회
/// 반환타입 : 데이터 클래스 (getCharacterById는 Character 반환)  
/// 예외 :  
///   - 요청한 ID가 없을 경우 기본 캐릭터 6번 반환 [ 널 반환 없음 → 안정적 ]
  static Character getCharacterById(int id) {
    
    return _characterData[id] ?? _characterData[6]!;
  }
}


/// 클래스 : PsychologyResult  
/// 목적 : 심리테스트 결과 ID에 따라 캐릭터 정보를 화면에 출력하고, 사용자가 '완료' 버튼을 누르면 네이버 로그인/회원가입 홈화면으로 이동  
/// 반환타입 : StatelessWidget  
/// 예외 :  
///   - 이미지 로딩 실패 시 대체 UI 표시  
///   - 로그인 중 에러 발생 가능성 있음 → try-catch로 처리  
///   - 로그인 성공 후 context.mounted 여부 확인 필수  
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
         padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.05), // 두꺼운 검은 색으로 수정.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //  상단 텍스트
              Text('STEP 2', style: TextStyle(fontSize: screenWidth * 0.04,color: Color(0xFF555555),fontWeight: FontWeight.bold )),
              SizedBox(height: screenHeight * 0.01), 
              Text('난 어떤 유형의 사람일까? -', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold)), // <<<
              SizedBox(height: screenHeight * 0.03),

              // 말풍선
              _SpeechBubble(text: character.speech),
             SizedBox(height: screenHeight * 0.02),

              // 캐릭터 이미지
              Image.asset(character.imagePath, height: screenHeight * 0.3, 
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
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(text, style:  TextStyle(fontSize: screenWidth * 0.04)),
    );
  }
}

// 하단 정보 컨테이너 위젯
class _InfoContainer extends StatelessWidget {
  final Character character;
  const _InfoContainer({required this.character});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; 
    return Container(
      padding:  EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // 캐릭터 이름과 완료 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
             crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(character.name, style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                    final authService = AuthService();
                      try {
                          // AuthService에 캐릭터 ID를 전달하며 로그인 및 저장 프로세스 실행
                        final userData = await authService.signInWithNaver(
                          characterId: character.id,
                        );

                        if (!context.mounted) return; // 위젯이 화면에 없으면 중단

 

                       //화면 전환 
                        Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeCalendar()),
                       );

                        

                        } catch (e) {
                            // 로그인 실패 또는 사용자가 취소했을 때의 처리
                          print(" 로그인 실패: $e");
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("로그인에 실패했습니다. 다시 시도해주세요.")),
                      );
                     }
                    }
                   },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF555555),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.03),
                ),
                child: Text('완료', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
         SizedBox(height: screenWidth * 0.05),
          // 캐릭터 소개 & 키워드 카드
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCard(
                  title: '캐릭터 소개',
                  content: Text(character.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ),
             SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _InfoCard(
                  title: 'Keyword',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: character.keywords
                        .map((keyword) => Text(keyword, style: const TextStyle(fontSize: 15, height: 1.6)))
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

// 소개 & 키워드 카드 위젯
class _InfoCard extends StatelessWidget {
  final String title;
  final Widget content;

  const _InfoCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding:  EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
           SizedBox(height: screenWidth * 0.03),
          content,
        ],
      ),
    );
  }
}