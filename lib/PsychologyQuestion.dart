import 'package:flutter/material.dart';
import 'PsychologyResult.dart';
import 'package:auto_size_text/auto_size_text.dart';

// --- 테스트 질문 화면 ---
/// 클래스 : PsychologyQuestion  
/// 목적 : 심리 테스트 질문을 하나씩 보여주고, 사용자의 선택을 받아 점수를 누적한 후 결과로 이동  
/// 여기서 점수는 1~8번에 계수 정렬처럼 누적됨. 
/// 반환타입 : StatefulWidget  
/// 예외 : 없음
class PsychologyQuestion extends StatefulWidget {
  const PsychologyQuestion({super.key});

  @override
  State<PsychologyQuestion> createState() => _PsychologyQuestionState();
}




class _PsychologyQuestionState extends State<PsychologyQuestion> {
  // --- 제공해주신 새로운 질문 및 점수 데이터 ---
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Q1. 친구가 고민 상담을 해왔을 때의 나는?',
      'answers': [
        {'text': '조언 위주로 들어준다.', 'score': 7},
        {'text': '진심으로 공감하며\n고민을 들어준다.', 'score': 4},
        {'text': '안심시키고 끝까지\n곁에 있어준다.', 'score': 1},
      ],
    },
    {
      'question': 'Q2. 누군가 곤란해보일 때 나는?',
      'answers': [
        {'text': '바로 도와준다\n몸이 먼저 움직인다.', 'score': 1},
        {'text': '걱정하지만\n쉽게 도와주지 못한다.', 'score': 8},
        {'text': '상황 봐서 자연스럽게\n챙겨준다.', 'score': 4},
      ],
    },
    {
      'question': 'Q3. 일이나 과제가 몰렸을 때 나는?',
      'answers': [
        {'text': '계획 세우고 미리미리\n처리한다', 'score': 7},
        {'text': '중요한 것만\n골라 처리한다', 'score': 5},
        {'text': '일단 쉰다 ', 'score': 2},
      ],
    },
    {
      'question': 'Q4. 쉬는 시간, 나는?',
      'answers': [
        {'text': '나만의 취미를 만들거나\n혼자 논다.', 'score': 3},
        {'text': '친구들과 수다를 떤다.', 'score': 5},
        {'text': '일단 눕는다...\n생각은 나중에 한다.', 'score': 2},
      ],
    },
    {
      'question': 'Q5. 새로운 팀플 팀원이 생겼을 때 나는?',
      'answers': [
        {'text': '먼저 말 걸고\n 분위기 띄운다.', 'score': 5},
        {'text': '무조건 계획표부터\n짜자고 한다.', 'score': 7},
        {'text': '필요한 말만 하고\n내 할 일 한다', 'score': 3},
      ],
    },
    {
      'question': 'Q6. 로맨스 영화를 볼 때 나는?',
      'answers': [
        {'text': '감정이입 100%,\n눈물 찔끔 흘린다.', 'score': 6},
        {'text': '주인공의 행동에\n공감한다.', 'score': 8},
        {'text': '현실 연애는 귀찮아~\n생각한다.', 'score': 2},
      ],
    },
    {
      'question': 'Q7. 인간관계 스타일은?',
      'answers': [
        {'text': '깊은 관계 몇 명이면\n충분하다.', 'score': 3},
        {'text': '먼저 다가가는 타입이다.', 'score': 4},
        {'text': '누군가에게 힘이\n되어주는 스타일이다.', 'score': 1},
      ],
    },
    {
      'question': 'Q8. 자유시간이 생기면 나는?',
      'answers': [
        {'text': '무언가를 배우거나\n도전한다.', 'score': 7},
        {'text': '재미있는 영상이나\n게임부터 켠다.', 'score': 5},
        {'text': '조용한 공간에서\n생각을 정리한다.', 'score': 8},
      ],
    },
    {
      'question': 'Q9. 혼자 있는 걸 좋아하는 이유는?',
      'answers': [
        {'text': '자유로워서!\n누구 눈치도 안 봐도 돼서.', 'score': 3},
        {'text': '생각 정리하거나\n감정 정리할 시간이 되니까.', 'score': 6},
        {'text': '아무것도 안 하고\n멍 때리는 게 힐링이라서.', 'score': 2},
      ],
    },
    {
      'question': 'Q10. 감동적인 편지를 받았을 때?',
      'answers': [
        {'text': '울컥하고 평생 동안\n간직한다.', 'score': 6},
        {'text': '감동하며\n답장 편지를 쓴다.', 'score': 4},
        {'text': '이건 나만 볼 수 없어!\nSNS에 공유한다.', 'score': 5},
      ],
    },
    {
      'question': 'Q11. 나를 한 마디로 표현한다면?',
      'answers': [
        {'text': '다정하고 따뜻한 사람', 'score': 4},
        {'text': '모든일이\n조심스러운 사람', 'score': 8},
        {'text': '감성 풍부한 낭만파', 'score': 6},
      ],
    },
    {
      'question': 'Q12. 강의가 취소됐다! 당신의 반응은?',
      'answers': [
        {'text': '새로운 계획을 세운다!', 'score': 7},
        {'text': '누워서 하루 종일\n쉬어야지.', 'score': 2},
        {'text': '그냥 내 리듬대로\n보내는 거지.', 'score': 3},
      ],
    },
    {
      'question': 'Q13. 당신에게 가까운 스타일은?',
      'answers': [
        {'text': '무슨 일이든 믿고\n맡기는 스타일이다.', 'score': 1},
        {'text': '항상 새로운 걸 찾는\n스타일이다.', 'score': 7},
        {'text': '깊게 생각하고 쉽게\n도전하지 않는 스타일이다.', 'score': 8},
      ],
    },
    {
      'question': 'Q14. 가장 끌리는 취미 생활은?',
      'answers': [
        {'text': '스포츠 관람하기,\n경기 뛰기', 'score': 7},
        {'text': '책 읽기, 뜨개질, 명상', 'score': 3},
        {'text': '식물 키우기', 'score': 4},
      ],
    },
    {
      'question': 'Q15. 가장 좋아하는 음식은?',
      'answers': [
        {'text': '김치찌개, 된장찌개 등\n한식', 'score': 3},
        {'text': '짜장면, 짬뽕 등\n중식', 'score': 7},
        {'text': '초밥, 규카츠 등\n일식', 'score': 2},
      ],
    },
  ];

  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  final List<int> _selectedScores = []; // 사용자가 선택한 점수를 저장하는 리스트

  // 답변 선택 시 호출되는 함수
  void _answerQuestion(int answerIndex, int score) {
    if (_selectedAnswerIndex != null) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
      _selectedScores.add(score); // 선택된 점수 추가
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswerIndex = null;
        });
      } else {
        // 모든 질문 완료, 결과 계산 및 화면 이동
        _calculateAndNavigate();
      }
    });
  }

  //  결과를 계산하고 결과 화면으로 이동하는 함수
  void _calculateAndNavigate() {
    // 1. 각 점수가 몇 번 나왔는지 계산
    final scoreCounts = <int, int>{};
    for (var score in _selectedScores) {
      scoreCounts[score] = (scoreCounts[score] ?? 0) + 1;
    }

    // 2. 가장 많이 나온 횟수 찾기
    int maxCount = 0;
    scoreCounts.forEach((score, count) {
      if (count > maxCount) {
        maxCount = count;
      }
    });

    // 3. 가장 많이 나온 점수들 찾기 (동점 대비)
    final topScores = <int>[];
    scoreCounts.forEach((score, count) {
      if (count == maxCount) {
        topScores.add(score);
      }
    });

    // 4. 동점일 경우 가장 작은 번호로 결정
    topScores.sort();
    final int finalResultId = topScores.first;

    // 로딩 화면을 거쳐 결과 화면으로 최종 ID 전달
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // 이제 LoadingScreen으로 결과 ID를 넘겨줍니다.
          builder: (_) => TestLoadingScreen(resultId: finalResultId),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.06;

    final questionData = _questions[_currentQuestionIndex];
    final answers = questionData['answers'] as List<Map<String, dynamic>>;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:  EdgeInsets.symmetric(horizontal:horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               SizedBox(height: size.height * 0.03),
              _TestProgressBar(
                currentStep: _currentQuestionIndex + 1,
                totalSteps: _questions.length,
              ),
               SizedBox(height: size.height * 0.05),
              Text(
                questionData['question'],
                textAlign: TextAlign.center,
                style: TextStyle(
                fontSize: size.width * 0.048,
                fontWeight: FontWeight.bold,
                height: 1.45,
              
              
              ),
              ),
                Expanded(
              child: _AnswerOptions(
                answers: answers,
                onAnswerSelected: (index) {
                  _answerQuestion(index, answers[index]['score'] as int);
                },
                selectedAnswerIndex: _selectedAnswerIndex,
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}



/// 클래스 : _TestProgressBar  
/// 목적 : 현재 진행 중인 질문 단계 수를 상단에 숫자로 1/15 표시  
/// 반환타입 : StatelessWidget  
/// 예외 : 없음

class _TestProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _TestProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double progress = currentStep / totalSteps;
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: const Color(0xFFC59A9A),
          minHeight:  size.height * 0.012,
          borderRadius: BorderRadius.circular(4),
        ),
         SizedBox(height:size.height * 0.01),
        Text(
          '$currentStep / $totalSteps',
          style:  TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}





/// 클래스 : _AnswerOptions  
/// 목적 : 질문의 답변들을 커스텀 도형 버튼 형태로  3개 씩 표시   
/// 반환타입 : StatelessWidget  
/// 예외 : 예외 처리 없음 (+ 질문 갯수가 3개씩이 아닐 경우가 생기면 추후 예외 처리할 예정. )
class _AnswerOptions extends StatelessWidget {
  final List<Map<String, dynamic>> answers;
  final Function(int) onAnswerSelected;
  final int? selectedAnswerIndex;

  const _AnswerOptions({
    super.key,
    required this.answers,
    required this.onAnswerSelected,
    this.selectedAnswerIndex,
  });

  @override
  Widget build(BuildContext context) {
    const shapeMapping = [
      _ShapeType.cloud,
      _ShapeType.circle,
      _ShapeType.triangle,
    ];

    // 화면 너비를 기준으로 도형 크기를 정함. 
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      fit: StackFit.expand, 
      children: <Widget>[
        // 답변 1 - 구름 (오른쪽 위)
        if (answers.isNotEmpty)
          Align(
            alignment: const Alignment(1.3, -0.85), // 오른쪽 위
            child: SizedBox(
            
              width: screenWidth * 0.6,
              child: _AnswerShape(
                text: answers[0]['text'] as String,
                shapeType: shapeMapping[0],
                isSelected: selectedAnswerIndex == 0,
                onTap: () => onAnswerSelected(0),
              ),
            ),
          ),

        if (answers.length > 1)
      Align(
       
    alignment: const Alignment(-1.3, 0.1),
    child: Container(
      width: screenWidth * 0.5,
      child: _AnswerShape(
        text: answers[1]['text'] as String,
        shapeType: shapeMapping[1],
        isSelected: selectedAnswerIndex == 1,
        onTap: () => onAnswerSelected(1),
      ),
    ),
  ),

          
        // 답변 3 - 삼각형 (오른쪽 아래)
        if (answers.length > 2)
          Align(
            alignment: const Alignment(1.1, 0.9), // 오른쪽 아래
            child: Container(
              width: screenWidth * 0.6,
              child: _AnswerShape(
                text: answers[2]['text'] as String,
                shapeType: shapeMapping[2],
                isSelected: selectedAnswerIndex == 2,
                onTap: () => onAnswerSelected(2),
              ),
            ),
          ),
      ],
    );
  }
}



enum _ShapeType { cloud, circle, triangle }




/// 클래스 : _AnswerShape  
/// 목적 : 각 도형형 버튼, 이미지 위치잡기   
/// 반환타입 : StatelessWidget  
/// 예외 : 예외 처리 안함. (+ 추후 이미지 경로 관련해서 코드 수정할 예정. )
class _AnswerShape extends StatelessWidget {
  final String text;
  final _ShapeType shapeType;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerShape({
    required this.text,
    required this.shapeType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    String imagePath;
    double shapeWidth;

  switch (shapeType) {
    case _ShapeType.cloud: // Star
      imagePath = 'assets/images/Star.png';
      //shapeWidth = 276;
      shapeWidth =size.width * 0.7;
      break;
    case _ShapeType.circle: //Ellipse
      imagePath = 'assets/images/Ellipse.png';
      //shapeWidth = 284;
      shapeWidth =size.width * 0.72;
      break;
    case _ShapeType.triangle: // Polygon
      imagePath = 'assets/images/Polygon.png';
      //shapeWidth = 277;
      shapeWidth = size.width * 0.7;
      break;
  }


    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            imagePath,
            width: shapeWidth.clamp(120, 350).toDouble(),
             fit: BoxFit.contain,
            color: isSelected ? const Color(0xFF6E8B66) : null,
            colorBlendMode: isSelected ? BlendMode.modulate : null,
          ),
          isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 50)
              : Container(
                  width: shapeWidth * 0.7,
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  child: AutoSizeText(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    minFontSize: 8,
                    //softWrap: true, 
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: (size.width * 0.04).clamp(12, 18).toDouble(),
                      color: const Color(0xFF504A4A),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}




/// 클래스 : TestLoadingScreen  
/// 목적 : 최종 점수를 기반으로  PsychologyResult로 3초 후 자동 이동하는 기능 구현  
/// 반환타입 : StatefulWidget  
/// 예외 :예외 처리 없음. 
class TestLoadingScreen extends StatefulWidget {
  // 질문 화면에서 넘어온 최종 결과 ID를 받을 변수 추가
  final int resultId;

  // 생성자에서 resultId를 필수로 받도록 수정함. 
  const TestLoadingScreen({super.key, required this.resultId});

  @override
  State<TestLoadingScreen> createState() => _TestLoadingScreenState();
}


// 클래스 : _TestLoadingScreenState  
/// 목적 : 로딩 애니메이션을 보여준 뒤, 일정 시간 후 PsychologyResult로 자동 전환  
/// 반환타입 : State<TestLoadingScreen>  
/// 예외 :  
/// -아직 비동기 부분 예외 처리 아직 구현 안함 !!!!!!!!!!!
///   - context가 `unmounted` 상태일 경우 Navigator 에러 발생 가능성 → `if (mounted)` 조건으로 방지  
///   - 이미지 asset 경로가 잘못된 경우 → `errorBuilder`를 통해 기본 아이콘으로 대체 처리
class _TestLoadingScreenState extends State<TestLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToResultScreen();
  }

  void _navigateToResultScreen() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            //  받은 resultId를 PsychologyResult 화면으로 전달
            builder: (context) => PsychologyResult(resultId: widget.resultId),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/TestLoading.png',
              //width: 80,
              //height: 80,
              width: size.width * 0.18,
              height: size.width * 0.18,
               errorBuilder: (context, error, stackTrace) {
                  return  Icon(Icons.find_in_page_outlined, size: size.width * 0.18, color: Colors.grey);
               },
            ),
             SizedBox(height: size.height * 0.03),
             Text('어울리는 캐릭터 찾는 중...', style: TextStyle(fontSize: size.width * 0.048)),
             SizedBox(height: size.height * 0.03),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: size.width * 0.15),
              child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200], color: Colors.grey[600],minHeight: size.height * 0.012,),
            ),
          ],
        ),
      ),
    );
  }
}