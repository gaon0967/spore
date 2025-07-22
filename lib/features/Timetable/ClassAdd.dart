import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Timetable/TimetableScreen.dart';

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
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  // 시간 유효성 검사 에러 메시지
  String? _timeErrorText;

  // --- [추가된 부분 1] ---
  // 요일 선택 상태 관리
  final List<String> _days = ['월', '화', '수', '목', '금'];
  String _selectedDay = '월'; // 기본 선택 요일
  // ----------------------

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
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 정리
    _courseNameController.dispose();
    _professorController.dispose();
    _locationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final startTime = _parseTime(_startTimeController.text);
    final endTime = _parseTime(_endTimeController.text);

    if (startTime == null || endTime == null) {
      setState(() {
        _timeErrorText = '시간을 HH:mm 형식으로 입력해주세요. (예: 14:30)';
      });
      return;
    }

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      setState(() {
        _timeErrorText = '종료 시간은 시작 시간보다 늦어야 합니다.';
      });
      return;
    }
    
    setState(() {
      _timeErrorText = null;
    });

    // --- [수정된 부분 2] ---
    // Course 객체 생성 시 선택된 요일의 인덱스를 전달합니다.
    final newCourse = Course(
      title: _courseNameController.text,
      professor: _professorController.text,
      room: _locationController.text,
      day: _days.indexOf(_selectedDay), // '월' -> 0, '화' -> 1 ...
      startTime: startTime.hour,
      endTime: endTime.hour,
      color: _selectedColor,
    );
    // -----------------------
    
    Navigator.of(context).pop(newCourse);
  }

  TimeOfDay? _parseTime(String text) {
    try {
      final parts = text.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: Colors.white,
      elevation: 0,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24.0),
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
              
              // --- [추가된 부분 3] ---
              // 요일 선택 UI 위젯 호출
              _buildDayPicker(),
              const SizedBox(height: 20),
              // ----------------------

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTimeInputRow('시작 시간', _startTimeController),
                    const SizedBox(height: 8),
                    _buildTimeInputRow('종료 시간', _endTimeController),
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

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
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

  // --- [추가된 부분 4] ---
  // 요일 선택 UI를 만드는 위젯 함수
  Widget _buildDayPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((day) {
        final isSelected = _selectedDay == day;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  // ----------------------

  Widget _buildTimeInputRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const Spacer(),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              hintText: '00:00',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
              LengthLimitingTextInputFormatter(5),
              _TimeTextInputFormatter(),
            ],
          ),
        ),
      ],
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

class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 2) {
      return newValue.copyWith(
        text: '${text.substring(0, 2)}:${text.substring(2)}',
        selection: TextSelection.fromPosition(
          TextPosition(offset: text.length + 1),
        ),
      );
    }
    return newValue;
  }
}