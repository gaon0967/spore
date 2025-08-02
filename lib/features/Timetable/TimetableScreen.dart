import 'package:flutter/material.dart';
import '../Timetable/TimetableList.dart';
import '../Timetable/ClassAdd.dart';
import '../Timetable/FriendTimetable.dart';
import '../Timetable/course_model.dart';

/*
추가 되는 과정 설명 

사용자가 Timetable 화면의 '추가' 버튼을 눌러 ClassAdd 모달이 뜹니다.

입력 폼(정보, 요일, 시간, 색상 등) 작성 후 [추가 +] 버튼을 누르면,

입력값과 시간대에 대한 유효성 검사가 진행됩니다.

충돌 시에는 기존 과목 교체 여부를 물으며, 사용자의 선택에 따라 교체 또는 취소합니다.

모든 검증 및 조치가 끝나면 과목이 실제로 추가되고 화면이 갱신됩니다.


*/

class TimetableScreen extends StatefulWidget {
  final SemesterTimetable timetable;
  final List<Course> initialCourses;
  final Function(List<Course>)? onCoursesUpdated;
  final Map<String, List<Course>> allTimetableCourses;
  final Function(String)? onTimetableSelected;

  const TimetableScreen({
    super.key,
    required this.timetable,
    required this.initialCourses,
    required this.allTimetableCourses,
    this.onCoursesUpdated,
    this.onTimetableSelected,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late List<Course> courses;

  @override
  void initState() {
    super.initState();
    courses = List.from(widget.initialCourses);
  }

  @override
  void didUpdateWidget(covariant TimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timetable.year != oldWidget.timetable.year ||
        widget.timetable.semester != oldWidget.timetable.semester) {
      setState(() {
        courses = List.from(widget.initialCourses);
      });
    }
  }

  void _addCourse(Course course) {
    setState(() {
      courses.add(course);
    });
    // 데이터 변경 사항을 MainScreen으로 전달
    if (widget.onCoursesUpdated != null) {
      widget.onCoursesUpdated!(courses);
    }
  }

  void _removeCourse(Course course) {
    setState(() {
      courses.remove(course);
    });
    // 데이터 변경 사항을 MainScreen으로 전달
    if (widget.onCoursesUpdated != null) {
      widget.onCoursesUpdated!(courses);
    }
  }

  void _updateCourses(List<Course> newCourses) {
    setState(() {
      courses = newCourses;
    });
    if (widget.onCoursesUpdated != null) {
      widget.onCoursesUpdated!(courses);
    }
  }

  Course? _checkTimeConflict(Course newCourse) {
    for (var existingCourse in courses) {
      if (existingCourse.day == newCourse.day) {
        if (newCourse.startTime < existingCourse.endTime &&
            existingCourse.startTime < newCourse.endTime) {
          return existingCourse;
        }
      }
    }
    return null;
  }

  Future<bool> _showConflictDialog(Course conflictingCourse) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('시간 중복'),
            content: Text(
              "'${conflictingCourse.title}' 강의와 시간이 겹칩니다. 변경하시겠습니까?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('예'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTimetable(),
                    _buildFriendsSection(), // 생략 가능
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _baseWidth = 411.0;
  double _scale(BuildContext context) {
    return MediaQuery.of(context).size.width / _baseWidth;
  }

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
                '${widget.timetable.year}년 ${widget.timetable.semester}',
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
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: const Color(0xFF3B3737),
                  size: 24 * scale,
                ),
                onPressed: () async {
                  final newCourse = await showDialog<Course>(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.5),
                    builder: (BuildContext context) => const ClassAdd(),
                  );
                  if (newCourse == null) return;
                  await Future.delayed(Duration.zero);
                  if (!mounted) return;
                  final conflictingCourse = _checkTimeConflict(newCourse);
                  if (conflictingCourse != null) {
                    final wannaReplace = await _showConflictDialog(
                      conflictingCourse,
                    );
                    if (wannaReplace) {
                      final newCourses = List<Course>.from(courses);
                      newCourses.remove(conflictingCourse);
                      newCourses.add(newCourse);
                      _updateCourses(newCourses);
                    }
                  } else {
                    final newCourses = List<Course>.from(courses);
                    newCourses.add(newCourse);
                    _updateCourses(newCourses);
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: const Color(0xFF3B3737),
                  size: 24 * scale,
                ),
                onPressed: () async {
                  // Navigator.push가 완료되면, TimetableList에서 반환된 값을 result 변수에 담습니다.
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TimetableList(
                            allTimetableCourses: widget.allTimetableCourses,
                          ),
                    ),
                  );

                  // result가 null이 아닐 경우 (즉, TimetableList에서 어떤 값을 반환했을 경우)
                  if (result != null && widget.onTimetableSelected != null) {
                    widget.onTimetableSelected!(result as String);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        return LayoutBuilder(
          builder: (context, constraints) {
            final modalWidth =
                constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: modalWidth,
                height: 210,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFF9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(1, 1),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      course.professor,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${_dayToString(course.day)} ${_formatTime(course.startTime)} ~ ${_formatTime(course.endTime)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                    Text(
                      course.room,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    const Divider(),
                    GestureDetector(
                      onTap: () {
                        final newCourses = List<Course>.from(courses);
                        newCourses.remove(course);
                        _updateCourses(newCourses);
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.grey),
                            SizedBox(width: 6),
                            Text(
                              "삭제",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
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
      },
    );
  }

  Widget _buildFriendsSection() {
    final scale = _scale(context);
    final List<String> friends = ['김가부기', '가부스탁스']; // 친구 목록

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
          ...friends.map(
            (friendName) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildFriendButton(friendName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendButton(String name) {
    final scale = _scale(context);
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendTimetable(friendName: name),
          ),
        );
      },
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
}