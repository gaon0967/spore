import 'package:flutter/material.dart';
import 'PsychologyQuestion.dart';

//수정 : 반응형으로 고쳤는데 문제가 스트롤 처리를 안하면 화면안에서 캐릭터가 잘림.

// 캐릭터 담는 클래스
/// 클래스 : CharacterInfo
/// 목적 : 캐릭터의 이름과 이미지 경로를 담는 용도.
/// 반환타입 : 해당 없음
/// 예외 : 없음
class CharacterInfo {
  final String name;

  final String imagePath;

  const CharacterInfo({required this.name, required this.imagePath});
}

// 캐릭터 데이터 리스트
const List<CharacterInfo> characterData = [
  CharacterInfo(name: '정의로운 용사', imagePath: 'assets/images/1_1.png'),
  CharacterInfo(name: '마이웨이', imagePath: 'assets/images/2_1.png'),
  CharacterInfo(name: '해피 바이러스', imagePath: 'assets/images/1_2.png'),
  CharacterInfo(name: '대문자 F', imagePath: 'assets/images/2_2.png'),
  CharacterInfo(name: '마더테레사', imagePath: 'assets/images/1_3.png'),
  CharacterInfo(name: '과몰입러', imagePath: 'assets/images/2_3.png'),
  CharacterInfo(name: '명연가', imagePath: 'assets/images/1_4.png'),
  CharacterInfo(name: '게으른 철학자', imagePath: 'assets/images/2_4.png'),
];

class PsychologyStart extends StatelessWidget {
  const PsychologyStart({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.06;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.spaceAround, // 반응형
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.04),
                const _StepTitle(),
                const SizedBox(height: 12),
                const _MainTitle(),
                const SizedBox(height: 30),

                _CharacterGrid(),
                SizedBox(height: size.height * 0.05),
                const _StartButton(),
                SizedBox(height: size.height * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 클래스 : PsychologyStart
/// 목적 : 심리테스트 시작 화면   "STEP 1"
/// 반환타입 : StatelessWidget (Scaffold 반환)
/// 예외 : 없음
class _StepTitle extends StatelessWidget {
  const _StepTitle();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Text(
      'STEP 1',
      style: TextStyle(
        fontSize: size.width * 0.045,
        color: const Color(0xFF95A797),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// 클래스 : _MainTitle
/// 목적 : 심리테스트 설명  출력
/// 반환타입 : StatelessWidget (Text 반환)
/// 예외 : 없음
class _MainTitle extends StatelessWidget {
  const _MainTitle();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width * 0.05;

    return Text(
      '나의 성격 유형을 알고\n같은 유형의 사람을 찾아가는 여정',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'GolosText',
        fontSize: fontSize.clamp(16, 28).toDouble(),
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5F5F5F),
        height: 1.5,
      ),
    );
  }
}

/// 클래스 : _CharacterGrid
/// 목적 : 여러 개의 캐릭터 선택지를 2열 그리드로 화면에 표시
/// 반환타입 : StatelessWidget (GridView 반환)
/// 예외 : 없음

class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final crossAxisCount = isWide ? 4 : 2;
    final aspectRatio = isWide ? 1.1 : 1.3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
      ),
      itemCount: characterData.length,
      itemBuilder: (context, index) {
        final character = characterData[index];
        return _CharacterItem(character: character);
      },
    );
  }
}

/// 클래스 : _CharacterItem
/// 목적 : 단일 캐릭터(이름 + 이미지)를 카드 형태로 화면에 표시 하는 약할
/// 반환타입 : StatelessWidget (Column 반환)
/// 예외 : 없음.
class _CharacterItem extends StatelessWidget {
  final CharacterInfo character;

  const _CharacterItem({required this.character});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageSize = size.width * 0.18; // 화면 폭의 18%
    final labelFontSize = size.width * 0.032; // 화면 폭의 3.2%

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 캐릭터 이미지
        Image.asset(
          character.imagePath,

          width: 80,
          height: 80,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        // 캐릭터 이름 라벨
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            character.name,
            style: TextStyle(
              fontSize: labelFontSize.clamp(10, 16),
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 클래스 : _StartButton
/// 목적 : 심리테스트 질문 페이지로 이동하는 버튼
/// 반환타입 : StatelessWidget (ElevatedButton 반환)
/// 예외 : 예외 처리 없음.  (+ 경로 없으면 예외 되게 추가할 예정 )
class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonWidth = size.width * 0.7;
    final buttonHeight = size.height * 0.07;
    final fontSize = size.width * 0.045;

    return ElevatedButton(
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PsychologyQuestion()));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E5656),
        foregroundColor: const Color(0xFF6B6060), // 눌렀을 때 색 (splash)
        minimumSize: const Size(274, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '심리테스트 하러 가기',
            style: TextStyle(
              fontFamily: 'GolosText', // 'GolosText'를 따옴표로 감싸줍니다.
              fontSize: 18,
              fontWeight: FontWeight.w600, // Semibold
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
