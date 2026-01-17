import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

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
      String currentSemester;
      if (now.month >= 3 && now.month <= 6) {
        currentSemester = '1학기';
      } else if (now.month >= 7 && now.month <= 8) {
        currentSemester = '여름학기';
      } else if (now.month >= 9 && now.month <= 12) {
        currentSemester = '2학기';
      } else {
        currentSemester = '겨울학기';
      }
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
        final dayId = doc.id; // monday, tuesday 등
        final data = doc.data();
        if (data['subjects'] == null) continue;

        final List<dynamic> subjectsList = data['subjects'];
        
        // 중요: 배열(List) 구조이므로 index를 ID 대용으로 사용하거나, 
        // Course 모델에서 자체 생성한 uuid를 id로 사용해야 합니다.
        for (int i = 0; i < subjectsList.length; i++) {
          final subjectData = subjectsList[i] as Map<String, dynamic>;
          
          // 여기서 courseId 대신 데이터 내부의 고유 ID를 사용합니다.
          allCourses.add(Course.fromMap(
            subjectData, 
            dayId, 
            subjectData['id'] ?? i.toString(), // ID가 없으면 인덱스라도 전달
          ));
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
        setState(() => _isLoading = false);
      }
    }
  }

  // Firebase 업데이트 함수 (저장 구조인 classes 컬렉션에 맞게 수정)
  Future<void> updateCourseInFirebase({
    required String semesterName, 
    required Course oldCourse,    
    required Course newCourse,    
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    String oldDayId = dayNames[oldCourse.day];
    String newDayId = dayNames[newCourse.day];

    final baseRef = FirebaseFirestore.instance
        .collection('timetables')
        .doc(uid)
        .collection('TableName')
        .doc(semesterName)
        .collection('classes');

    try {
      if (oldDayId == newDayId) {
        // 1. 요일이 같은 경우: 배열에서 기존 것 지우고 새 것 추가
        final docRef = baseRef.doc(oldDayId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(docRef, {
            'subjects': FieldValue.arrayRemove([oldCourse.toMap()]),
          });
          transaction.update(docRef, {
            'subjects': FieldValue.arrayUnion([newCourse.toMap()]),
          });
        });
      } else {
        // 2. 요일이 바뀐 경우: 이전 요일 문서에서 삭제, 새 요일 문서에 추가
        await baseRef.doc(oldDayId).update({
          'subjects': FieldValue.arrayRemove([oldCourse.toMap()]),
        });
        
        final newDocRef = baseRef.doc(newDayId);
        final newDocSnapshot = await newDocRef.get();
        if (!newDocSnapshot.exists) {
          await newDocRef.set({'subjects': [newCourse.toMap()]});
        } else {
          await newDocRef.update({
            'subjects': FieldValue.arrayUnion([newCourse.toMap()]),
          });
        }
      }
    } catch (e) {
      print("Firebase 업데이트 에러: $e");
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
  final screenWidth = MediaQuery.of(context).size.width;
  final double scale = screenWidth / 430;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 40 * scale),
      child: Container(
        width: 298 * scale, // CSS Rectangle 45 & 137 참조
        height: 179 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFF9), // CSS background: #FFFFF9
          borderRadius: BorderRadius.circular(10), // border-radius: 10px
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1), // border: 1px solid #E5E5E5
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), // rgba(0, 0, 0, 0.06)
              offset: const Offset(1, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // 텍스트 영역 (상단)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '시간 중복',
                      style: TextStyle(
                        fontFamily: 'Golos Text',
                        fontSize: 17 * scale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF716969),
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      "'${conflictingCourse.title}' 강의와 시간이 겹칩니다.\n기존 강의를 삭제하고 추가하시겠습니까?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Golos Text',
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: const Color(0xFF716969), // CSS color: #716969
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 하단 버튼 영역 (Subtract 영역 참고)
            Container(
              height: 47 * scale, // CSS height: 47px
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // 아니오 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                          ),
                        ),
                        child: Text(
                          '아니오',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF635E5E), // CSS color: #635E5E
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 예 버튼 (CSS 상의 '네')
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          '예',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF2F3BDC), // CSS color: #2F3BDC
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

  Route<String> _createTimetableListRoute() {
    // PageRouteBuilder에도 <String> 타입을 지정합니다.
    return PageRouteBuilder<String>(
      pageBuilder: (context, animation, secondaryAnimation) => TimetableList(),
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Route _createFriendTimetableRoute(String friendName, String friendUid) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => FriendTimetable(
        friendName: friendName,
        friendUid: friendUid,
      ),
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.easeOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {  
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFEF9),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildTimetable(),
              ),
            ),
            _buildFriendsSection(),
          ],
        ),
      ),
      // bottomNavigationBar 속성 제거
    );
  }

  
