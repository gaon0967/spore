import 'package:flutter/material.dart';
import 'TimetableScreen.dart';
import 'course_model.dart';
import 'ClassAdd.dart';

// 시간표 데이터를 표현하기 위한 간단한 모델 클래스
class SemesterTimetable {
  final String year;
  final String semester;
  final Color color;

  SemesterTimetable({
    required this.year,
    required this.semester,
    required this.color,
  });
}

class TimetableList extends StatefulWidget {
  final Map<String, List<Course>> allTimetableCourses;
  const TimetableList({super.key, required this.allTimetableCourses});

  @override
  State<TimetableList> createState() => _TimetableListState();
}

final List<String> _semesterOptions = ['1학기', '2학기', '여름학기', '겨울학기'];

class _TimetableListState extends State<TimetableList> {
  late List<SemesterTimetable> _timetables;
  int _selectedIndex = 0; // 선택된 시간표의 인덱스를 저장

  @override
  void initState() {
    super.initState();
    _loadTimetables();
  }

  // 이 메소드는 위젯이 업데이트될 때마다 호출되어야 하므로 didUpdateWidget에서도 호출합니다.
  @override
  void didUpdateWidget(covariant TimetableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allTimetableCourses.keys.length !=
        oldWidget.allTimetableCourses.keys.length) {
      _loadTimetables();
    }
  }

  void _loadTimetables() {
    final List<String> keys = widget.allTimetableCourses.keys.toList();
    _timetables =
        keys.map((key) {
          final parts = key.split('-');
          final year = parts[0];
          final semester = parts[1];
          return SemesterTimetable(
            year: year,
            semester: semester,
            color:
                Colors.primaries[keys.indexOf(key) % Colors.primaries.length],
          );
        }).toList();
  }

  // [수정] 시간표 추가 버튼을 눌렀을 때 실행될 함수
  void _showAddTimetableDialog() async {
    final newTimetable = await showDialog<SemesterTimetable>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AddTimetableModal();
      },
    );

    // 반환된 값이 있으면 (null이 아니면) 리스트에 추가
    if (newTimetable != null) {
      final newKey = '${newTimetable.year}-${newTimetable.semester}';
      // 새로운 시간표를 allTimetableCourses 맵에 추가
      widget.allTimetableCourses[newKey] = [];
      setState(() {
        _loadTimetables();
        _selectedIndex = 0; // 새로 추가된 시간표가 선택되도록 인덱스 설정
      });
    }
  }

  // [추가] 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmationDialog(int index) async {
    final timetableToDelete = _timetables[index];
    final keyToDelete =
        '${timetableToDelete.year}-${timetableToDelete.semester}';

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('시간표 삭제'),
            content: Text(
              "'${timetableToDelete.year} ${timetableToDelete.semester}' 시간표를 삭제하시겠습니까?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (result == true) {
      setState(() {
        // allTimetableCourses 맵에서 항목 삭제
        widget.allTimetableCourses.remove(keyToDelete);
        _loadTimetables(); // 리스트 다시 불러오기

        // 삭제 후 선택된 항목이 없거나 인덱스가 범위를 벗어나면 조정
        if (_timetables.isEmpty) {
          _selectedIndex = -1; // 선택된 항목 없음
        } else if (_selectedIndex >= _timetables.length) {
          _selectedIndex = _timetables.length - 1; // 마지막 항목 선택
        }
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
          onPressed: () {
            final selectedKey =
                _selectedIndex != -1
                    ? '${_timetables[_selectedIndex].year}-${_timetables[_selectedIndex].semester}'
                    : null;
            Navigator.of(context).pop(selectedKey);
          },
        ),
        title: const Text(
          '시간표 목록',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            if (constraints.maxWidth > 1200) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // 아이템 비율
              ),
              itemCount: _timetables.length,
              itemBuilder: (context, index) {
                final timetable = _timetables[index];
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    // 한 번 탭하면 시간표로 이동하는 기능
                    final key = '${timetable.year}-${timetable.semester}';
                    Navigator.of(context).pop(key);
                  },
                  onLongPress: () {
                    // 길게 눌러서 삭제 알림창 띄우기
                    _showDeleteConfirmationDialog(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: timetable.color,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          isSelected
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
            );
          },
        ),
      ),
    );
  }
}

// ## 새로운 시간표를 추가하기 위한 모달 다이얼로그 위젯 ##
class AddTimetableModal extends StatefulWidget {
  const AddTimetableModal({super.key});

  @override
  State<AddTimetableModal> createState() => _AddTimetableModalState();
}

class _AddTimetableModalState extends State<AddTimetableModal> {
  final _yearController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedSemester;
  final List<Color> _colorOptions = const [
    Color(0xFFDDEBF1),
    Color(0xFFD4DAF5),
    Color(0xFFA9C5D8),
    Color(0xFFC7D7CB),
    Color(0xFFE3E8EE),
    Color(0xFFE9EBE0),
  ];
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
    _selectedColor = _colorOptions.first;
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _addTimetable() {
    if (_formKey.currentState!.validate()) {
      final newTimetable = SemesterTimetable(
        year: _yearController.text,
        semester: _selectedSemester!,
        color: _selectedColor,
      );
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '새 시간표 추가',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
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
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                items:
                    _semesterOptions.map((String semester) {
                      return DropdownMenuItem<String>(
                        value: semester,
                        child: Text(semester),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: '학기',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '학기를 선택하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
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
