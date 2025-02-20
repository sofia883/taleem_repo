import 'package:taleem_app/common_imports.dart';
class TalimHomePage extends StatefulWidget {
  @override
  _TalimHomePageState createState() => _TalimHomePageState();
}

class _TalimHomePageState extends State<TalimHomePage> {
  // Default durations in minutes
  int halkaTime = 10;
  int talimTime = 20;
  int sifatTime = 5;
  int mashwaraTime = 5;
  int tashqeerTime = 10;

  late List<Session> sessions;
  int currentSessionIndex = 0;
  int remainingSeconds = 0;
  Timer? timer;
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeSessions();
  }

  void _initializeSessions() {
    sessions = [
      Session(name: 'Halka', duration: halkaTime),
      Session(name: 'Talim', duration: talimTime),
      Session(name: '6 Sifat', duration: sifatTime),
      Session(name: 'Mashwara', duration: mashwaraTime),
      Session(name: 'Tashqeer', duration: tashqeerTime),
    ];
    // Set initial remaining time based on the first session
    remainingSeconds = sessions[currentSessionIndex].duration * 60;
  }

  void _startTimer() {
    // Cancel any existing timer before starting a new one
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        // When time is up, play a beep sound
        _playBeep();
        t.cancel();
        _moveToNextSession();
      }
    });
  }

  void _stopTimer() {
    timer?.cancel();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      currentSessionIndex = 0;
      remainingSeconds = sessions[currentSessionIndex].duration * 60;
    });
  }

  void _moveToNextSession() {
    if (currentSessionIndex < sessions.length - 1) {
      setState(() {
        currentSessionIndex++;
        remainingSeconds = sessions[currentSessionIndex].duration * 60;
      });
      // Automatically start the next session
      _startTimer();
    } else {
      // All sessions complete
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Completed'),
          content: Text('All sessions are complete!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetTimer();
              },
              child: Text('OK'),
            )
          ],
        ),
      );
    }
  }

  Future<void> _playBeep() async {
    // Ensure you have placed your beep.mp3 in assets/ and declared it in pubspec.yaml
    await audioPlayer.play(AssetSource('assets/beep.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    // Format minutes and seconds for display
    String minutesStr = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    String secondsStr = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text('Talim Timer'),
        actions: [
          // Navigate to a settings page to set durations for each session
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    halkaTime: halkaTime,
                    talimTime: talimTime,
                    sifatTime: sifatTime,
                    mashwaraTime: mashwaraTime,
                    tashqeerTime: tashqeerTime,
                    onSave: (newHalka, newTalim, newSifat, newMashwara, newTashqeer) {
                      setState(() {
                        halkaTime = newHalka;
                        talimTime = newTalim;
                        sifatTime = newSifat;
                        mashwaraTime = newMashwara;
                        tashqeerTime = newTashqeer;
                        _initializeSessions();
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            // Tapping the circular container will start (or pause) the timer
            if (timer == null || !timer!.isActive) {
              _startTimer();
            } else {
              _stopTimer();
            }
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sessions[currentSessionIndex].name,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$minutesStr:$secondsStr',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // A floating action button to reset the timer
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.stop),
        onPressed: _resetTimer,
      ),
    );
  }
}