Widget _buildHeader() {
  final screenWidth = MediaQuery.of(context).size.width;
  final scale = MediaQuery.of(context).size.width / 430.0;

  return SizedBox(
    height: 80,
    child: Stack(
      children: [
        // 1. 제목 부분 (기존과 거의 동일)
        Positioned(
          left: 28,
          top: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '시간표',
                style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontSize: screenWidth * 0.065,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF504A4A)),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4.0), // 이 값을 조절해 오른쪽으로 얼마나 이동할지 정합니다.
                child: Text(
                  _currentTableName ?? '시간표 로딩 중...',
                  style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontSize: scale * 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF556283)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // 2. 아이콘 버튼 부분
        Positioned(
          top: -2,    // 숫자를 줄일수록 '위로' 이동합니다.
          right: 25,   // 숫자를 줄일수록 '오른쪽으로' 이동합니다.
          child: Row(
            children: [
              IconButton(
                icon: Image.asset(
                  'assets/images/TimeTable/add_icon.png',
                  width: 22,
                  height: 22,
                ),
                onPressed: () async {
                  final newCourse = await showDialog<Course>(
                    context: context,
                    builder: (context) => const ClassAdd(),
                  );
                  if (newCourse == null) return;
                  final conflictingCourse = _checkTimeConflict(newCourse);
                  if (conflictingCourse != null) {
                    final wannaReplace =
                        await _showConflictDialog(conflictingCourse);
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
                icon: Image.asset(
                  'assets/images/TimeTable/menu_icon.png',
                  width: 22,
                  height: 22,
                ),
                onPressed: () async {
                    // 새로 만든 커스텀 Route를 사용하여 페이지 이동
                    final newTableName = await Navigator.push<String>(
                      context,
                      _createTimetableListRoute(),
                    );
                    if (newTableName != null &&
                        newTableName != _currentTableName) {
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
        ),
      ],
    ),
  );
}

  Widget _buildTimetable() {
    int minHour = 9;
    int maxHour = 16;

    if (_courses.isNotEmpty) {
      final startTimes = _courses.map((c) => c.startTime.floor()).toList();
      final endTimes = _courses.map((c) => c.endTime.ceil()).toList();
      final earliestCourse = startTimes.reduce((minVal, e) => e < minVal ? e : minVal);
      final latestCourse = endTimes.reduce((maxVal, e) => e > maxVal ? e : maxVal);
      minHour = min(minHour, earliestCourse);
      maxHour = max(maxHour, latestCourse);
    }
    
    final int totalHours = maxHour - minHour;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 1, 14, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final timeColumnWidth = constraints.maxWidth * 0.06;
          final dayColumnWidth = (constraints.maxWidth - timeColumnWidth) / 5;
          final headerHeight = constraints.maxWidth * 0.06;
          final rowHeight = constraints.maxWidth * 0.144;
          final containerHeight = rowHeight * totalHours + headerHeight;

          return Container(
            height: containerHeight,
            decoration: BoxDecoration(
              // Container 자체에는 색상을 지정하지 않고, 테두리와 둥근 모서리 모양만 잡습니다.
              border: Border.all(color: const Color(0xFFB3A6A6), width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              // Container의 borderRadius와 똑같은 값을 줍니다.
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // 배경색과 내용은 Stack 안에서 처리합니다.
                  // 제목 행/열 배경색
                  Positioned.fill(child: Container(color: const Color(0xFFFFFDF2))),
                  // 강의 셀 부분만 덮어쓸 흰색 배경
                  Positioned(
                    top: headerHeight,
                    left: timeColumnWidth,
                    right: 0,
                    bottom: 0,
                    child: Container(color: const Color(0xFFFFFFF9)),
                  ),
                  _buildGrid(headerHeight, timeColumnWidth, dayColumnWidth, rowHeight, constraints.maxWidth, minHour, maxHour),
                  ..._courses.map((course) => _buildCourseItem(course, headerHeight, timeColumnWidth, dayColumnWidth, rowHeight, minHour)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

    Widget _buildGrid(double headerHeight, double timeColWidth, double dayColWidth, double rowHeight, double timetableWidth, int startHour, int endHour) {
    const days = ['월', '화', '수', '목', '금'];
    final times = List.generate(endHour - startHour, (i) => (startHour + i).toString());

    return Stack(
      children: [
        // 요일 행 배경색
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: Container(color: const Color(0xFFFFFDF2)),
        ),
        // 시간 열 배경색
        Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          width: timeColWidth,
          child: Container(color: const Color(0xFFFFFDF2)),
        ),

        // 1. 가로 구분선들
        ...List.generate(times.length + 1, (i) {
          return Positioned(
            top: headerHeight + (i * rowHeight),
            left: 0,
            right: 0,
            child: Container(height: 0.5, color: const Color(0xFFB3A6A6)),
          );
        }),
        
        // 2. 세로 구분선들
        Positioned(
          top: 0,
          bottom: 0,
          left: timeColWidth,
          child: Container(width: 0.5, color: const Color(0xFFB3A6A6)),
        ),
        ...List.generate(4, (i) {
          return Positioned(
            top: 0,
            bottom: 0,
            left: timeColWidth + ((i + 1) * dayColWidth),
            child: Container(width: 0.5, color: const Color(0xFFB3A6A6)),
          );
        }),

        // 3. 요일 텍스트 (월, 화, 수, 목, 금)
        ...List.generate(5, (i) => Positioned(
          top: 0,
          height: headerHeight,
          left: timeColWidth + (i * dayColWidth),
          width: dayColWidth,
          child: Center(
            child: Text(days[i], style: const TextStyle(fontFamily: 'Golos Text', fontSize: 11, color: Color(0xFF504A4A),fontWeight: FontWeight.w500))
          ),
        )),
        
        // 4. 시간 텍스트 (9, 10, 11...)
        ...List.generate(times.length, (i) => Positioned(
          top: headerHeight + (i * rowHeight),
          height: rowHeight,
          left: 0,
          width: timeColWidth,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0, right: 4.0),
              child: Text(times[i], style: const TextStyle(fontFamily: 'Golos Text', fontSize: 11, color: Color(0xFF504A4A),fontWeight: FontWeight.w500)),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCourseItem(Course course, double headerHeight,
      double timeColWidth, double dayColWidth, double rowHeight, int startHour) {
    final top = headerHeight + (course.startTime - startHour) * rowHeight;
    final height = (course.endTime - course.startTime) * rowHeight;
    final left = timeColWidth + (course.day * dayColWidth);
    final width = dayColWidth;

    return Positioned(
      top: top + 0.5,
      left: left + 0.5,
      child: GestureDetector(
        onTap: () => _showCourseDetailModal(context, course,_currentTableName ?? ''),
        child: Container(
          width: width - 0.5,
          height: height - 0.5,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: course.color,
            // borderRadius: BorderRadius.circular(4)
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: const TextStyle(fontFamily: 'Golos Text', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF504A4A)), overflow: TextOverflow.ellipsis, maxLines: 2,),
                const SizedBox(height: 0.5),
                Text(course.professor, style: const TextStyle(fontFamily: 'Golos Text', fontSize: 10.5, fontWeight: FontWeight.w400, color: Color(0xFF625B5B)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 0.5),
                Text(course.room, style: const TextStyle(fontFamily: 'Golos Text', fontSize: 10.5,fontWeight: FontWeight.w400, color: Color(0xFF625B5B)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCourseDetailModal(BuildContext context, Course course,String semesterName) {
  final screenWidth = MediaQuery.of(context).size.width;
  final double scale = screenWidth / 430;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: EdgeInsets.fromLTRB(24 * scale, 24 * scale, 24 * scale, 20 * scale),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFF9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            style: TextStyle(fontFamily: 'Golos Text', fontSize: 15 * scale, color: const Color(0xFF675F5F)),
          ),
          Text(
            "장소: ${course.room}",
            style: TextStyle(fontFamily: 'Golos Text', fontSize: 15 * scale, color: const Color(0xFF675F5F)),
          ),
          Text(
            "시간: ${formatTimeDouble(course.startTime)} - ${formatTimeDouble(course.endTime)}",
            style: TextStyle(fontFamily: 'Golos Text', fontSize: 15 * scale, color: const Color(0xFF675F5F)),
          ),
          
          SizedBox(height: 8 * scale),

          // 3. 하단 버튼 영역 (좌: 삭제 이미지, 우: 수정 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // [좌측 하단] 삭제 버튼 (이미지)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _deleteCourse(course);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // 터치 영역 확보
                  child: Image.asset(
                    'assets/images/mainpage/delete.png',
                    width: 24 * scale,
                    height: 24 * scale,
                    color: const Color(0xFF675F5F), // 삭제 버튼 느낌을 위해 붉은 계열 추천
                  ),
                ),
              ),

              // [우측 하단] 수정 버튼
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context); // 시트 닫기
                  
                  final updatedCourse = await showDialog<Course>(
                    context: context,
                    builder: (context) => ClassAdd(course: course),
                  );

                  if (updatedCourse != null) {
                    // 에러 났던 부분을 인자로 받은 semesterName으로 교체합니다.
                    await updateCourseInFirebase(
                      semesterName: semesterName, 
                      oldCourse: course, 
                      newCourse: updatedCourse,
                    );

                    setState(() {
                      // Firebase 업데이트 후 화면을 다시 그립니다.
                      _loadCourses(); 
                    });
                  }
                },
                child: Container(
                  width: 65 * scale,
                  height: 38 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF504A4A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "수정",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Golos Text',
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}




  Widget _buildFriendsSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.055;
    final separatorHeight = screenHeight * 0.008;
    final sectionHeight = screenHeight * 0.2; // 친구 버튼 크기 

    return Container(
      height: sectionHeight,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFACACAC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '친구 시간표',
              style: TextStyle(fontFamily: 'Golos Text', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF504A4A)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  itemCount: friendDocs.length,
                  itemBuilder: (context, index) {
                    final friendDoc = friendDocs[index];
                    final friendUid = friendDoc.id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return _buildFriendButton(context, '로딩 중...', friendUid, buttonHeight);
                        }
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return _buildFriendButton(context, '알 수 없는 친구', friendUid, buttonHeight);
                        }

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final friendName = userData['name'] ?? '이름 없음';

                        return _buildFriendButton(context, friendName, friendUid, buttonHeight);
                      },
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: separatorHeight),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendButton(BuildContext context, String name, String uid, double buttonHeight) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          _createFriendTimetableRoute(name, uid),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F5F5F),
        foregroundColor: const Color(0xFFFFFFF9),
        minimumSize: Size(double.infinity, buttonHeight),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontFamily: 'Golos Text', fontSize: 15.5, fontWeight: FontWeight.w500)),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}