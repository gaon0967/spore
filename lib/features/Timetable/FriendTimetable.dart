import 'package:flutter/material.dart';
import 'course_model.dart'; 

class FriendTimetable extends StatelessWidget {
  final String friendName;

  FriendTimetable({super.key, required this.friendName});

  // ### ⭐️ 수정된 부분: Course 생성자에서 id 파라미터 제거 ⭐️ ###
  final List<Course> friendCourses = [
    Course(title: '리눅스눅스', professor: '함부기', room: '제2호관-401', day: 0, startTime: 9, endTime: 11, color: Color(0xFFCDDEE3)),
    Course(title: '고양이와 낮잠', professor: '냐옹이다옹', room: '제5호관-201', day: 1, startTime: 11, endTime: 13, color: Color(0xFF8E9CBF)),
    Course(title: '가부기와 햄 부기', professor: '미사에', room: '제5호관-409', day: 2, startTime: 9, endTime: 11, color: Color(0xFF97B4C7)),
    Course(title: '땅울림개론', professor: '에렌 예거', room: '제5호관-207', day: 2, startTime: 12, endTime: 14, color: Color(0xFFBBCDC0)),
    Course(title: '밥 얻어먹는 기술', professor: '각설이', room: '제10호관-101', day: 3, startTime: 12, endTime: 14, color: Color(0xFFE5EAEF)),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 411.0;

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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22 * scale,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 23 * scale, vertical: 8 * scale),
                child: Text(
                  '2025년 여름학기',
                  style: TextStyle(
                    color: const Color(0xFF556283).withOpacity(0.8),
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14 * scale),
                child: _buildTimetable(context, scale),
              ),
              _buildCourseListDetails(context, scale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimetable(BuildContext context, double scale) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final timeColumnWidth = 30.0 * scale;
        final dayColumnWidth = (screenWidth - timeColumnWidth) / 5;
        final rowHeight = 55.0 * scale;
        final headerHeight = 22 * scale;
        final containerHeight = rowHeight * 10 + headerHeight;

        return Container(
          width: screenWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB3A6A6), width: 0.5),
            borderRadius: BorderRadius.circular(10 * scale),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              _buildGrid(headerHeight, timeColumnWidth, dayColumnWidth, rowHeight, scale),
              ...friendCourses.map((course) => _buildCourseItem(course, headerHeight, timeColumnWidth, dayColumnWidth, rowHeight, scale)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(double headerHeight, double timeColWidth, double dayColWidth, double rowHeight, double scale) {
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
          top: 0,
          left: timeColWidth + (i * dayColWidth),
          width: dayColWidth,
          height: headerHeight,
          child: Center(
            child: Text(
              days[i],
              style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF504A4A))
            ),
          ),
        )),
        ...List.generate(times.length, (i) => Positioned(
          top: headerHeight + (i * rowHeight),
          left: 0,
          width: timeColWidth,
          height: rowHeight,
          child: Center(
            child: Text(
              times[i],
              style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF504A4A))
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCourseItem(Course course, double headerHeight, double timeColWidth, double dayColWidth, double rowHeight, double scale) {
    final top = headerHeight + (course.startTime - 9) * rowHeight;
    final left = timeColWidth + (course.day * dayColWidth);
    final height = (course.endTime - course.startTime) * rowHeight;
    final width = dayColWidth;

    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: width - 0.5,
        height: height - 0.5,
        padding: EdgeInsets.all(4 * scale),
        decoration: BoxDecoration(
          color: course.color,
          borderRadius: BorderRadius.circular(4 * scale)
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(course.title, style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w500, color: const Color(0xFF504A4A))),
              const SizedBox(height: 2),
              Text(course.professor, style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF625B5B))),
              const SizedBox(height: 2),
              Text(course.room, style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF625B5B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseListDetails(BuildContext context, double scale) {
    final List<String> dayNames = ['월', '화', '수', '목', '금'];

    return Padding(
      padding: EdgeInsets.fromLTRB(16 * scale, 10 * scale, 16 * scale, 16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '강의 목록',
            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 12 * scale),
          ListView.builder(
            itemCount: friendCourses.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final course = friendCourses[index];
              return Card(
                elevation: 1.5,
                margin: EdgeInsets.only(bottom: 12 * scale),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                child: Padding(
                  padding: EdgeInsets.all(16.0 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(fontSize: 17 * scale, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10 * scale),
                      _buildDetailRow(icon: Icons.person_outline, text: course.professor, scale: scale),
                      SizedBox(height: 5 * scale),
                      _buildDetailRow(icon: Icons.location_on, text: course.room, scale: scale),
                      SizedBox(height: 5 * scale),
                      _buildDetailRow(
                        icon: Icons.access_time_outlined,
                        text: '${dayNames[course.day]}요일 ${course.startTime}:00 - ${course.endTime}:00',
                        scale: scale
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text, required double scale}) {
    return Row(
      children: [
        Icon(icon, size: 16 * scale, color: Colors.grey[700]),
        SizedBox(width: 8 * scale),
        Text(text, style: TextStyle(fontSize: 14 * scale, color: Colors.grey[800])),
      ],
    );
  }
}