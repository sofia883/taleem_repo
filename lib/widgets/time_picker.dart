import 'package:taleem_app/common_imports.dart';

class CustomTimePicker extends StatefulWidget {
  final String sessionName;
  final TimeOfDay initialTime;
  final Color accentColor;
  final Function(TimeOfDay) onTimeSelected;

  const CustomTimePicker({
    Key? key,
    required this.sessionName,
    required this.initialTime,
    required this.accentColor,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  // Helper: Format time as "X hr Y min" or "Y min" if less than an hour.
  String formatTimeOfDay(TimeOfDay time) {
    int totalMinutes = time.hour * 60 + time.minute;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    if (hours > 0) {
      return "$hours hr ${minutes} min";
    } else {
      return "$minutes min";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Session name and current selection at the top.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  widget.sessionName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Current: ${formatTimeOfDay(_selectedTime)}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: Duration(
                hours: _selectedTime.hour,
                minutes: _selectedTime.minute,
              ),
              onTimerDurationChanged: (Duration newDuration) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: newDuration.inHours,
                    minute: newDuration.inMinutes % 60,
                  );
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(iconColor: widget.accentColor),
              onPressed: () {
                widget.onTimeSelected(_selectedTime);
                Navigator.pop(context, _selectedTime);
              },
              child: Text("Select"),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the custom time picker.
/// Pass also the sessionName to display in the picker.
Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required String sessionName,
  required TimeOfDay initialTime,
  required Color accentColor,
}) async {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CustomTimePicker(
      sessionName: sessionName,
      initialTime: initialTime,
      accentColor: accentColor,
      onTimeSelected: (TimeOfDay time) {
        // Optionally log the selection.
        print('Selected time for $sessionName: ${time.format(context)}');
      },
    ),
  );
}
