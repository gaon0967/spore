import 'package:flutter/material.dart';
import 'ClassAdd.dart';

class FriendTimetable extends StatelessWidget {
  final String friendName;

  FriendTimetable({super.key, required this.friendName});

  // 실제 앱에서는 친구 ID를 통해 서버에서 받아와야 함
  final List<Course> friendCourses = [
  // [수정] 모든 TimeOfDay에 minute: 0 추가
  Course(title: '리눅스눅스', professor: '함부기', room: '제2호관-401', day: 0, startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 11, minute: 0), color: Color(0xFFCDDEE3)),
  Course(title: '고양이와 낮잠', professor: '냐옹이다옹', room: '제5호관-201', day: 1, startTime: const TimeOfDay(hour: 11, minute: 0), endTime: const TimeOfDay(hour: 13, minute: 0), color: Color(0xFF8E9CBF)),
  Course(title: '가부기와 햄 부기', professor: '미사에', room: '제5호관-409', day: 2, startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 11, minute: 0), color: Color(0xFF97B4C7)),
  Course(title: '땅울림개론', professor: '에렌 예거', room: '제5호관-207', day: 2, startTime: const TimeOfDay(hour: 12, minute: 0), endTime: const TimeOfDay(hour: 14, minute: 0), color: Color(0xFFBBCDC0)),
  Course(title: '밥 얻어먹는 기술', professor: '각설이', room: '제10호관-101', day: 3, startTime: const TimeOfDay(hour: 12, minute: 0), endTime: const TimeOfDay(hour: 14, minute: 0), color: Color(0xFFE5EAEF)),
  Course(title: '인간과 모기', professor: '전기파리채', room: '제9호관-105', day: 4, startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 11, minute: 0), color: Color(0xFFE8EBDF)),
  Course(title: '가부기와 햄 부기', professor: '미사에', room: '제5호관-409', day: 0, startTime: const TimeOfDay(hour: 14, minute: 0), endTime: const TimeOfDay(hour: 16, minute: 0), color: Color(0xFF97B4C7)),
  Course(title: '고양이와 낮잠', professor: '냐옹이다옹', room: '제5호관-201', day: 2, startTime: const TimeOfDay(hour: 14, minute: 0), endTime: const TimeOfDay(hour: 16, minute: 0), color: Color(0xFF8E9CBF)),
  Course(title: '오펜세의 법칙', professor: '오씨부인', room: '제3호관-301', day: 0, startTime: const TimeOfDay(hour: 15, minute: 0), endTime: const TimeOfDay(hour: 17, minute: 0), color: Color(0xFFCDDEE3)),
  Course(title: '땅울림개론', professor: '에렌 예거', room: '제5호관-207', day: 4, startTime: const TimeOfDay(hour: 14, minute: 0), endTime: const TimeOfDay(hour: 16, minute: 0), color: Color(0xFFBBCDC0)),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          friendName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 8),
              child: Text(
                '2025년 여름학기',
                style: TextStyle(
                  color: const Color(0xFF556283).withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _buildTimetable(context),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildTimetable(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 411.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 14.0;
    final containerWidth = screenWidth - (horizontalPadding * 2);
    final timeColumnWidth = 30.0 * scale;
    final dayColumnWidth = (containerWidth - timeColumnWidth) / 5;
    final rowHeight = 55.0 * scale;
    const int totalHours = 10;
    final double headerHeight = 22 * scale;
    final double containerHeight = rowHeight * totalHours + headerHeight;

    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB3A6A6), width: 0.5),
        borderRadius: BorderRadius.circular(10 * scale),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          _buildGrid(context, containerWidth, headerHeight, timeColumnWidth, dayColumnWidth, rowHeight),
          ...friendCourses.map((course) => _buildCourseItem(context, course, headerHeight, timeColumnWidth, dayColumnWidth, rowHeight)),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, double width, double headerHeight, double timeColWidth, double dayColWidth, double rowHeight) {
    final scale = MediaQuery.of(context).size.width / 411.0;
    const List<String> days = ['월', '화', '수', '목', '금'];
    const List<String> times = ['9', '10', '11', '12', '13', '14', '15', '16', '17', '18'];

    return Stack(
      children: [
        ...List.generate(times.length + 1, (i) => Positioned(
          left: 0, right: 0, top: headerHeight + (i * rowHeight),
          child: Container(height: 0.5, color: const Color(0xFFB3A6A6)),
        )),
        ...List.generate(6, (i) => Positioned(
          top: 0, bottom: 0, left: timeColWidth + (i * dayColWidth),
          child: Container(width: 0.5, color: const Color(0xFFB3A6A6)),
        )),
        ...List.generate(5, (i) => Positioned(
          top: 5 * scale, left: timeColWidth + (i * dayColWidth) + (dayColWidth / 2) - (5 * scale),
          child: Text(days[i], style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF504A4A))),
        )),
        ...List.generate(times.length, (i) => Positioned(
          top: headerHeight + (i * rowHeight) + (5 * scale), left: 10 * scale,
          child: Text(times[i], style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF504A4A))),
        )),
      ],
    );
  }

  Widget _buildCourseItem(BuildContext context, Course course, double headerHeight, double timeColWidth, double dayColWidth, double rowHeight) {
    final scale = MediaQuery.of(context).size.width / 411.0;
    
    final top = headerHeight + (course.startTime.hour - 9) * rowHeight + (course.startTime.minute / 60.0) * rowHeight;
    final left = timeColWidth + (course.day * dayColWidth);

    final startMinutes = course.startTime.hour * 60 + course.startTime.minute;
    final endMinutes = course.endTime.hour * 60 + course.endTime.minute;
    final durationMinutes = endMinutes - startMinutes;
    final height = (durationMinutes / 60.0) * rowHeight;

    final width = dayColWidth;

    return Positioned(
      top: top,
      left: left,
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
              Text(course.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF504A4A))),
              const SizedBox(height: 2),
              Text(course.professor, style: const TextStyle(fontSize: 10, color: Color(0xFF625B5B))),
              const SizedBox(height: 2),
              Text(course.room, style: const TextStyle(fontSize: 10, color: Color(0xFF625B5B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(context, Icons.people_outline, '친구', false),
          _buildNavItem(context, Icons.home_outlined, '홈', false),
          _buildNavItem(context, Icons.calendar_today_outlined, '시간표', true),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0E0E0) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4D4D4D), size: 28),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF515151)))
      ],
    );
  }
}