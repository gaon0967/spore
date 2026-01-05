import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';     // ✔️ 반드시 import
import 'course_model.dart';
import '../Settings/TitleHandler.dart';
import '../Settings/firebase_title.dart';

class ClassAdd extends StatefulWidget {
  const ClassAdd({super.key});
  @override
  State<ClassAdd> createState() => _ClassAddState();
}

class _ClassAddState extends State<ClassAdd> {
  final _courseNameController = TextEditingController();
  final _professorController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _timeErrorText;

  final List<String> _days = ['월', '화', '수', '목', '금'];
  String _selectedDay = '월';

  final List<Color> _colors = const [
    Color(0xFFCDDEE3), Color(0xFF8E9CBF), Color(0xFF97B4C7),
    Color(0xFFBBCDC0), Color(0xFFE5EAEF), Color(0xFFE8EBDF),
  ];
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors.first;
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 11, minute: 0);
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _professorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// 30분 단위, 오전/오후, 9~18시 선택되는 커스텀 시간 피커 함수
  Future<TimeOfDay?> _showCupertino30MinutePicker(BuildContext context, TimeOfDay initial) async {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final pickerHeight = screenHeight * 0.35;

    DateTime picked = DateTime(2024, 1, 1, initial.hour, initial.minute - (initial.minute % 30));
    return await showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (_) {
        return SizedBox(
          height: pickerHeight,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 30,
                  use24hFormat: false,
                  initialDateTime: picked,
                  minimumDate: DateTime(2024, 1, 1, 9, 0),
                  maximumDate: DateTime(2024, 1, 1, 18, 0),
                  onDateTimeChanged: (dt) {
                    picked = dt;
                  },
                ),
              ),
              CupertinoButton(
                child: Text('확인', style: TextStyle(fontFamily: 'Golos Text', fontSize: screenWidth * 0.04)),
                onPressed: () {
                  Navigator.pop(
                    context,
                    TimeOfDay(hour: picked.hour, minute: picked.minute),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }

  void _validateAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
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

    final dayIndex = _days.indexOf(_selectedDay);
    final newCourse = Course(
      title: _courseNameController.text.trim(),
      professor: _professorController.text.trim(),
      room: _locationController.text.trim(),
      day: dayIndex,
      // 시 + (분 / 60) 로 변환 → double
      startTime: _startTime!.hour + (_startTime!.minute / 60),
      endTime: _endTime!.hour + (_endTime!.minute / 60),
      color: _selectedColor,
    );

    // 1. 총 시간표 개수 얻기
    final scheduleCount = await getTotalSchedule();

    // 2. 타이틀 지급 함수 호출 후 UI 갱신 콜백 전달
    final newTitles = await handleScheduleCountFirestore(
      scheduleCount,
      onUpdate: () {
        setState(() {
          // 필요에 따라 UI 상태 업데이트
        });
      },
    );

    // print('획득된 새 타이틀 개수: ${newTitles.length}');

    Navigator.of(context).pop(newCourse);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.028;
    final smallSpacing = screenHeight * 0.014;
    final mediumSpacing = screenHeight * 0.022;
    final buttonPadding = screenHeight * 0.016;
    final borderRadius = screenWidth * 0.03;
    final fontSize = screenWidth * 0.04;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
      backgroundColor: Colors.white,
      elevation: 0,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _courseNameController,
                  hintText: '수업명',
                  screenWidth: screenWidth,
                ),
                SizedBox(height: smallSpacing),
                _buildTextField(
                  controller: _professorController,
                  hintText: '교수',
                  screenWidth: screenWidth,
                ),
                SizedBox(height: smallSpacing),
                _buildTextField(
                  controller: _locationController,
                  hintText: '장소',
                  screenWidth: screenWidth,
                ),
                SizedBox(height: mediumSpacing),
                _buildDayPicker(screenWidth),
                SizedBox(height: mediumSpacing),
                _buildTimePickerRow(
                  label: '시작 시간',
                  time: _startTime,
                  screenWidth: screenWidth,
                  onTap: () async {
                    final picked = await _showCupertino30MinutePicker(
                      context,
                      _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
                SizedBox(height: smallSpacing),
                _buildTimePickerRow(
                  label: '종료 시간',
                  time: _endTime,
                  screenWidth: screenWidth,
                  onTap: () async {
                    final picked = await _showCupertino30MinutePicker(
                      context,
                      _endTime ?? const TimeOfDay(hour: 11, minute: 0),
                    );
                    if (picked != null) setState(() => _endTime = picked);
                  },
                ),
                if (_timeErrorText != null)
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.01),
                    child: Text(
                      _timeErrorText!,
                      style: TextStyle(fontFamily: 'Golos Text', color: Colors.red, fontSize: screenWidth * 0.03),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: mediumSpacing),
                _buildColorPickerRow(),
                SizedBox(height: mediumSpacing),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _validateAndSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4A4A),
                          padding: EdgeInsets.symmetric(vertical: buttonPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                        ),
                        child: Text(
                          '추가 +',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: EdgeInsets.symmetric(vertical: buttonPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          '닫기',
                          style: TextStyle(
                            fontFamily: 'Golos Text',
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerRow({
    required String label,
    TimeOfDay? time,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    final fontSize = screenWidth * 0.04;
    final padding = screenWidth * 0.04;
    final borderRadius = screenWidth * 0.03;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.9),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Golos Text', fontSize: fontSize, color: Colors.black54),
            ),
            Text(
              time != null
                  ? MaterialLocalizations.of(context)
                      .formatTimeOfDay(time, alwaysUse24HourFormat: false)
                  : '시간 선택',
              style: TextStyle(
                fontFamily: 'Golos Text',
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker(double screenWidth) {
    final fontSize = screenWidth * 0.038;
    final verticalPadding = screenWidth * 0.02;
    final margin = screenWidth * 0.01;
    final borderRadius = screenWidth * 0.02;

    return Row(
      children: _days.asMap().entries.map((entry) {
        final day = entry.value;
        final isSelected = _selectedDay == day;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: EdgeInsets.only(
                left: entry.key == 0 ? 0 : margin,
                right: entry.key == _days.length - 1 ? 0 : margin,
              ),
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[200],
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontFamily: 'Golos Text',
                    fontSize: fontSize,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required double screenWidth,
  }) {
    final fontSize = screenWidth * 0.04;
    final padding = screenWidth * 0.04;
    final borderRadius = screenWidth * 0.03;

    return TextFormField(
      controller: controller,
      style: TextStyle(fontFamily: 'Golos Text', fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontFamily: 'Golos Text', color: Colors.grey[400], fontSize: fontSize),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.9,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$hintText 항목을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildColorPickerRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = screenWidth * 0.08;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colors.map((color) {
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
                  ? Border.all(color: Colors.blueAccent, width: 3)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
