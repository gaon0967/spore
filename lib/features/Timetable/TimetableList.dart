import 'package:flutter/material.dart';

// 시간표 데이터를 표현하기 위한 간단한 모델 클래스
class SemesterTimetable {
  final String year;
  final String semester;
  final Color color;

  SemesterTimetable(
      {required this.year, required this.semester, required this.color});
}

class TimetableList extends StatefulWidget {
  const TimetableList({super.key});

  @override
  State<TimetableList> createState() => _TimetableListState();
}

class _TimetableListState extends State<TimetableList> {
  // 샘플 데이터 리스트
  final List<SemesterTimetable> timetables = [
    SemesterTimetable(
        year: '2025', semester: '여름학기', color: const Color(0xFFDDEBF1)),
    SemesterTimetable(
        year: '2025', semester: '1학기', color: const Color(0xFFD4DAF5)),
    SemesterTimetable(
        year: '2024', semester: '겨울학기', color: const Color(0xFFA9C5D8)),
    SemesterTimetable(
        year: '2024', semester: '2학기', color: const Color(0xFFC7D7CB)),
    SemesterTimetable(
        year: '2024', semester: '여름학기', color: const Color(0xFFE3E8EE)),
    SemesterTimetable(
        year: '2024', semester: '1학기', color: const Color(0xFFE9EBE0)),
  ];

  // 선택된 시간표의 인덱스를 저장
  int _selectedIndex = 0;

  // [수정] 시간표 추가 버튼을 눌렀을 때 실행될 함수
  void _showAddTimetableDialog() async {
    // showDialog가 반환하는 값을 받음 (추가된 시간표 정보)
    final newTimetable = await showDialog<SemesterTimetable>(
      context: context,
      barrierDismissible: false, // 바깥 영역을 탭해도 닫히지 않음
      builder: (BuildContext context) {
        return const AddTimetableModal();
      },
    );

    // 반환된 값이 있으면 (null이 아니면) 리스트에 추가
    if (newTimetable != null) {
      setState(() {
        // 리스트의 가장 앞에 새로운 시간표를 추가
        timetables.insert(0, newTimetable);
        // 새로 추가된 아이템을 선택된 상태로 변경
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
              // [수정] onPressed에 _showAddTimetableDialog 함수 연결
              onPressed: _showAddTimetableDialog,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: timetables.length,
          itemBuilder: (context, index) {
            final timetable = timetables[index];
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: timetable.color,
                  borderRadius: BorderRadius.circular(16),
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
    );
  }
}

// ## [추가] 새로운 시간표를 추가하기 위한 모달 다이얼로그 위젯 ##
class AddTimetableModal extends StatefulWidget {
  const AddTimetableModal({super.key});

  @override
  State<AddTimetableModal> createState() => _AddTimetableModalState();
}

class _AddTimetableModalState extends State<AddTimetableModal> {
  final _yearController = TextEditingController();
  final _semesterController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 선택 가능한 색상 목록
  final List<Color> _colorOptions = const [
    Color(0xFFDDEBF1), Color(0xFFD4DAF5), Color(0xFFA9C5D8),
    Color(0xFFC7D7CB), Color(0xFFE3E8EE), Color(0xFFE9EBE0),
  ];
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    // 현재 년도를 기본값으로 설정
    _yearController.text = DateTime.now().year.toString();
    // 첫 번째 색상을 기본 선택 색상으로 설정
    _selectedColor = _colorOptions.first;
  }

  @override
  void dispose() {
    _yearController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  void _addTimetable() {
    // Form의 유효성 검사를 통과하면 시간표를 생성하고 모달을 닫음
    if (_formKey.currentState!.validate()) {
      final newTimetable = SemesterTimetable(
        year: _yearController.text,
        semester: _semesterController.text,
        color: _selectedColor,
      );
      // Navigator.pop을 통해 이전 화면에 newTimetable 객체를 전달
      Navigator.of(context).pop(newTimetable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // 컨텐츠 크기에 맞게 조절
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '년도를 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 학기 입력 필드
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(
                  labelText: '학기',
                  hintText: '예: 1학기, 여름학기',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '학기를 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // 색상 선택
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _colorOptions.map((color) {
                  bool isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 3)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // 버튼 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(), // 그냥 닫기
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