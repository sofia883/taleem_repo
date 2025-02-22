import 'package:taleem_app/common_imports.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSoundDuration = 2;

  @override
  void initState() {
    super.initState();
    _loadSoundDuration();
  }

  Future<void> _loadSoundDuration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSoundDuration = prefs.getInt('sound_duration') ?? 2;
    });
  }

  Future<void> _saveSoundDuration(int duration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sound_duration', duration);
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
            Text("Select Sound Duration (seconds):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            DropdownButton<int>(
              value: _selectedSoundDuration,
              items: [2, 3, 5, 10]
                  .map((value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text("$value seconds"),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSoundDuration = value;
                  });
                  _saveSoundDuration(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
