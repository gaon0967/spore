import 'package:flutter/material.dart';
import '../Timetable/TimetableList.dart';
import '../Timetable/ClassAdd.dart';
import '../Timetable/FriendTimetable.dart';

// Course 데이터 모델
class Course {
  final String title;
  final String professor;
  final String room;
  final int day; // 0:월, 1:화, 2:수, 3:목, 4:금
  final int startTime;
  final int endTime;
  final Color color;

  Course({
    required this.title,
    required this.professor,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.color,
  });
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // 샘플 강의 데이터
  final List<Course> courses = [
    Course(
      title: '리눅스눅스',
      professor: '함부기',
      room: '제2호관-401',
      day: 0,
      startTime: 9,
      endTime: 11,
      color: const Color(0xFFCDDEE3),
    ),
    Course(
      title: '가부기와 햄 부기',
      professor: '미사에',
      room: '제5호관-409',
      day: 0,
      startTime: 13,
      endTime: 15,
      color: const Color(0xFF97B4C7),
    ),
    Course(
      title: '고양이와 낮잠',
      professor: '냐옹이다옹',
      room: '제5호관-201',
      day: 1,
      startTime: 11,
      endTime: 13,
      color: const Color(0xFF8E9CBF),
    ),
    Course(
      title: '가부기와 햄 부기',
      professor: '미사에',
      room: '제5호관-409',
      day: 2,
      startTime: 9,
      endTime: 11,
      color: const Color(0xFF97B4C7),
    ),
    Course(
      title: '땅울림개론',
      professor: '에렌 예거',
      room: '제5호관-207',
      day: 2,
      startTime: 12,
      endTime: 14,
      color: const Color(0xFFBBCDC0),
    ),
    Course(
      title: '고양이와 낮잠',
      professor: '냐옹이다옹',
      room: '제5호관-201',
      day: 2,
      startTime: 14,
      endTime: 16,
      color: const Color(0xFF8E9CBF),
    ),
    Course(
      title: '밥 얻어먹는 기술',
      professor: '각설이',
      room: '제10호관-101',
      day: 3,
      startTime: 12,
      endTime: 14,
      color: const Color(0xFFE5EAEF),
    ),
    Course(
      title: '인간과 모기',
      professor: '전기파리채',
      room: '제9호관-105',
      day: 4,
      startTime: 9,
      endTime: 11,
      color: const Color(0xFFE8EBDF),
    ),
    Course(
      title: '땅울림개론',
      professor: '에렌 예거',
      room: '제5호관-207',
      day: 4,
      startTime: 14,
      endTime: 16,
      color: const Color(0xFFBBCDC0),
    ),
    Course(
      title: '저녁 산책',
      professor: '멍멍이',
      room: '운동장',
      day: 1,
      startTime: 17,
      endTime: 18,
      color: const Color(0xFFE8DDFD),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(), // 헤더 (버튼 포함)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTimetable(), // 시간표
                    _buildFriendsSection(), // 친구 시간표 섹션
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 반응형 UI를 위한 스케일 계산
  static const double _baseWidth = 411.0;
  double _scale(BuildContext context) {
    return MediaQuery.of(context).size.width / _baseWidth;
  }

  // 상단 헤더 위젯
  Widget _buildHeader() {
    final scale = _scale(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 23 * scale,
        vertical: 16 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '시간표',
                style: TextStyle(
                  color: const Color(0xFF504A4A),
                  fontSize: 28 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3 * scale),
              Text(
                '2025년 여름학기',
                style: TextStyle(
                  color: const Color(0xFF556283),
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // + 버튼 (누르면 모달 표시)
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: const Color(0xFF3B3737),
                  size: 24 * scale,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const AddCourseModal();
                    },
                  );
                },
              ),
              // 메뉴 버튼
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: const Color(0xFF3B3737),
                  size: 24 * scale,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimetableList()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 시간표 위젯
  Widget _buildTimetable() {
    final scale = _scale(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalPadding = 14.0 * scale;
    final containerWidth = screenWidth - (horizontalPadding * 2);
    final timeColumnWidth = 30.0 * scale;
    final dayColumnWidth = (containerWidth - timeColumnWidth) / 5;
    final rowHeight = 55.0 * scale;

    final int totalHours = 10;
    final double headerHeight = 22 * scale;
    final double containerHeight = rowHeight * totalHours + headerHeight;

    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB3A6A6), width: 0.5),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Stack(
        children: [
          _buildGrid(
            containerWidth,
            headerHeight,
            timeColumnWidth,
            dayColumnWidth,
            rowHeight,
          ),
          ...courses.map(
            (course) => _buildCourseItem(
              course,
              headerHeight,
              timeColumnWidth,
              dayColumnWidth,
              rowHeight,
            ),
          ),
        ],
      ),
    );
  }

