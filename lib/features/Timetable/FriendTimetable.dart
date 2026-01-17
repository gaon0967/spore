import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // min, max 함수 사용
import 'course_model.dart';

class FriendTimetable extends StatefulWidget {
  final String friendName;
  final String friendUid;

  FriendTimetable({
    super.key,
    required this.friendName,
    required this.friendUid,
  });

  @override
  _FriendTimetableState createState() => _FriendTimetableState();
}

class _FriendTimetableState extends State<FriendTimetable> {
  List<Course> _friendCourses = [];
  bool _isLoading = true;
  String _currentSemester = '';

  @override
  void initState() {
    super.initState();
    _loadFriendCourses();
  }

  Future<void> _loadFriendCourses() async {
    setState(() => _isLoading = true);
    try {
      final tableSnapshot =
          await FirebaseFirestore.instance
              .collection('timetables')
              .doc(widget.friendUid)
              .collection('TableName')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      if (tableSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _friendCourses = [];
            _currentSemester = '시간표 없음';
            _isLoading = false;
          });
        }
        return;
      }

      final latestTable = tableSnapshot.docs.first;
      final tableName = latestTable.id;

      final snapshot =
          await FirebaseFirestore.instance
              .collection('timetables')
              .doc(widget.friendUid)
              .collection('TableName')
              .doc(tableName)
              .collection('classes')
              .get();

      List<Course> allCourses = [];
      for (var doc in snapshot.docs) {
        final dayId = doc.id;
        final data = doc.data();
        if (data['subjects'] == null) continue;

        final List<dynamic> subjectsList = data['subjects'];
        for (int i = 0; i < subjectsList.length; i++) {
          final subjectData = subjectsList[i] as Map<String, dynamic>;
          allCourses.add(
            Course.fromMap(
              subjectData,
              dayId,
              subjectData['id'] ?? i.toString(),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _friendCourses = allCourses;
          _currentSemester = tableName;
        });
      }
    } catch (e) {
      print("친구 시간표 로딩 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 430.0;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/Setting/go.png',
            width: screenWidth * 0.045,
            height: screenWidth * 0.045,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        leadingWidth: screenWidth * 0.1315,
        titleSpacing: 0,
        title: Text(
          widget.friendName,
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.047,
            color: Color(0xFF504A4A),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 23 * scale,
                  vertical: 10 * scale,
                ),
                child: Text(
                  _currentSemester,
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    color: const Color(0xFF556283),
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  14 * scale,
                  1 * scale,
                  14 * scale,
                  30 * scale,
                ), // 하단 여백 추가
                child: _buildTimetable(scale),
              ),
              // 강의 목록(_buildCourseListDetails)을 삭제했습니다.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimetable(double scale) {
    int minHour = 9;
    int maxHour = 16;
    if (_friendCourses.isNotEmpty) {
      final startTimes =
          _friendCourses.map((c) => c.startTime.floor()).toList();
      final endTimes = _friendCourses.map((c) => c.endTime.ceil()).toList();
      minHour = min(minHour, startTimes.reduce(min));
      maxHour = max(maxHour, endTimes.reduce(max));
    }
    final int totalHours = maxHour - minHour;

    return LayoutBuilder(
      builder: (context, constraints) {
        final timeColumnWidth = constraints.maxWidth * 0.06;
        final dayColumnWidth = (constraints.maxWidth - timeColumnWidth) / 5;
        final headerHeight = constraints.maxWidth * 0.06;
        final rowHeight = constraints.maxWidth * 0.144;
        final containerHeight = rowHeight * totalHours + headerHeight;

        return Container(
          height: containerHeight,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB3A6A6), width: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: const Color(0xFFFFFDF2)),
                ),
                Positioned(
                  top: headerHeight,
                  left: timeColumnWidth,
                  right: 0,
                  bottom: 0,
                  child: Container(color: const Color(0xFFFFFFF9)),
                ),
                _buildGrid(
                  headerHeight,
                  timeColumnWidth,
                  dayColumnWidth,
                  rowHeight,
                  minHour,
                  maxHour,
                  scale,
                ),
                ..._friendCourses.map(
                  (course) => _buildCourseItem(
                    course,
                    headerHeight,
                    timeColumnWidth,
                    dayColumnWidth,
                    rowHeight,
                    minHour,
                    scale,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(
    double headerHeight,
    double timeColWidth,
    double dayColWidth,
    double rowHeight,
    int startHour,
    int endHour,
    double scale,
  ) {
    const List<String> days = ['월', '화', '수', '목', '금'];
    final List<String> times = List.generate(
      endHour - startHour,
      (i) => (startHour + i).toString(),
    );

    return Stack(
      children: [
        ...List.generate(
          times.length + 1,
          (i) => Positioned(
            top: headerHeight + (i * rowHeight),
            left: 0,
            right: 0,
            child: Container(height: 0.5, color: const Color(0xFFB3A6A6)),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: timeColWidth,
          child: Container(width: 0.5, color: const Color(0xFFB3A6A6)),
        ),
        ...List.generate(
          4,
          (i) => Positioned(
            top: 0,
            bottom: 0,
            left: timeColWidth + ((i + 1) * dayColWidth),
            child: Container(width: 0.5, color: const Color(0xFFB3A6A6)),
          ),
        ),
        ...List.generate(
          5,
          (i) => Positioned(
            top: 0,
            height: headerHeight,
            left: timeColWidth + (i * dayColWidth),
            width: dayColWidth,
            child: Center(
              child: Text(
                days[i],
                style: TextStyle(
                  fontFamily: 'Golos Text',
                  fontSize: 11 * scale,
                  color: const Color(0xFF504A4A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        ...List.generate(
          times.length,
          (i) => Positioned(
            top: headerHeight + (i * rowHeight),
            height: rowHeight,
            left: 0,
            width: timeColWidth,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 2.0 * scale, right: 4.0 * scale),
                child: Text(
                  times[i],
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontSize: 11 * scale,
                    color: const Color(0xFF504A4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseItem(Course course, double headerHeight, double timeColWidth, double dayColWidth, double rowHeight, int startHour, double scale) {
  final top = headerHeight + (course.startTime - startHour) * rowHeight;
  final height = (course.endTime - course.startTime) * rowHeight;
  final left = timeColWidth + (course.day * dayColWidth);
  final width = dayColWidth;

  return Positioned(
    top: top + 0.5,
    left: left + 0.5,
    child: GestureDetector(
      onTap: () => _showCourseDetailModal(context, course), // 모달 호출
      child: Container(
        width: width - 0.5,
        height: height - 0.5,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: course.color),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title, 
                style: TextStyle(fontFamily: 'Golos Text', fontSize: 13 * scale, fontWeight: FontWeight.w500, color: const Color(0xFF504A4A)), 
                overflow: TextOverflow.ellipsis, maxLines: 2),
              const SizedBox(height: 0.5),
              Text(course.professor, 
                style: TextStyle(fontFamily: 'Golos Text', fontSize: 10.5 * scale, fontWeight: FontWeight.w400, color: const Color(0xFF625B5B)), 
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 0.5),
              Text(course.room, 
                style: TextStyle(fontFamily: 'Golos Text', fontSize: 10.5 * scale, fontWeight: FontWeight.w400, color: const Color(0xFF625B5B)), 
                overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    ),
  );
}


  // 2. 친구 전용 상세정보 바텀시트 (수정/삭제 제외)
 void _showCourseDetailModal(BuildContext context, Course course) {
  final screenWidth = MediaQuery.of(context).size.width;
  final double scale = screenWidth / 430;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 추가: 내용에 따라 높이 조절 및 바닥 밀착 보장
    backgroundColor: Colors.transparent, // 배경을 투명하게 해서 라운드 적용
    builder: (context) => Container(
      width: double.infinity, // 양옆을 꽉 채우기 위해 무한대 설정
      padding: EdgeInsets.fromLTRB(24 * scale, 24 * scale, 24 * scale, 40 * scale),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFF9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 내부 콘텐츠만큼만 높이 차지
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 수업 제목
          Text(
            course.title,
            style: TextStyle(
              fontFamily: 'Golos Text',
              fontSize: 20 * scale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF504A4A),
            ),
          ),
          SizedBox(height: 8 * scale),

          // 2. 상세 정보 (교수, 장소, 시간)
          Text(
            "교수: ${course.professor}",
            style: TextStyle(
              fontFamily: 'Golos Text', 
              fontSize: 15 * scale, 
              color: const Color(0xFF675F5F)
            ),
          ),
          Text(
            "장소: ${course.room}",
            style: TextStyle(
              fontFamily: 'Golos Text', 
              fontSize: 15 * scale, 
              color: const Color(0xFF675F5F)
            ),
          ),
          Text(
            "시간: ${formatTimeDouble(course.startTime)} - ${formatTimeDouble(course.endTime)}",
            style: TextStyle(
              fontFamily: 'Golos Text', 
              fontSize: 15 * scale, 
              color: const Color(0xFF675F5F)
            ),
          ),
          // 하단 버튼(수정, 삭제)이 들어가는 Row를 완전히 제거함
        ],
      ),
    ),
  );
}

  String formatTimeDouble(double time) {
    int hour = time.floor();
    int minute = ((time - hour) * 60).round();
    return '$hour:${minute.toString().padLeft(2, '0')}';
  }
}
