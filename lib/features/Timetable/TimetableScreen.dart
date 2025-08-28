import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'course_model.dart';
import 'TimetableList.dart';
import 'ClassAdd.dart';
import 'FriendTimetable.dart';

class TimetableScreen extends StatefulWidget {
  final String? tableName;
  const TimetableScreen({super.key, this.tableName});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _currentTableName;

  final List<String> _dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant TimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tableName != null && widget.tableName != oldWidget.tableName) {
      setState(() {
        _currentTableName = widget.tableName;
        _isLoading = true;
      });
      _loadCourses();
    }
  }

  Future<void> _initialize() async {
    _currentTableName = widget.tableName;

    if (_currentTableName == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      final currentYear = now.year.toString();
      final currentSemester = (now.month >= 1 && now.month <= 6) ? '1학기' : '2학기';
      final defaultTableName = "$currentYear년 $currentSemester";

      final docRef = FirebaseFirestore.instance
          .collection('timetables')
          .doc(user.uid)
          .collection('TableName')
          .doc(defaultTableName);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        await docRef.set({
          'year': currentYear,
          'semester': currentSemester,
          'tableName': defaultTableName,
          'color': 'ffddebf1',
          'createdAt': Timestamp.now(),
        });
      }
      if (mounted) {
        _currentTableName = defaultTableName;
      }
    }
    await _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (_currentTableName == null || !mounted) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .doc(user.uid)
          .collection('TableName')
          .doc(_currentTableName!)
          .collection('classes')
          .get();

      List<Course> allCourses = [];
      for (var doc in snapshot.docs) {
        final dayId = doc.id;
        final data = doc.data();
        if (data['subjects'] == null) continue;

        final List<dynamic> subjectsList = data['subjects'];
        for (var subjectData in subjectsList) {
          allCourses.add(Course.fromMap(subjectData as Map<String, dynamic>, dayId));
        }
      }

      if (mounted) {
        setState(() {
          _courses = allCourses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("수업 로딩 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시간표를 불러오는 중 오류가 발생했습니다.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCourse(Course newCourse) async {
    if (_currentTableName == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String dayId = _dayNames[newCourse.day];
    final docRef = FirebaseFirestore.instance
        .collection('timetables')
        .doc(user.uid)
        .collection('TableName')
        .doc(_currentTableName!)
        .collection('classes')
        .doc(dayId);

    final newCourseMap = newCourse.toMap();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      if (!docSnapshot.exists) {
        transaction.set(docRef, {'subjects': [newCourseMap]});
      } else {
        transaction.update(docRef, {
          'subjects': FieldValue.arrayUnion([newCourseMap])
        });
      }
    });

    await _loadCourses();
  }

  Future<void> _deleteCourse(Course courseToDelete) async {
    if (_currentTableName == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String dayId = _dayNames[courseToDelete.day];
    final docRef = FirebaseFirestore.instance
        .collection('timetables')
        .doc(user.uid)
        .collection('TableName')
        .doc(_currentTableName!)
        .collection('classes')
        .doc(dayId);

    final courseMapToRemove = courseToDelete.toMap();

    await docRef.update({
      'subjects': FieldValue.arrayRemove([courseMapToRemove])
    });

    // 즉시 UI에서 제거
  if (mounted) {
    setState(() {
      _courses.removeWhere((c) =>
        c.title == courseToDelete.title &&
        c.startTime == courseToDelete.startTime &&
        c.endTime == courseToDelete.endTime &&
        c.day == courseToDelete.day
      );
    });
  }

  // Firestore에서 최신 데이터 다시 불러오기
  await _loadCourses();
  }
String formatTimeDouble(double time) {
    int hour = time.floor();
    int minute = ((time - hour) * 60).round();
    String minStr = minute.toString().padLeft(2, '0');
    return '$hour:$minStr';
  }



  Course? _checkTimeConflict(Course newCourse) {
    for (var existingCourse in _courses) {
      if (existingCourse.day == newCourse.day &&
          newCourse.startTime < existingCourse.endTime &&
          existingCourse.startTime < newCourse.endTime) {
        return existingCourse;
      }
    }
    return null;
  }

  Future<bool> _showConflictDialog(Course conflictingCourse) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시간 중복'),
        content: Text("'${conflictingCourse.title}' 강의와 시간이 겹칩니다. 기존 강의를 삭제하고 추가하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('아니오')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('예')),
        ],
      ),
    );
    return result ?? false;
  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  if (_isLoading) return const Center(child: CircularProgressIndicator());

  return SafeArea(
    top: true, // 상단만 안전영역 적용
    child: Column(
      children: [
        _buildHeader(screenWidth), // 헤더 바로 출력, padding 없음
        // 위에 SizedBox, Padding 등 추가하지 마세요
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTimetable(screenWidth, screenHeight),
                _buildFriendsSection(screenWidth, screenHeight),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


Widget _buildHeader(double screenWidth) {
  final horizontalPadding = screenWidth * 0.055;
  final titleFontSize = screenWidth * 0.07;
  final subtitleFontSize = screenWidth * 0.03;
  final iconSize = screenWidth * 0.06;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0), // verticalPadding을 0으로!
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('시간표', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600, color: const Color(0xFF504A4A))),
              SizedBox(height: screenWidth * 0.01),
              Text(
                _currentTableName ?? '시간표 로딩 중...',
                style: TextStyle(fontSize: subtitleFontSize, fontWeight: FontWeight.w600, color: const Color(0xFF556283)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.add, size: iconSize, color: const Color(0xFF3B3737)),
              onPressed: () async {
                final newCourse = await showDialog<Course>(
                  context: context,
                  builder: (context) => const ClassAdd(),
                );
                if (newCourse == null) return;
                final conflictingCourse = _checkTimeConflict(newCourse);
                if (conflictingCourse != null) {
                  final wannaReplace = await _showConflictDialog(conflictingCourse);
                  if (wannaReplace) {
                    await _deleteCourse(conflictingCourse);
                    await _addCourse(newCourse);
                  }
                } else {
                  await _addCourse(newCourse);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.menu, size: iconSize, color: const Color(0xFF3B3737)),
              onPressed: () async {
                final newTableName = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => TimetableList()),
                );
                if (newTableName != null && newTableName != _currentTableName) {
                  setState(() {
                    _currentTableName = newTableName;
                    _isLoading = true;
                  });
                  await _loadCourses();
                }
              },
            ),
          ],
        ),
      ],
    ),
  );
}


       
  
  

  Widget _buildTimetable(double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.fromLTRB(screenWidth * 0.035, 0, screenWidth * 0.035, screenHeight * 0.02),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final timeColumnWidth = constraints.maxWidth * 0.07;
          final dayColumnWidth = (constraints.maxWidth - timeColumnWidth) / 5;
          final headerHeight = constraints.maxWidth * 0.05;
          final rowHeight = screenHeight * 0.06;
          final containerHeight = rowHeight * 10 + headerHeight;

          return Container(
            height: containerHeight,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB3A6A6), width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                _buildGrid(headerHeight, timeColumnWidth, dayColumnWidth, rowHeight, constraints.maxWidth),
                ..._courses.map((course) => _buildCourseItem(course, headerHeight, timeColumnWidth, dayColumnWidth, rowHeight)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(double headerHeight, double timeColWidth, double dayColWidth, double rowHeight, double timetableWidth) {
    const days = ['월', '화', '수', '목', '금'];
    const times = ['9','10','11','12','13','14','15','16','17','18'];
    final fontSize = timetableWidth * 0.028;

    return Stack(
      children: [
        // 가로줄
        ...List.generate(times.length + 1, (i) => Positioned(
          left: 0, right: 0, top: headerHeight + (i * rowHeight),
          child: Container(height: 0.5, color: const Color(0xFFB3A6A6))
        )),
        // 세로줄
        ...List.generate(6, (i) => Positioned(
          top: 0, bottom: 0,
          left: timeColWidth + (i * dayColWidth),
          child: Container(width: 0.5, color: const Color(0xFFB3A6A6))
        )),
        // 요일 텍스트
        ...List.generate(5, (i) => Positioned(
          top: headerHeight * 0.25,
          left: timeColWidth + (i * dayColWidth),
          width: dayColWidth,
          child: Center(child: Text(days[i], style: TextStyle(fontSize: fontSize, color: const Color(0xFF504A4A))))
        )),
        // 시간 텍스트
        ...List.generate(times.length, (i) => Positioned(
          top: headerHeight + (i * rowHeight) + (rowHeight * 0.05),
          left: timeColWidth * 0.2,
          child: Text(times[i], style: TextStyle(fontSize: fontSize, color: const Color(0xFF504A4A)))
        )),
      ],
    );
  }



Widget _buildCourseItem(Course course, double headerHeight,
    double timeColWidth, double dayColWidth, double rowHeight) {
  final top = headerHeight + (course.startTime - 9) * rowHeight;
  final height = (course.endTime - course.startTime) * rowHeight;
  final left = timeColWidth + (course.day * dayColWidth);
  final width = dayColWidth;

return Positioned(
  top: top,
  left: left,
  child: GestureDetector(
    onTap: () => _showCourseDetailModal(context, course),
    child: Container(
      width: width - 0.5,
      height: height - 0.5,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: course.color,
        borderRadius: BorderRadius.circular(4)
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(course.professor, style: const TextStyle(fontSize: 9)),
            const SizedBox(height: 2),
            Text(course.room, style: const TextStyle(fontSize: 9)),
          ],
        ),
      ),
    ),
  ),
);
    }

  void _showCourseDetailModal(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFF9),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("교수: ${course.professor}", style: const TextStyle(fontSize: 16)),
            Text("장소: ${course.room}", style: const TextStyle(fontSize: 16)),

            // 시간 0.5가 아니라 30분으로 나오게 변경 
            Text(
  "시간: ${formatTimeDouble(course.startTime)} - ${formatTimeDouble(course.endTime)}",
  style: const TextStyle(fontSize: 16),
),
            const Divider(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _deleteCourse(course);
              },
              child: const Row(children: [
                Icon(Icons.delete_outline, color: Colors.grey), SizedBox(width: 6), Text("삭제")
              ]),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildFriendsSection(double screenWidth, double screenHeight) {
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.03;
    final titleFontSize = screenWidth * 0.035;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screenWidth * 0.05),
          topRight: Radius.circular(screenWidth * 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.01),
            decoration: BoxDecoration(
              color: const Color(0xFFC9C9C9),
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
            ),
            child: Text(
              '친구 시간표',
              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600, color: const Color(0xFF5F5F5F)),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // Firestore에서 현재 사용자의 친구 목록을 가져오는 StreamBuilder
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('friends')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('오류: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('친구가 없습니다.'));
              }

              final friendDocs = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: friendDocs.length,
                itemBuilder: (context, index) {
                  final friendDoc = friendDocs[index];
                  final friendUid = friendDoc.id; // 친구의 UID는 문서 ID로 가져옵니다.

                  return FutureBuilder<DocumentSnapshot>(
                    // 친구의 UID로 'users' 컬렉션에서 이름을 조회합니다.
                    future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return _buildFriendButton(context, '로딩 중...', friendUid, screenWidth, screenHeight);
                      }
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return _buildFriendButton(context, '알 수 없는 친구', friendUid, screenWidth, screenHeight);
                      }

                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      final friendName = userData['name'] ?? '이름 없음';

                      return _buildFriendButton(context, friendName, friendUid, screenWidth, screenHeight);
                    },
                  );
                },
                separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.015),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendButton(BuildContext context, String name, String uid, double screenWidth, double screenHeight) {
    final buttonFontSize = screenWidth * 0.04;
    final iconSize = screenWidth * 0.04;

    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          // Pass both the name and the UID to the FriendTimetable widget
          MaterialPageRoute(builder: (context) => FriendTimetable(friendName: name, friendUid: uid)),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF757575),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, screenHeight * 0.06),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.025)),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w600)),
          Icon(Icons.arrow_forward_ios, size: iconSize),
        ],
      ),
    );
  }
}