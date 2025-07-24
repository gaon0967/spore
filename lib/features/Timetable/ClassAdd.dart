import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../Timetable/TimetableScreen.dart'; // 프로젝트에 맞게 경로 확인

/// 수업 추가 모달 위젯
class AddCourseModal extends StatefulWidget {
  const AddCourseModal({super.key});

  @override
  State<AddCourseModal> createState() => _AddCourseModalState();
}

class _AddCourseModalState extends State<AddCourseModal> {
  // 텍스트 입력 컨트롤러
  final _courseNameController = TextEditingController();
  final _professorController = TextEditingController();
  final _locationController = TextEditingController();

  // TimeOfDay 상태 변수
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

    // 초기 시간을 30분 단위로 설정
    final now = DateTime.now();
    final roundedMinute = (now.minute ~/ 30) * 30;
    final initialTime = TimeOfDay(hour: now.hour, minute: roundedMinute);

    _startTime = initialTime;

    // 시작 시간에서 30분 뒤로 종료 시간 설정
    final initialDateTime = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
    final endDateTime = initialDateTime.add(const Duration(minutes: 30));
    _endTime = TimeOfDay.fromDateTime(endDateTime);
  }


  @override
  void dispose() {
    _courseNameController.dispose();
    _professorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Cupertino 시간 피커를 띄우는 함수
  Future<void> _pickTime(BuildContext context, {required bool isStartTime}) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    DateTime tempPickedTime = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day,
      initialTime?.hour ?? TimeOfDay.now().hour,
      initialTime?.minute ?? TimeOfDay.now().minute,
    );

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.3,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('완료'),
                    onPressed: () {
                      setState(() {
                        final newTime = TimeOfDay.fromDateTime(tempPickedTime);
                        if (isStartTime) {
                          _startTime = newTime;
                        } else {
                          _endTime = newTime;
                        }
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  // [개선] 오전/오후 선택을 위해 12시간제 사용
                  use24hFormat: false,
                  minuteInterval: 30,
                  initialDateTime: tempPickedTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempPickedTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 유효성 검사 및 제출 함수
  void _validateAndSubmit() {
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
      title: _courseNameController.text,
      professor: _professorController.text,
      room: _locationController.text,
      day: _days.indexOf(_selectedDay),
      startTime: _startTime!,
      endTime: _endTime!,
      color: _selectedColor,
    );

    Navigator.of(context).pop(newCourse);
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTimePickerRow('시작 시간', true),
                    const Divider(height: 1, color: Colors.black12),
                    _buildTimePickerRow('종료 시간', false),
                  ],
                ),
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
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: _colors.length,
                  itemBuilder: (context, index) => _buildColorCircle(_colors[index]),
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
    );
  }

  // [개선] 시간 표시를 '오전/오후' 형식으로 변경
  Widget _buildTimePickerRow(String label, bool isStartTime) {
    final time = isStartTime ? _startTime : _endTime;
    String formattedTime = '선택';

    if (time != null) {
      // MaterialLocalizations를 사용하여 디바이스 설정에 맞는 오전/오후 형식으로 변환
      formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(time, alwaysUse24HourFormat: false);
    }

    return InkWell(
      onTap: () => _pickTime(context, isStartTime: isStartTime),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const Spacer(),
            Text(
              formattedTime,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.black54),
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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    bool isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
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