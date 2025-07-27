import 'package:flutter/cupertino.dart'; // Cupertino 위젯을 위해 추가
import 'package:flutter/material.dart';
import 'TimetableScreen.dart';

// 수업 추가 모달 위젯
class ClassAdd extends StatefulWidget {
  const ClassAdd({super.key});

  @override
  State<ClassAdd> createState() => _ClassAddState();
}

class _ClassAddState extends State<ClassAdd> {
  // 텍스트 입력 컨트롤러
  final _courseNameController = TextEditingController();
  final _professorController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 시간 상태 변수
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // 시간 유효성 검사 에러 메시지
  String? _timeErrorText;

  // 요일 선택 상태 관리
  final List<String> _days = ['월', '화', '수', '목', '금'];
  String _selectedDay = '월';

  // 색상 선택 상태 관리
  final List<Color> _colors = const [
    Color(0xFFCDDEE3), Color(0xFF8E9CBF), Color(0xFF97B4C7),
    Color(0xFFBBCDC0), Color(0xFFE5EAEF), Color(0xFFE8EBDF),
  ];
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors.first;

    // 초기 시간 설정
    final now = DateTime.now();
    // 현재 시간에서 가장 가까운 30분 단위 시간으로 초기화
    final initialMinute = (now.minute / 30).round() * 30;
    final initialHour = now.hour + (initialMinute >= 60 ? 1 : 0);
    _startTime = TimeOfDay(hour: initialHour % 24, minute: initialMinute % 60);

    final startDateTime = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
    final endDateTime = startDateTime.add(const Duration(hours: 1));
    _endTime = TimeOfDay.fromDateTime(endDateTime);
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _professorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // 유효성 검사 및 제출 함수
  void _validateAndSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startTime == null || _endTime == null) {
      setState(() => _timeErrorText = '시간을 선택해주세요.');
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      setState(() => _timeErrorText = '종료 시간은 시작 시간보다 늦어야 합니다.');
      return;
    }

    setState(() => _timeErrorText = null);

    final newCourse = Course(
      title: _courseNameController.text.trim(),
      professor: _professorController.text.trim(),
      room: _locationController.text.trim(),
      day: _days.indexOf(_selectedDay),
      startTime: _startTime!,
      endTime: _endTime!,
      color: _selectedColor,
    );

    Navigator.of(context).pop(newCourse);
  }

  /// [새로운 기능] 휠 스타일의 시간 선택기를 표시하는 함수
  Future<void> _showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) async {
    final now = DateTime.now();
    DateTime tempPickedDate = DateTime(now.year, now.month, now.day, initialTime.hour, initialTime.minute);

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              // '완료' 버튼을 포함한 헤더
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      child: const Text('완료'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempPickedDate,
                  minuteInterval: 30, // 30분 단위로 설정
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempPickedDate = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    // 모달이 닫히면 최종 선택된 시간으로 상태 업데이트
    onTimeChanged(TimeOfDay.fromDateTime(tempPickedDate));
  }


  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.of(context).size.width * 0.06;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: Colors.white,
      elevation: 0,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(controller: _courseNameController, hintText: '수업명'),
                const SizedBox(height: 12),
                _buildTextField(controller: _professorController, hintText: '교수'),
                const SizedBox(height: 12),
                _buildTextField(controller: _locationController, hintText: '장소'),
                const SizedBox(height: 20),
                _buildDayPicker(),
                const SizedBox(height: 20),
                
                // [수정] 시작 시간 선택 UI 변경
                _buildTimePickerRow(
                  label: '시작 시간',
                  time: _startTime,
                  onTap: () {
                    _showTimePicker(
                      context: context,
                      initialTime: _startTime ?? TimeOfDay.now(),
                      onTimeChanged: (newTime) {
                        setState(() {
                          _startTime = newTime;
                          final startDateTime = DateTime(2025, 1, 1, newTime.hour, newTime.minute);
                          final endDateTime = startDateTime.add(const Duration(hours: 1));
                          _endTime = TimeOfDay.fromDateTime(endDateTime);
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // [수정] 종료 시간 선택 UI 변경
                _buildTimePickerRow(
                  label: '종료 시간',
                  time: _endTime,
                  onTap: () {
                    _showTimePicker(
                      context: context,
                      initialTime: _endTime ?? TimeOfDay.now(),
                      onTimeChanged: (newTime) {
                        setState(() => _endTime = newTime);
                      },
                    );
                  },
                ),

                if (_timeErrorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _timeErrorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) => _buildColorCircle(_colors[index]),
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _validateAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4A4A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '추가 +',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [새로운 위젯] 시간 레이블과 선택된 시간을 표시하는 행
  Widget _buildTimePickerRow({required String label, TimeOfDay? time, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            Text(
              time != null
                  ? MaterialLocalizations.of(context).formatTimeOfDay(time, alwaysUse24HourFormat: false)
                  : '시간 선택',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker() {
    return Row(
      children: _days.asMap().entries.map((entry) {
        final int index = entry.key;
        final String day = entry.value;
        final isSelected = _selectedDay == day;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: EdgeInsets.only(left: index == 0 ? 0 : 4, right: index == _days.length - 1 ? 0 : 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$hintText 항목을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildColorCircle(Color color) {
    bool isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.blueAccent, width: 3) : null,
        ),
      ),
    );
  }
}

// Course 클래스 예시 (프로젝트의 실제 정의와 일치해야 합니다)
class Course {
  final String title;
  final String professor;
  final String room;
  final int day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;

  Course({
    required this.title,
    required this.professor,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.color,
  });
}