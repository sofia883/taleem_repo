import 'package:taleem_app/common_imports.dart';

class SessionControlButtons extends StatelessWidget {
  final VoidCallback onStop;
  final VoidCallback onPauseResume;
  final bool isRunning;

  const SessionControlButtons({
    Key? key,
    required this.onStop,
    required this.onPauseResume,
    required this.isRunning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: onStop,
            icon: Icon(Icons.stop, color: Colors.blue),
            label: Text("Stop"),
            style: ElevatedButton.styleFrom(iconColor: Colors.red),
          ),
          ElevatedButton.icon(
            onPressed: onPauseResume,
            icon: Icon(
              isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.blue,
            ),
            label: Text(isRunning ? "Pause" : "Resume"),
            style: ElevatedButton.styleFrom(iconColor: Colors.blue),
          ),
        ],
      ),
    );
  }
}
