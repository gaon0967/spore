import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // 데이터 추가 후 목록을 새로고침합니다.
    _loadTimetables();
  }

  // ✅ 추가: 선택된 시간표를 Firestore에서 삭제하는 비동기 메소드
  Future<void> _deleteTimetable(String tableName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 사용자에게 삭제 확인 다이얼로그를 표시합니다.
    final bool confirmDelete =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('시간표 삭제'),
                content: const Text('정말로 이 시간표를 삭제하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false), // 취소
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ), // 삭제 확인
                    child: const Text('삭제'),
                  ),
                ],
              ),
        ) ??
        false; // null이면 false 반환

    if (!confirmDelete) return; // 사용자가 삭제를 취소하면 함수 종료

    try {
      // 삭제할 문서의 경로를 지정합니다.
      final docRef = FirebaseFirestore.instance
          .collection('timetables')
          .doc(user.uid)
          .collection('TableName')
          .doc(tableName);

      // 문서를 삭제합니다.
      await docRef.delete();

      // 삭제 성공 후 목록을 새로고침합니다.
      _loadTimetables();
      if (mounted) {
        // 사용자에게 삭제 완료 메시지를 표시합니다.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('시간표가 삭제되었습니다.')));
      }
    } catch (e) {
      print("시간표 삭제 실패: $e");
      if (mounted) {
        // 오류 메시지를 표시합니다.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('시간표 삭제에 실패했습니다.')));
      }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // 뒤로가기
        ),
        title: const Text(
          '시간표 목록',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _showAddTimetableDialog, // '시간표 추가' 버튼 클릭 시 다이얼로그 표시
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
          ),
        ],
      ),
      // 로딩 상태에 따라 다른 위젯을 표시합니다.
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때
              : Padding(
                padding: const EdgeInsets.all(16.0),
                // GridView.builder를 사용해 시간표 목록을 격자 형태로 효율적으로 표시합니다.
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 한 줄에 2개의 아이템
                    crossAxisSpacing: 16, // 아이템 간 가로 간격
                    mainAxisSpacing: 16, // 아이템 간 세로 간격
                    childAspectRatio: 0.8, // 아이템의 가로/세로 비율
                  ),
                  itemCount: _timetables.length,
                  itemBuilder: (context, index) {
                    final timetable = _timetables[index];
                    // 각 시간표 항목을 GestureDetector로 감싸 탭 이벤트를 처리합니다.
                    return GestureDetector(
                      onTap: () {
                        // 현재 화면을 닫고 이전 화면(TimetableScreen)으로 선택된 시간표의 이름을 전달합니다.
                        Navigator.pop(context, timetable.tableName);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: timetable.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // ✅ 추가: 휴지통 아이콘 버튼
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.black54,
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
class AddTimetableModal extends StatefulWidget {
  const AddTimetableModal({super.key});
  @override
  State<AddTimetableModal> createState() => _AddTimetableModalState();
}

class _AddTimetableModalState extends State<AddTimetableModal> {
  // TextFormField의 입력을 제어하기 위한 컨트롤러입니다.
  final _yearController = TextEditingController();
  // Form 위젯의 상태를 관리하기 위한 GlobalKey입니다. (유효성 검사 등)
  final _formKey = GlobalKey<FormState>();
  // 드롭다운 메뉴에 표시될 학기 목록입니다.
  final List<String> _semesterOptions = ['1학기', '2학기', '여름학기', '겨울학기'];
  // 현재 선택된 학기를 저장하는 변수입니다.
  String? _selectedSemester;
  // 선택 가능한 색상 목록입니다.
  final List<Color> _colorOptions = const [
    Color(0xFFDDEBF1),
    Color(0xFFD4DAF5),
    Color(0xFFA9C5D8),
    Color(0xFFC7D7CB),
    Color(0xFFE3E8EE),
    Color(0xFFE9EBE0),
  ];
  // 현재 선택된 색상을 저장하는 변수입니다.
  late Color _selectedColor;

  // 위젯 초기화 시 호출됩니다.
  @override
  void initState() {
    super.initState();
    // 년도 입력 필드의 초기값을 현재 년도로 설정합니다.
    _yearController.text = DateTime.now().year.toString();
    // 선택된 색상의 초기값을 색상 목록의 첫 번째 색으로 설정합니다.
    _selectedColor = _colorOptions.first;
  }

  // 위젯이 화면에서 제거될 때 호출됩니다.
  @override
  void dispose() {
    // 메모리 누수를 방지하기 위해 컨트롤러를 제거합니다.
    _yearController.dispose();
    super.dispose();
  }

  // '추가' 버튼을 눌렀을 때 실행되는 메소드입니다.
  void _addTimetable() {
    // Form의 유효성 검사를 통과했을 경우에만 실행됩니다.
    if (_formKey.currentState!.validate()) {
      final year = _yearController.text;
      final semester = _selectedSemester!;
      final tableName = "$year년 $semester";
      // 입력된 정보로 새로운 TimetableInfo 객체를 생성합니다.
      final newTimetable = TimetableInfo(
        tableName: tableName,
        year: year,
        semester: semester,
        color: _selectedColor,
        createdAt: Timestamp.now(),
      );
      // 다이얼로그를 닫으면서 생성된 객체를 이전 화면으로 전달합니다.
      Navigator.of(context).pop(newTimetable);
    }
  }

  // 다이얼로그의 UI를 구성합니다.
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        // Form 위젯으로 감싸 유효성 검사를 쉽게 처리합니다.
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물의 크기만큼만 다이얼로그 크기를 설정
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '새 시간표 추가',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // 년도 입력 필드
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '년도',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) => v == null || v.trim().isEmpty ? '년도를 입력하세요.' : null,
              ),
              const SizedBox(height: 16),
              // 학기 선택 드롭다운 메뉴
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                items:
                    _semesterOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedSemester = v),
                decoration: const InputDecoration(
                  labelText: '학기',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? '학기를 선택하세요.' : null,
              ),
              const SizedBox(height: 24),
              // 색상 선택 UI
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _colorOptions.map((color) {
                        bool isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 6.0),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border:
                                  isSelected
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // 취소, 추가 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addTimetable,
                    child: const Text('추가'),
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
