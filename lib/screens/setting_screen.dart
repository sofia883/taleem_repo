import 'package:taleem_app/common_imports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSoundDuration = 2;

  // Default to the first file in your list, or any other of your choosing.
  String _selectedSound = "soft_beep_01.wav";

  // Here are 15 sample .wav files.
  final List<String> _soundOptions = [
    "soft_beep_01.wav",
    "soft_beep_02.wav",
    "soft_beep_03.wav",
    "soft_beep_04.wav",
    "soft_beep_05.wav",
    "soft_beep_06.wav",
    "soft_beep_07.wav",
    "soft_beep_08.wav",
    "soft_beep_09.wav",
    "soft_beep_10.wav",
    "soft_beep_11.wav",
    "soft_beep_12.wav",
    "soft_beep_13.wav",
    "soft_beep_14.wav",
    "soft_beep_15.wav",
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

  /// Loads the user’s previously saved sound filename.
  Future<void> _loadSelectedSound() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSound = prefs.getString('selected_sound') ?? "soft_beep_01.wav";
    });
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
                // Create a friendlier label by removing the extension
                final label = soundFile.substring(0, soundFile.lastIndexOf('.'));
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
