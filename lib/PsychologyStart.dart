import 'package:flutter/material.dart';
import 'PsychologyQuestion.dart';

// 캐릭터 담는 클래스
class CharacterInfo {
  final String name;
  
  final String imagePath;

  const CharacterInfo({
    required this.name,
    
    required this.imagePath,
  });
}

// 캐릭터 데이터 리스트
const List<CharacterInfo> characterData = [
  CharacterInfo(name: '정의로운 용사', imagePath: 'assets/images/1_1.png'),
  CharacterInfo(name: '마이웨이', imagePath: 'assets/images/2_1.png'),
  CharacterInfo(name: '해피 바이러스',  imagePath: 'assets/images/1_2.png'),
  CharacterInfo(name: '대문자 F', imagePath: 'assets/images/2_2.png'),
  CharacterInfo(name: '마더테레사', imagePath: 'assets/images/1_3.png'),
  CharacterInfo(name: '과몰입러', imagePath: 'assets/images/2_3.png'),
  CharacterInfo(name: '명연가', imagePath: 'assets/images/1_4.png'),
  CharacterInfo(name: '게으른 철학자',  imagePath: 'assets/images/2_4.png'),
];


class PsychologyStart extends StatelessWidget {
  const PsychologyStart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // 모든 콘텐츠를 포함하는 기본 Column
          child: Column(
            // Column 내 위젯들의 정렬 및 간격 조절
            mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Spacer(flex: 2), // 상단 공간
              _StepTitle(),
              SizedBox(height: 12),
              _MainTitle(),
              SizedBox(height: 30), // 타이틀과 그리드 사이 간격 줄임
              _CharacterGrid(),
              Spacer(flex: 3), // 그리드와 버튼 사이 공간
              _StartButton(),
              Spacer(flex: 1), // 하단 공간
            ],
          ),
        ),
      ),
    );
  }
}

// "STEP 1" 텍스트 위젯
class _StepTitle extends StatelessWidget {
  const _StepTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'STEP 1',
      style: TextStyle(
        fontSize: 18,
        color: const Color(0xFF95A797),
        fontWeight: FontWeight.w500, // Medium
      ),
    );
  }
}

// 메인 타이틀 위젯
class _MainTitle extends StatelessWidget {
  const _MainTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      '나의 성격 유형을 알고\n같은 유형의 사람을 찾아가는 여정',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'GolosText', // 'GolosText'를 따옴표로 감싸줍니다.
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5F5F5F),
        height: 1.5,
      ),
    );
  }
}

// 캐릭터 그리드 위젯
// 캐릭터 그리드 위젯
class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 8,
      ),
      itemCount: characterData.length,
      itemBuilder: (context, index) {
        final character = characterData[index];
        return _CharacterItem(character: character);
      },
    );
  }
}

// 개별 캐릭터 아이템 위젯
class _CharacterItem extends StatelessWidget {
  final CharacterInfo character;

  const _CharacterItem({required this.character});

  @override
  Widget build(BuildContext context) {
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
              )
            ],
          ),
          child: Text(
            character.name,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// "심리테스트 하러 가기" 버튼 위젯
class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
       Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PsychologyQuestion()),
         );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E5656),
        foregroundColor: const Color(0xFF6B6060), // 눌렀을 때 색 (splash)
        minimumSize: const Size(274, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
        ),
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
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }
}