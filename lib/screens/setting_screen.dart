import 'package:taleem_app/common_imports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSoundDuration = 2;

  // Default to the first file in your list, or any other of your choosing.
  String _selectedSound = "assets/sounds/mp_01.mp3"; // Default sound

  Future<void> _loadSelectedSound() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Use the full path as default
      _selectedSound =
          prefs.getString('selected_sound') ?? "assets/sounds/mp_01.mp3";
    });
  }

  final List<String> _soundOptions = [
    "assets/sounds/mp_01.mp3",
    "assets/sounds/soft_beep_1.wav",
    "assets/sounds/soft_beep_2.wav",
    "assets/sounds/soft_beep_3.wav",
    "assets/sounds/soft_beep_4.wav",
    "assets/sounds/soft_beep_5.wav",
    "assets/sounds/soft_beep_6.wav",
    "assets/sounds/soft_beep_7.wav",
    "assets/sounds/soft_beep_8.wav",
    "assets/sounds/soft_beep_9.wav",
    "assets/sounds/soft_beep_10.wav",
    "assets/sounds/soft_beep_11.wav",
    "assets/sounds/soft_beep_12.wav",
    "assets/sounds/soft_beep_13.wav",
    "assets/sounds/soft_beep_14.wav",
    "assets/sounds/soft_beep_15.wav",
  ];
  @override
  void initState() {
    super.initState();
    _loadSoundDuration();
    _loadSelectedSound();
  }

  /// Loads the user’s previously saved sound duration (in seconds).
  Future<void> _loadSoundDuration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSoundDuration = prefs.getInt('sound_duration') ?? 2;
    });
  }

  /// Saves the user’s selected sound duration (in seconds).
  Future<void> _saveSoundDuration(int duration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sound_duration', duration);
  }

  /// Saves the user’s selected sound filename.
  Future<void> _saveSelectedSound(String sound) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_sound', sound);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SECTION: Sound Duration
            Text(
              "Select Sound Duration (seconds):",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<int>(
              value: _selectedSoundDuration,
              items: [2, 3, 5, 10]
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text("$value seconds"),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSoundDuration = value);
                  _saveSoundDuration(value);
                }
              },
            ),

            SizedBox(height: 30),

            /// SECTION: Sound File
            Text(
              "Select Sound:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedSound,
              items: _soundOptions.map((soundFile) {
                // Extract just the filename without path for display
                final label = soundFile.split('/').last.replaceAll('.wav', '');
                return DropdownMenuItem<String>(
                  value: soundFile,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSound = value);
                  _saveSelectedSound(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
