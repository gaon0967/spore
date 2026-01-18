import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'course_model.dart';
import '../Settings/TitleHandler.dart';
import '../Settings/firebase_title.dart';

class ClassAdd extends StatefulWidget {
  final Course? course;

  const ClassAdd({super.key, this.course});
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
  String _selectedDay = '월';
  late Color _selectedColor;

  final List<String> _days = ['월', '화', '수', '목', '금'];
  final List<Color> _colors = const [
    Color(0xFFCDDEE3),
    Color(0xFF8E9CBF),
    Color(0xFF97B4C7),
    Color(0xFFBBCDC0),
    Color(0xFFE5EAEF),
    Color(0xFFE8EBDF),
  ];

  @override
  void initState() {
    super.initState();
    // 데이터 유무에 따라 초기값 설정 (수정 모드 vs 추가 모드)
    if (widget.course != null) {
      _courseNameController.text = widget.course!.title;
      _professorController.text = widget.course!.professor;
      _locationController.text = widget.course!.room;
      _selectedDay = _days[widget.course!.day];
      _selectedColor = widget.course!.color;

      // double(9.5) -> TimeOfDay(9, 30) 변환
      int sHour = widget.course!.startTime.toInt();
      int sMin = ((widget.course!.startTime - sHour) * 60).round();
      _startTime = TimeOfDay(hour: sHour, minute: sMin);

      int eHour = widget.course!.endTime.toInt();
      int eMin = ((widget.course!.endTime - eHour) * 60).round();
      _endTime = TimeOfDay(hour: eHour, minute: eMin);
    } else {
      _selectedColor = _colors.first;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 13, minute: 0);
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _professorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<TimeOfDay?> _showCupertino5MinutePicker(
    BuildContext context,
    TimeOfDay initial,
  ) async {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double w = screenWidth * 0.00243;
    final double h = screenHeight * 0.001134;

    final pickerHeight = 200.0*h;

    DateTime picked = DateTime(2024, 1, 1, initial.hour, initial.minute);

    return await showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (_) {
        // CupertinoTheme를 사용하여 피커의 색상을 직접 설정합니다.
        return CupertinoTheme(
          data: CupertinoThemeData(
            primaryColor: Color(
              0xFF504A4A,
            ), // '확인' 버튼 및 선택바 강조 색상 (원하는 색상으로 변경)
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                fontFamily: 'Golos Text',
                fontSize: 18*w,
                color: Color(0xFF675F5F), // 피커 내부 숫자/글자 색상
              ),
            ),
          ),
          child: Container(
            height: pickerHeight,
            color: const Color(0xFFFFFFF9), // 배경색을 모달과 동일하게 맞춤
            child: Column(
              children: [
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    minuteInterval: 5,
                    use24hFormat: false,
                    initialDateTime: picked,
                    onDateTimeChanged: (dt) {
                      picked = dt;
                    },
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontFamily: 'Golos Text',
                      fontSize: 15*w,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      TimeOfDay(hour: picked.hour, minute: picked.minute),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double h = screenHeight * 0.001134;
    final double w = screenWidth * 0.00243;

    final double scale = screenWidth / 430;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 40*w),
      child: Container(
        width: 292 * w,
        height: 365 * h,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFF9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(1, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20 * w,
                  25 * h,
                  20 * h,
                  15 * h,
                ),
                child: Column(
                  children: [
                    _buildTextField(_courseNameController, '수업명', w,h),
                    SizedBox(height: 6 * h),
                    _buildTextField(_professorController, '교수', w,h,),
                    SizedBox(height: 6 * h),
                    _buildTextField(_locationController, '장소', w,h,),
                    SizedBox(height: 10 * h),
                    _buildDayPicker(h,w),
                    SizedBox(height: 10 * h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 155 * w,
                          height: 94 * h,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * w,
                            vertical: 6 * h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5EF),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTimeRow("시작 시간", _startTime!, true,h,w),
                              Container(
                                height: 0.8*h,
                                color: const Color(0xFFADADAD),
                              ),
                              _buildTimeRow("종료 시간", _endTime!, false,h,w),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 75 * w,
                          child: Wrap(
                            spacing: 10 * w,
                            runSpacing: 10 * h,
                            children:
                                _colors
                                    .map(
                                      (color) =>
                                          _buildColorCircle(color, w),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 완료/추가 버튼
            Positioned(
              right: 12 * w,
              bottom: 12 * h,
              child: GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    final dayIndex = _days.indexOf(_selectedDay);
                    final updatedCourse = Course(
                      title: _courseNameController.text.trim(),
                      professor: _professorController.text.trim(),
                      room: _locationController.text.trim(),
                      day: dayIndex,
                      startTime: _startTime!.hour + (_startTime!.minute / 60),
                      endTime: _endTime!.hour + (_endTime!.minute / 60),
                      color: _selectedColor,
                    );
                    Navigator.of(context).pop(updatedCourse);
                  }
                },
                child: Container(
                  width: 65 * w,
                  height: 38 * h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF504A4A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.course != null ? "완료" : "추가 +", // 수정 모드면 "완료"
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Golos Text',
                      fontSize: 13 * w,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    double w,
    double h,
  ) {
    return Container(
      height: 42 * w,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5EF),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10 * w),
      alignment: Alignment.centerLeft,
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontFamily: 'Golos Text',
          fontSize: 14 * w, 
          fontWeight: FontWeight.w600,
          color: const Color(0xFF675F5F),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13 * w),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: (v) => v!.trim().isEmpty ? '' : null,
      ),
    );
  }

  Widget _buildDayPicker(double h, double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          _days.map((day) {
            bool isSelected = _selectedDay == day;
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                width: 42 * w, // 폭 축소
                height: 30 * h, // 높이 축소
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFF8E9CBF)
                          : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF675F5F),
                    fontWeight: FontWeight.bold,
                    fontSize: 13 * w,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTimeRow(
    String label,
    TimeOfDay time,
    bool isStart,
    double h,
    double w,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await _showCupertino5MinutePicker(context, time);
        if (picked != null)
          setState(() => isStart ? _startTime = picked : _endTime = picked);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Golos Text',
              fontSize: 13 * w,
              color: const Color(0xFF504A4A),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time.format(context),
            style: TextStyle(
              fontFamily: 'Golos Text',
              fontSize: 13 * w,
              color: const Color(0xFF675F5F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color, double w) {
    bool isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 24 * w,
        height: 24 * w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border:
              isSelected
                  ? Border.all(color: const Color(0xFF675F5F), width: 1.5)
                  : null,
        ),
      ),
    );
  }
}
