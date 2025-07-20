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
  CharacterInfo(name: '정의로운 용사', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-1.png'),
  CharacterInfo(name: '마이웨이', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-1.png'),
  CharacterInfo(name: '해피 바이러스', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-2.png'),
  CharacterInfo(name: '대문자 F', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-2.png'),
  CharacterInfo(name: '마더테레사', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-3.png'),
  CharacterInfo(name: '과몰입러', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-3.png'),
  CharacterInfo(name: '명연가', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle1-4.png'),
  CharacterInfo(name: '게으른 철학자', bgImagePath: 'assets/images/PsychologyTest/Shape/Rectangle2-4.png'),
];

// A data class for better readability of layout properties.
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

// 도형+텍스트 좌표 (Figma 411x731 기준)
const _characterLayouts = [
  _CharacterLayout(left: 81.5, top: 214.88, width: 124, height: 40, angle: -3.83),    // 정의로운 용사
  _CharacterLayout(left: 229.97, top: 223.83, width: 124, height: 40, angle: -35.42), // 마이웨이
  _CharacterLayout(left: 30.58, top: 306.66, width: 124, height: 40, angle: -3.1),    // 해피 바이러스
  _CharacterLayout(left: 253.46, top: 354.35, width: 124, height: 40, angle: 4.33),   // 대문자 F
  _CharacterLayout(left: 51.73, top: 395, width: 124, height: 40, angle: -1.85),      // 마더테레사
  _CharacterLayout(left: 242.32, top: 438.08, width: 124, height: 40, angle: 6.47),   // 과몰입러
  _CharacterLayout(left: 60.65, top: 492.39, width: 124, height: 40, angle: -2.42),   // 명연가
  _CharacterLayout(left: 222.75, top: 512.24, width: 124, height: 40, angle: 1.63),   // 게으른 철학자
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
                          Image.asset(
                            'assets/images/PsychologyTest/Character/QuestionMark.png',
                            width: 40 * scale,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    // STEP 1 header
                    Positioned(
                      left: ((_designWidth - 205) / 2) * scale,
                      top: 28 * scale,
                      child: SizedBox(
                        width: 205 * scale,
                        child: Center(
                          child: Text(
                            'STEP 1',
                            style: TextStyle(
                              fontFamily: 'GolosText',
                              fontWeight: FontWeight.w500,
                              fontSize: 18.5 * scale,
                              color: const Color(0xFF95A797),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Main title
                    Positioned(
                      left: ((_designWidth - 304) / 2) * scale,
                      top: 85 * scale,
                      child: SizedBox(
                        width: 304 * scale,
                        child: Center(
                          child: Text(
                            '나의 성격 유형을 알고\n같은 유형의 사람을 찾아가는 여정',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'GolosText',
                              fontWeight: FontWeight.bold,
                              fontSize: 21.4 * scale,
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
                padding: EdgeInsets.only(
                  bottom: size.height * 0.05,
                  left: size.width * 0.09,
                  right: size.width * 0.09,
                ),
                child: SizedBox(
                  width: double.infinity,
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
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
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