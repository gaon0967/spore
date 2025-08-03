import 'package:flutter/material.dart';
import 'dart:math';
import 'PsychologyQuestion.dart';

class CharacterInfo {
  final String name;
  final String bgImagePath; // 컬러 도형 png
  const CharacterInfo({required this.name, required this.bgImagePath});
}

const List<CharacterInfo> characterData = [
  // 사진 경로 입력
  CharacterInfo(
    name: '정의로운 용사',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-1.png',
  ),
  CharacterInfo(
    name: '마이웨이',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-1.png',
  ),
  CharacterInfo(
    name: '해피 바이러스',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-2.png',
  ),
  CharacterInfo(
    name: '대문자 F',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-2.png',
  ),
  CharacterInfo(
    name: '마더테레사',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-3.png',
  ),
  CharacterInfo(
    name: '과몰입러',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-3.png',
  ),
  CharacterInfo(
    name: '명연가',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-4.png',
  ),
  CharacterInfo(
    name: '게으른 철학자',
    bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-4.png',
  ),
];

class _CharacterLayout {
  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;

  const _CharacterLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
  });
}

const _characterLayouts = [
  // 크기 디자인과 최대한 유사하게 수정. 각도는 디자인과 달라서 임의로 테스트해가면서 바꿈.
  _CharacterLayout(
    left: 44,
    top: 188.88,
    width: 199,
    height: 92,
    angle: -3.83,
  ), // 정의로운 용사
  _CharacterLayout(
    left: 215,
    top: 195,
    width: 185,
    height: 110,
    angle: -10,
  ), // 마이웨이
  _CharacterLayout(
    left: 15,
    top: 277.66,
    width: 225,
    height: 98,
    angle: -3.1,
  ), // 해피 바이러스
  _CharacterLayout(
    left: 227.46,
    top: 328.35,
    width: 176,
    height: 92,
    angle: 2.5,
  ), // 대문자 F
  _CharacterLayout(
    left: 24.73,
    top: 374,
    width: 178,
    height: 82,
    angle: -1.85,
  ), // 마더테레사
  _CharacterLayout(
    left: 226.32,
    top: 425.08,
    width: 156,
    height: 66,
    angle: 3.5,
  ), // 과몰입러
  _CharacterLayout(
    left: 47.65,
    top: 462.39,
    width: 150,
    height: 100,
    angle: -2.42,
  ), // 명연가
  _CharacterLayout(
    left: 219.75,
    top: 487.24,
    width: 135,
    height: 90,
    angle: 1.63,
  ), // 게으른 철학자
];

class PsychologyStart extends StatelessWidget {
  const PsychologyStart({super.key});

  static const double _designWidth = 411;
  static const double _designHeight = 731;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final scaleW = size.width / _designWidth;
    final scaleH = size.height / _designHeight;

    final scale = min(scaleW, scaleH);

    final scaledWidth = _designWidth * scale;
    final scaledHeight = _designHeight * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: scaledWidth,
                height: scaledHeight,
                child: Stack(
                  children: [
                    // Each character shape and name is positioned and scaled uniformly.
                    for (int i = 0; i < characterData.length; i++)
                      Positioned(
                        left: _characterLayouts[i].left * scale,
                        top: _characterLayouts[i].top * scale,
                        child: Transform.rotate(
                          angle: _characterLayouts[i].angle * 3.141592 / 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                characterData[i].bgImagePath,
                                width: _characterLayouts[i].width * scale,
                                height: _characterLayouts[i].height * scale,
                                fit: BoxFit.fill,
                              ),
                              Container(
                                width: _characterLayouts[i].width * scale,
                                height: _characterLayouts[i].height * scale,
                                alignment: Alignment.center,
                                child: Text(
                                  characterData[i].name,
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    color: const Color(0xFF5F5F5F),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'GolosText',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Positioned(
                      left: 119.92 * scale,
                      top: 279.49 * scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/PsychologyTest/Character/TestStart_Character.png',
                            width: 187.91 * scale,
                            height: 204.1 * scale,
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            // 추가 : 물음표 위치를 조정하기 위해서
                            left: ((187.91 - 45) / 2) * scale,
                            // (캐릭터 높이 / 2) - (물음표 높이 / 2) - (시각적 보정값)
                            top: 55 * scale,
                            child: Image.asset(
                              'assets/images/PsychologyTest/Character/QuestionMark.png',
                              width: 20 * scale, // 40-> 15
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // STEP 1 header
                    Positioned(
                      left: ((_designWidth - 205) / 2) * scale,
                      top: 20 * scale,
                      child: SizedBox(
                        width: 205 * scale,
                        child: Center(
                          child: Text(
                            'STEP 1',
                            style: TextStyle(
                              fontFamily: 'GolosText',
                              fontWeight: FontWeight.w500,
                              fontSize: 18.5 * scale,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Main title
                    Positioned(
                      left: ((_designWidth - 304) / 2) * scale,
                      top: 70 * scale,
                      child: SizedBox(
                        width: 304 * scale,
                        child: Center(
                          child: Text(
                            '나의 성격 유형을 알고\n같은 유형의 사람을 찾아가는 여정-',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'GolosText',
                              fontWeight: FontWeight.bold,
                              fontSize: 20 * scale,
                              color: const Color(0xFF5F5F5F),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.08),
                child: SizedBox(
                  width: size.width * 0.75, // 너비를 화면의 75%로 줄였습니다.
                  height: size.height * 0.07,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PsychologyQuestion(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B6060),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 사람 아이콘과 옆의 공백(SizedBox)을 제거했습니다.
                        Text(
                          '심리테스트 하러 가기',
                          style: TextStyle(
                            fontFamily: 'GolosText',
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w600,
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
