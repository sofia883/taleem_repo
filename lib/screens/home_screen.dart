import 'package:taleem_app/common_imports.dart';

enum SessionStatus { notStarted, countdown, running, paused, ended }

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Session> sessions = [
    Session(name: 'Halqa', defaultDuration: 10),
    Session(name: 'Taleem', defaultDuration: 20),
    Session(name: '6 Sifat', defaultDuration: 5),
    Session(name: 'Mashwarah', defaultDuration: 5),
    Session(name: 'Tashkeel', defaultDuration: 10),
  ];
  final StoreService storeService = StoreService();

  bool _isSessionActive = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  int _soundDuration =
      2; // Default to 2 seconds, but will be updated from SharedPreferences
  // Timer variables
  SessionStatus _sessionStatus = SessionStatus.notStarted;
  int _currentSessionIndex = 0;
  int _remainingSeconds = 0;
  Timer? _sessionTimer;
  Timer? _countdownTimer;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _loadSelectedDurations();
  }

  Future<void> _loadSelectedDurations() async {
    for (var session in sessions) {
      int? storedDuration =
          await storeService.loadSessionDuration(session.name);
      if (storedDuration != null) {
        setState(() {
          session.selectedDuration = storedDuration;
        });
      }
    }
  }

  void _startCountdown() {
    setState(() {
      _sessionStatus = SessionStatus.countdown;
      _countdown = 3;
    });
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _startSession();
      }
    });
  }

  void _startSession() async {
    int duration = sessions[_currentSessionIndex].selectedDuration ??
        sessions[_currentSessionIndex].defaultDuration;
    _remainingSeconds = duration * 60;

    setState(() {
      _sessionStatus = SessionStatus.running;
    });

    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _playCompletionSound();
      }
    });
  }

  void _pauseSession() {
    if (_sessionStatus == SessionStatus.running) {
      _sessionTimer?.cancel();
      setState(() {
        _sessionStatus = SessionStatus.paused;
      });
    } else if (_sessionStatus == SessionStatus.paused) {
      setState(() {
        _sessionStatus = SessionStatus.running;
      });
      _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          _playCompletionSound();
        }
      });
    }
  }

  void _stopSession() async {
    _sessionTimer?.cancel();
    _audioPlayer.stop(); // Ensure the sound stops immediately
    setState(() {
      _sessionStatus = SessionStatus.ended;
      _isSessionActive = false;
      _currentSessionIndex = 0;
    });
  }

  void _playCompletionSound() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selectedSound = prefs.getString('selected_sound') ?? 'mp_01.mp3';
    _soundDuration =
        prefs.getInt('sound_duration') ?? 2; // Load updated duration

    await _audioPlayer.play(AssetSource('sounds/$selectedSound'));
    await Future.delayed(
        Duration(seconds: _soundDuration)); // Use updated duration
    _audioPlayer.stop(); // Stop sound after duration

    if (_currentSessionIndex < sessions.length - 1) {
      setState(() {
        _currentSessionIndex++;
      });
      _startCountdown();
    } else {
      setState(() {
        _sessionStatus = SessionStatus.ended;
      });
    }
  }

  // Helper to format total minutes into "X hr Y min" (or just "Y min").
  String formatDuration(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    if (hours > 0) {
      return "$hours hr ${minutes} min";
    } else {
      return "$minutes min";
    }
  }

  Widget _buildGridItem(Session session, int index) {
    bool isActive = _isSessionActive &&
        (index == _currentSessionIndex) &&
        (_sessionStatus == SessionStatus.running ||
            _sessionStatus == SessionStatus.paused);
    int currentMinutes = session.selectedDuration ?? session.defaultDuration;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(12),
          color: isActive ? Colors.green[300] : Colors.white,
        ),
        padding: EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            _showDurationSelector(context, session);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                session.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatDuration(currentMinutes),
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionGrid() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: List.generate(
          sessions.length,
          (index) => _buildGridItem(sessions[index], index),
        ),
      ),
    );
  }

  void _showDurationSelector(BuildContext context, Session session) async {
    int totalMinutes = session.selectedDuration ??
        session.defaultDuration; // Use default if null

    TimeOfDay? selectedTime = await showCustomTimePicker(
      context: context,
      sessionName: session.name,
      initialTime: TimeOfDay(
        hour: totalMinutes ~/ 60, // Safe fallback
        minute: totalMinutes % 60, // Safe fallback
      ),
      accentColor: Colors.blue,
    );

    if (selectedTime != null) {
      int newTotalMinutes = selectedTime.hour * 60 + selectedTime.minute;
      setState(() {
        session.selectedDuration = newTotalMinutes;
        storeService.saveSessionDuration(session.name, newTotalMinutes);
      });
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerContent() {
    switch (_sessionStatus) {
      case SessionStatus.notStarted:
        return Text("Ready",
            style: TextStyle(fontSize: 24, color: Colors.white));
      case SessionStatus.countdown:
        return Text("$_countdown",
            style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white));
      case SessionStatus.running:
      case SessionStatus.paused:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sessions[_currentSessionIndex].name,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(_formatTime(_remainingSeconds),
                style: TextStyle(fontSize: 36, color: Colors.white)),
          ],
        );
      case SessionStatus.ended:
        return Text("Session Ended",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white));
      default:
        return Container();
    }
  }

  // Home view shows the grid and start button.
  Widget buildHomeView() {
    return Column(
      children: [
        _buildSessionGrid(),
        Divider(),
        SizedBox(height: 200),
        SessionCircleContainer(
          onTap: () {
            if (!_isSessionActive) {
              setState(() {
                _isSessionActive = true;
                _sessionStatus = SessionStatus.notStarted;
              });
              _startCountdown();
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 50, color: Colors.white),
              SizedBox(height: 8),
              Text("Start Session",
                  style: TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  // Session view shows the active timer and control buttons.
  Widget buildSessionView() {
    return Column(
      children: [
        _buildSessionGrid(),
        Divider(
          thickness: 3,
        ),
        SizedBox(height: 200),
        if (_sessionStatus == SessionStatus.running ||
            _sessionStatus == SessionStatus.paused)
          SessionControlButtons(
            onStop: _stopSession,
            onPauseResume: _pauseSession,
            isRunning: _sessionStatus == SessionStatus.running,
          ),
        SessionCircleContainer(
          onTap: () {
            if (_sessionStatus == SessionStatus.notStarted) {
              _startCountdown();
            }
          },
          child: _buildTimerContent(),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Talim Time Selector"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _isSessionActive ? buildSessionView() : buildHomeView(),
      ),
    );
  }
}