  // 시간표 배경 그리드
  Widget _buildGrid(
    double width,
    double headerHeight,
    double timeColWidth,
    double dayColWidth,
    double rowHeight,
  ) {
    final scale = _scale(context);
    final List<String> days = ['월', '화', '수', '목', '금'];
    final List<String> times = [
      '9',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
    ];

    return Stack(
      children: [
        ...List.generate(
          times.length + 1,
          (i) => Positioned(
            left: 0,
            right: 0,
            top: headerHeight + (i * rowHeight),
            child: Container(height: 0.5, color: const Color(0xFFB3A6A6)),
          ),
        ),
        ...List.generate(
          6,
          (i) => Positioned(
            top: 0,
            bottom: 0,
            left: timeColWidth + (i * dayColWidth),
            child: Container(width: 0.5, color: const Color(0xFFB3A6A6)),
          ),
        ),
        ...List.generate(
          5,
          (i) => Positioned(
            top: 5 * scale,
            left:
                timeColWidth +
                (i * dayColWidth) +
                (dayColWidth / 2) -
                (5 * scale),
            child: Text(
              days[i],
              style: TextStyle(
                fontSize: 11 * scale,
                color: const Color(0xFF504A4A),
              ),
            ),
          ),
        ),
        ...List.generate(
          times.length,
          (i) => Positioned(
            top: headerHeight + (i * rowHeight) + (5 * scale),
            left: 10 * scale,
            child: Text(
              times[i],
              style: TextStyle(
                fontSize: 11 * scale,
                color: const Color(0xFF504A4A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 개별 강의 아이템
  Widget _buildCourseItem(
    Course course,
    double headerHeight,
    double timeColWidth,
    double dayColWidth,
    double rowHeight,
  ) {
    final scale = _scale(context);
    final top = headerHeight + (course.startTime - 9) * rowHeight;
    final left = timeColWidth + (course.day * dayColWidth);
    final height = (course.endTime - course.startTime) * rowHeight;
    final width = dayColWidth;

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () => _showCourseDetailModal(context, course),
        child: Container(
          width: width - 0.5,
          height: height - 0.5,
          padding: EdgeInsets.all(4 * scale),
          decoration: BoxDecoration(color: course.color),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF504A4A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  course.professor,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF625B5B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  course.room,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF625B5B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dayToString(int day) {
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일'];
    return days[day];
  }

  String _formatTime(int hour) {
    return "${hour.toString().padLeft(2, '0')}:00";
  }

  void _showCourseDetailModal(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter, // 하단 정렬
          child: Container(
            width: 414,
            height: 210,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFF9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 과목명
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 교수명
                Text(
                  course.professor,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 6),

                // 요일/시간
                Text(
                  "${_dayToString(course.day)} ${_formatTime(course.startTime)} ~ ${_formatTime(course.endTime)}",
                  style: const TextStyle(fontSize: 14, color: Colors.black45),
                ),

                // 강의실
                Text(
                  course.room,
                  style: const TextStyle(fontSize: 14, color: Colors.black45),
                ),

                const Spacer(),

                const Divider(),

                // 삭제 버튼 (텍스트형)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      courses.remove(course);
                    });
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          "삭제",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 친구 시간표 섹션
  Widget _buildFriendsSection() {
    final scale = _scale(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 20 * scale),
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20 * scale),
          topRight: Radius.circular(20 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(1, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 6 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFACACAC),
              borderRadius: BorderRadius.circular(20 * scale),
            ),
            child: Text(
              '친구 시간표',
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF504A4A),
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          _buildFriendButton('김가부기'),
          SizedBox(height: 8 * scale),
          _buildFriendButton('가부스탁스'),
        ],
      ),
    );
  }

  // 친구 시간표 버튼
  // TimetableScreen.dart의 _buildFriendButton 위젯

  Widget _buildFriendButton(String name) {
    final scale = _scale(context);
    return ElevatedButton(
      // ## 친구 시간표 페이지로 이동하는 기능 ##
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendTimetable(friendName: name),
          ),
        );
      },
      // ## 생략되었던 스타일 전체 코드 ##
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F5F5F),
        minimumSize: Size(double.infinity, 56 * scale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14 * scale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color: const Color(0xFFFFFFF9),
              fontSize: 15 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16 * scale),
        ],
      ),
    );
  }

