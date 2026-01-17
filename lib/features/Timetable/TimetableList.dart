import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_project_1/features/Settings/TitleHandler.dart';
import 'TimetableScreen.dart';

// Firestore에 저장된 시간표의 메타데이터를 관리하는 데이터 모델 클래스입니다.
class TimetableInfo {
  final String tableName; // 시간표 문서 ID (예: "2025년 2학기")
  final String year; // 연도
  final String semester; // 학기
  final Color color; // 시간표 목록에서 표시될 배경색
  final Timestamp createdAt; // 생성 시간 (정렬에 사용)

  TimetableInfo({
    required this.tableName,
    required this.year,
    required this.semester,
    required this.color,
    required this.createdAt,
  });

  // Firestore의 DocumentSnapshot으로부터 TimetableInfo 객체를 생성하는 팩토리 생성자입니다.
  factory TimetableInfo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TimetableInfo(
      tableName: doc.id,
      year: data['year'] ?? '',
      semester: data['semester'] ?? '',
      // Firestore에 저장된 16진수 색상 문자열을 Color 객체로 변환합니다.
      // 값이 null일 경우 기본 색상을 사용해 오류를 방지합니다.
      color: Color(int.parse(data['color'] ?? 'FFDDEBF1', radix: 16)),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

// 사용자의 모든 시간표 목록을 표시하는 화면 위젯입니다.
class TimetableList extends StatefulWidget {
  const TimetableList({super.key});

  @override
  State<TimetableList> createState() => _TimetableListState();
}

class _TimetableListState extends State<TimetableList> {
  // Firestore에서 불러온 시간표 목록을 저장하는 리스트입니다.
  List<TimetableInfo> _timetables = [];
  // 데이터 로딩 상태를 관리하는 변수입니다. true이면 로딩 중을 표시합니다.
  bool _isLoading = true;

  // 위젯이 생성될 때 처음 한 번 호출되는 초기화 메소드입니다.
  @override
  void initState() {
    super.initState();
    // Firestore에서 시간표 목록을 비동기적으로 불러옵니다.
    _loadTimetables();
  }

  // Firestore에서 현재 사용자의 시간표 목록을 불러오는 비동기 메소드입니다.
  Future<void> _loadTimetables() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final uid = user.uid;

    try {
      // Firestore 경로를 지정하여 'TableName' 컬렉션의 데이터를 가져옵니다.
      // 생성 시간(createdAt)을 기준으로 내림차순 정렬합니다.
      final snapshot =
          await FirebaseFirestore.instance
              .collection('timetables')
              .doc(uid)
              .collection('TableName')
              .orderBy('createdAt', descending: true)
              .get();

      // 가져온 문서들을 TimetableInfo 객체 리스트로 변환합니다.
      final timetables =
          snapshot.docs.map((doc) => TimetableInfo.fromFirestore(doc)).toList();

      // 위젯이 아직 화면에 마운트된 상태일 때만 state를 업데이트합니다.
      if (mounted) {
        setState(() {
          _timetables = timetables;
          _isLoading = false; // 로딩 완료 상태로 변경
        });
      }
    } catch (e) {
      print("시간표 목록 로딩 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 새로운 시간표 정보를 Firestore에 추가하는 비동기 메소드입니다.
  Future<void> _addTimetableToFirestore(TimetableInfo newTimetable) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('timetables')
        .doc(user.uid)
        .collection('TableName')
        .doc(newTimetable.tableName);

    // 전달받은 newTimetable 객체의 데이터를 Firestore 문서에 저장합니다.
    await docRef.set({
      'year': newTimetable.year,
      'semester': newTimetable.semester,
      'color': newTimetable.color.value.toRadixString(
        16,
      ), // Color 객체를 16진수 문자열로 변환
      'tableName': newTimetable.tableName,
      'createdAt': newTimetable.createdAt,
    });
    // 시간표 개수 계산
    int scheduleCount = await getTotalSchedule();

    // schedule 관련 타이틀 처리(누적)
    await handleScheduleCountTitle(
      scheduleCount,
      onUpdate: () => setState(() {}),
    );

    _loadTimetables();
  }

  // 추가: 선택된 시간표를 Firestore에서 삭제하는 비동기 메소드
  Future<void> _deleteTimetable(String tableName) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final screenWidth = MediaQuery.of(context).size.width;
  final double scale = screenWidth / 411; // CSS 기준 너비 대비 비율

  // 1. 커스텀 삭제 확인 다이얼로그
  final bool confirmDelete = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 40 * scale),
      child: Container(
        width: 298 * scale,  // CSS width: 298px
        height: 179 * scale, // CSS height: 179px (Rectangle 137 참조)
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFF9), // CSS background: #FFFFF9
          borderRadius: BorderRadius.circular(10), // border-radius: 10px
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(1, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // 상단 메시지 영역
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                child: Text(
                  '시간표를 삭제하시겠습니까?', // CSS "로그아웃 하시겠습니까?" 스타일 참조
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500, // font-weight: 520
                    color: const Color(0xFF716969), // color: #716969
                  ),
                ),
              ),
            ),
            // 하단 버튼 영역 (Subtract 영역)
            Container(
              height: 47 * scale, // CSS height: 47px
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // '아니오' 버튼
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
                            color: const Color(0xFF635E5E), // color: #635E5E
                          ),
                        ),
                      ),
                    ),
                  ),
                  // '네' (삭제) 버튼
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          '네',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF2F3BDC), // color: #2F3BDC
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
  ) ?? false;

  if (!confirmDelete) return;

  try {
    await FirebaseFirestore.instance
        .collection('timetables')
        .doc(user.uid)
        .collection('TableName')
        .doc(tableName)
        .delete();

    _loadTimetables();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시간표가 삭제되었습니다.')),
      );
    }
  } catch (e) {
    print("시간표 삭제 실패: $e");
  }
}

  // '시간표 추가' 다이얼로그를 표시하는 메소드입니다.
  void _showAddTimetableDialog() async {
    // showDialog는 Future를 반환하며, 다이얼로그가 닫힐 때 값을 전달받을 수 있습니다.
    final newTimetable = await showDialog<TimetableInfo>(
      context: context,
      barrierDismissible: false, // 다이얼로그 바깥을 터치해도 닫히지 않도록 설정
      builder: (BuildContext context) => const AddTimetableModal(),
    );

    // 다이얼로그에서 정상적으로 TimetableInfo 객체를 반환받았을 경우에만 Firestore에 추가합니다.
    if (newTimetable != null) {
      await _addTimetableToFirestore(newTimetable);
    }
  }

  // 위젯의 UI를 구성하는 빌드 메소드입니다.
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
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
          "시간표 목록",
          style: TextStyle(
            fontFamily: 'Golos Text',
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.047,
            color: Color(0xFF504A4A),
          ),
        ),
        centerTitle: false,
        actions: [
          // CSS Rectangle 80 & 시간표 추가 + 반영
          Padding(
            padding: EdgeInsets.only(right: 20, top: 10, bottom: 10),
            child: GestureDetector(
              onTap: _showAddTimetableDialog,
              child: Container(
                width: 110,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '시간표 추가 +',
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: const Color(0xFF504A4A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: screenWidth * 0.04,
                  mainAxisSpacing: screenWidth * 0.04,
                  childAspectRatio: 0.85,
                ),
                itemCount: _timetables.length,
                itemBuilder: (context, index) {
                  final timetable = _timetables[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context, timetable.tableName);
                    },
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: timetable.color,
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.black54,
                                size: screenWidth * 0.055,
                              ),
                              onPressed: () {
                                _deleteTimetable(timetable.tableName);
                              },
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${timetable.year}년",
                                style: TextStyle(
                                  fontFamily: 'Golos Text',
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF504A4A),
                                ),
                              ),
                              Text(
                                timetable.semester,
                                style: TextStyle(
                                  color: const Color(0xFF675F5F),
                                  fontFamily: 'Golos Text',
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// 새 시간표를 추가하기 위한 다이얼로그 위젯입니다.
// 새 시간표를 추가하기 위한 다이얼로그 위젯입니다.
class AddTimetableModal extends StatefulWidget {
  const AddTimetableModal({super.key});
  @override
  State<AddTimetableModal> createState() => _AddTimetableModalState();
}

class _AddTimetableModalState extends State<AddTimetableModal> {
  final _yearController = TextEditingController(); //
  final _formKey = GlobalKey<FormState>(); //
  final List<String> _semesterOptions = ['1학기', '2학기', '여름학기', '겨울학기']; //
  String? _selectedSemester; //
  
  // CSS에 정의된 색상 목록
  final List<Color> _colorOptions = const [
    Color(0xFFCDDEE3), Color(0xFF8E9CBF), Color(0xFF97B4C7),
    Color(0xFFBBCDC0), Color(0xFFE5EAEF), Color(0xFFE8EBDF),
  ];

  late Color _selectedColor; //

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString(); // 초기값 설정
    _selectedColor = _colorOptions.first; //
  }

  @override
  void dispose() {
    _yearController.dispose(); //
    super.dispose();
  }

  void _addTimetable() {
    if (_formKey.currentState!.validate()) { //
      final year = _yearController.text; //
      final semester = _selectedSemester!; //
      final tableName = "$year년 $semester"; //
      
      final newTimetable = TimetableInfo(
        tableName: tableName,
        year: year,
        semester: semester,
        color: _selectedColor,
        createdAt: Timestamp.now(),
      );
      Navigator.of(context).pop(newTimetable); //
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 411.0;
    final circleSize = 35 * scale;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
      backgroundColor: const Color(0xFFFFFFF9),
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '새 시간표 추가',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Golos Text',
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF504A4A),
                ),
              ),
              SizedBox(height: 25 * scale),

              // 1. 년도 입력 커스텀 스타일
              Text(
                "년도",
                style: TextStyle(
                  fontFamily: 'Golos Text',
                  fontSize: 14 * scale,
                  color: const Color(0xFF716969),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5 * scale), // 제목과 입력칸 사이 간격
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontFamily: 'Golos Text', fontSize: 16 * scale),
                decoration: InputDecoration(
                  // labelText 제거
                  hintText: '예: 2025', // 입력값이 없을 때 보여줄 가이드 (선택 사항)
                  hintStyle: TextStyle(color: const Color(0xFFACACAC), fontSize: 14 * scale),
                  isDense: true, // 내부 패딩을 줄여 텍스트와 밑줄 사이 간격을 조절
                  contentPadding: EdgeInsets.symmetric(vertical: 8 * scale),
                  // CSS Border 스타일 직접 제어
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5E5E5))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF504A4A))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? '년도를 입력하세요.' : null,
              ),
              SizedBox(height: 25 * scale),

              // 2. 학기 선택 (기존 보라색 드롭다운 제거 -> 직접 커스텀 가능한 칩 스타일)
              Text(
                "학기 선택",
                style: TextStyle(
                  fontFamily: 'Golos Text',
                  fontSize: 14 * scale,
                  color: const Color(0xFF716969),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12 * scale),
              Wrap(
                spacing: 8 * scale,
                runSpacing: 8 * scale,
                children: _semesterOptions.map((semester) {
                  final isSelected = _selectedSemester == semester;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSemester = semester),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                      decoration: BoxDecoration(
                        // [CSS 수정 포인트] 배경색 제어
                        color: isSelected ? const Color(0xFF8E9CBF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10 * scale),
                        // [CSS 수정 포인트] 테두리 제어
                        border: Border.all(
                          color: isSelected ? const Color.fromARGB(255, 126, 142, 185) : const Color(0xFFE5E5E5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        semester,
                        style: TextStyle(
                          fontFamily: 'Golos Text',
                          fontSize: 14 * scale,
                          // [CSS 수정 포인트] 글자색 제어
                          color: isSelected ? Colors.white : const Color(0xFF716969),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              SizedBox(height: 25 * scale),

              // 3. 색상 선택 (동일 유지)
              Text(
                "테마 색상",
                style: TextStyle(
                  fontFamily: 'Golos Text',
                  fontSize: 14 * scale,
                  color: const Color(0xFF716969),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12 * scale),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colorOptions.map((color) {
                  bool isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: const Color(0xFF504A4A), width: 2)
                            : Border.all(color: Colors.transparent),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 35 * scale),

              // 4. 하단 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // 버튼들을 오른쪽으로 정렬
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('취소', style: TextStyle(fontFamily: 'Golos Text', color: Color(0xFFACACAC), fontSize: 16 * scale)),
                  ),
                  SizedBox(width: 20 * scale),
                  // Expanded를 제거하고 크기를 고정
                  SizedBox(
                    width: 80 * scale, // 원하는 가로 너비값으로 조절하세요
                    height: 40 * scale, // 높이 조절
                    child: ElevatedButton(
                      onPressed: _addTimetable,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF504A4A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        padding: EdgeInsets.zero, // 내부 패딩 제거해야 지정한 사이즈가 잘 적용됩니다.
                      ),
                      child: Text('추가', style: TextStyle(fontFamily: 'Golos Text', color: Colors.white, fontSize: 15 * scale, fontWeight: FontWeight.w400)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

