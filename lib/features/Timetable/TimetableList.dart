import 'package:flutter/material.dart';

// 시간표 데이터를 표현하기 위한 간단한 모델 클래스
class SemesterTimetable {
  final String year;
  final String semester;
  final Color color;

  SemesterTimetable({required this.year, required this.semester, required this.color});
}

class TimetableList extends StatefulWidget {
  const TimetableList({super.key});

  @override
  State<TimetableList> createState() => _TimetableListState();
}

class _TimetableListState extends State<TimetableList> {
  // 샘플 데이터 리스트
  final List<SemesterTimetable> timetables = [
    SemesterTimetable(year: '2025', semester: '여름학기', color: const Color(0xFFDDEBF1)),
    SemesterTimetable(year: '2025', semester: '1학기', color: const Color(0xFFD4DAF5)),
    SemesterTimetable(year: '2024', semester: '겨울학기', color: const Color(0xFFA9C5D8)),
    SemesterTimetable(year: '2024', semester: '2학기', color: const Color(0xFFC7D7CB)),
    SemesterTimetable(year: '2024', semester: '여름학기', color: const Color(0xFFE3E8EE)),
    SemesterTimetable(year: '2024', semester: '1학기', color: const Color(0xFFE9EBE0)),
  ];

  // 선택된 시간표의 인덱스를 저장
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ## 커스텀 AppBar 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // 그림자 제거
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '시간표 목록',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // 시간표 추가 기능 구현-------------------아직 안함. !!!
            
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F0F0),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text('시간표 추가 +'),
            ),
          )
        ],
      ),
      // ## 2. GridView를 사용한 시간표 목록 ##
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 한 줄에 2개의 아이템
            crossAxisSpacing: 16, // 아이템 간의 가로 간격
            mainAxisSpacing: 16, // 아이템 간의 세로 간격
            childAspectRatio: 0.8, // 아이템의 가로세로 비율
          ),
          itemCount: timetables.length,
          itemBuilder: (context, index) {
            final timetable = timetables[index];
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () {
                // 아이템을 탭하면 선택된 인덱스 변경
                setState(() {
                  _selectedIndex = index;
                });
              },
              // ## 3. 개별 시간표 카드 위젯 ##
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: timetable.color,
                  borderRadius: BorderRadius.circular(16),
                  // isSelected가 true일 때만 테두리 표시
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timetable.year,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timetable.semester,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // ##  우측 하단 플로팅 위젯 ##
    );
  }
}