  // 하단 네비게이션 바
  Widget _buildBottomNavBar() {
    final scale = _scale(context);
    return Container(
      height: 80 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20 * scale),
          topRight: Radius.circular(20 * scale),
        ),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.people_outline, '친구', false),
          _buildNavItem(Icons.home_outlined, '홈', false),
          _buildNavItem(Icons.calendar_today_outlined, '시간표', true),
        ],
      ),
    );
  }

  // 하단 네비게이션 아이템
  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    final scale = _scale(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 4 * scale,
      ),
      decoration:
          isSelected
              ? BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(10 * scale),
              )
              : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF4D4D4D), size: 24 * scale),
          SizedBox(height: 4 * scale),
          Text(
            label,
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF515151),
            ),
          ),
        ],
      ),
    );
  }
}

// 수업 추가 모달 위젯
class AddCourseModal extends StatefulWidget {
  const AddCourseModal({super.key});

  @override
  State<AddCourseModal> createState() => _AddCourseModalState();
}

class _AddCourseModalState extends State<AddCourseModal> {
  final List<Color> _colors = [
    const Color(0xFFCDDEE3),
    const Color(0xFF97B4C7),
    const Color(0xFF8E9CBF),
    const Color(0xFFBBCDC0),
    const Color(0xFFE5EAEF),
    const Color(0xFFE8EBDF),
  ];
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors.first; // 기본 색상 선택
  }

  @override
  Widget build(BuildContext context) {
    // AlertDialog를 사용하여 모달 모양을 만듭니다.
    return AlertDialog(
      backgroundColor: const Color(0xFFFCFBF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.all(20),
      content: SingleChildScrollView(
        // 키보드가 올라올 때 오버플로우 방지
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField('수업명'),
            const SizedBox(height: 12),
            _buildTextField('교수'),
            const SizedBox(height: 12),
            _buildTextField('장소'),
            const SizedBox(height: 16),
            _buildTimePicker('시작 시간'),
            const SizedBox(height: 8),
            _buildTimePicker('종료 시간'),
            const SizedBox(height: 16),
            _buildColorPicker(),
          ],
        ),
      ),
      actions: [
        // '추가 +' 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton(
            onPressed: () {
              // TODO: 입력된 정보로 강의 추가하는 로직 구현
              Navigator.of(context).pop(); // 모달 닫기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              '추가 +',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
      buttonPadding: EdgeInsets.zero,
    );
  }

  // 텍스트 입력 필드를 만드는 함수
  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F2EE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // 시간 선택 위젯을 만드는 함수
  Widget _buildTimePicker(String label) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        const Expanded(
          child: Text(
            "00 : 00",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        // TODO: 실제 TimePicker 기능 연동 필요-------------- 아직 개발 안함.
      ],
    );
  }

  // 색상 선택 위젯을 만드는 함수
  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children:
          _colors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border:
                      _selectedColor == color
                          ? Border.all(color: Colors.blueAccent, width: 2)
                          : null,
                ),
              ),
            );
          }).toList(),
    );
  }
}
