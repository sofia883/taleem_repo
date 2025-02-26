import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:taleem_app/common_imports.dart'; // Assuming this includes necessary imports.
import 'package:flutter_background_service/flutter_background_service.dart';

enum SessionStatus { notStarted, countdown, running, paused, ended }

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Session> sessions = [
    Session(name: 'Halqa', defaultDuration: 10),
    Session(name: 'Taleem', defaultDuration: 20),
    Session(name: '6 Sifat', defaultDuration: 5),
    Session(name: 'Mashwarah', defaultDuration: 5),
    Session(name: 'Tashkeel', defaultDuration: 10),
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  final StoreService storeService = StoreService();

  bool _isBlinking = false;
  bool _showBlink = false;
  Timer? _blinkingTimer;

  bool _isSessionActive = false;
  Timer? _blinkTimer;
  AudioPlayer? _currentPlayer;
  int _soundDuration = 2;

  SessionStatus _sessionStatus = SessionStatus.notStarted;
  int _currentSessionIndex = 0;
  int _remainingSeconds = 0;
  Timer? _sessionTimer;
  Timer? _countdownTimer;
  int _countdown = 3;

  // New variable: a target end time for the running session.
  DateTime? _targetTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSelectedDurations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimer?.cancel();
    _sessionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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

  // Modified _startSession: sets a target end time and uses it to update the remaining seconds.
  void _startSession() async {
    int duration = sessions[_currentSessionIndex].selectedDuration ??
        sessions[_currentSessionIndex].defaultDuration;
    // Calculate total seconds.
    _remainingSeconds = duration * 60;

    // Set the target end time.
    _targetTime = DateTime.now().add(Duration(minutes: duration));

    setState(() {
      _sessionStatus = SessionStatus.running;
    });

    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      int secondsLeft = _targetTime!.difference(DateTime.now()).inSeconds;
      if (secondsLeft > 0) {
        setState(() {
          _remainingSeconds = secondsLeft;
        });
      } else {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        _playCompletionSound();
      }
    });
  }

  // Modified pause/resume logic: if resuming, reset target time using the remaining seconds.
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
      // Reset target time based on current remaining seconds.
      _targetTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
      _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        int secondsLeft = _targetTime!.difference(DateTime.now()).inSeconds;
        if (secondsLeft > 0) {
          setState(() {
            _remainingSeconds = secondsLeft;
          });
        } else {
          timer.cancel();
          setState(() {
            _remainingSeconds = 0;
          });
          _playCompletionSound();
        }
      });
    }
  }

  void _playCompletionSound() async {
    try {
      // Get stored preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String selectedSound =
          prefs.getString('selected_sound') ?? 'assets/sounds/soft_beep_1.wav';
      int soundDuration = prefs.getInt('sound_duration') ?? 2;

      // Create a new audio player instance for this playback
      AudioPlayer player = AudioPlayer();

      // Change release mode to stop so the sound doesn't loop indefinitely
      await player.setReleaseMode(ReleaseMode.stop);

      // Start playing the sound - remove 'assets/' from the path since AssetSource adds it
      String soundPath = selectedSound.replaceAll('assets/', '');
      await player.play(AssetSource(soundPath));

      // Schedule sound stop after duration
      Timer(Duration(seconds: soundDuration), () async {
        await player.stop();
        await player.dispose();

        // Continue with session progression
        _handleSessionProgression();
      });
    } catch (e) {
      print('Error playing completion sound: $e');
      // Even if sound fails, continue with session
      _handleSessionProgression();
    }
  }

  void _handleSessionProgression() {
    _blinkingTimer?.cancel();
    setState(() {
      _isBlinking = false;
      _showBlink = false;
    });

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed &&
        _targetTime != null &&
        _sessionStatus == SessionStatus.running) {
      // Update remaining time when app resumes
      int secondsLeft = _targetTime!.difference(DateTime.now()).inSeconds;

      if (secondsLeft <= 0) {
        // If time expired while in background, play sound immediately
        _playCompletionSound();
      } else {
        setState(() {
          _remainingSeconds = secondsLeft;
        });
      }
    }
  }

  void _stopSession() async {
    _sessionTimer?.cancel();
    _blinkTimer?.cancel();
    await _currentPlayer?.stop();
    await _currentPlayer?.dispose();

    setState(() {
      _sessionStatus = SessionStatus.ended;
      _isBlinking = false;
      _isSessionActive = false;
      _currentSessionIndex = 0;
    });
  }

  Widget _buildGridItem(Session session, int index) {
    bool isActive = _isSessionActive &&
        (index == _currentSessionIndex) &&
        (_sessionStatus == SessionStatus.running ||
            _sessionStatus == SessionStatus.paused);
    // When displaying duration on grid, assume it's in minutes.
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
    int totalMinutes = session.selectedDuration ?? session.defaultDuration;
    TimeOfDay? selectedTime = await showCustomTimePicker(
      context: context,
      sessionName: session.name,
      initialTime: TimeOfDay(
        hour: totalMinutes ~/ 60,
        minute: totalMinutes % 60,
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

  // Assumes that formatDuration receives seconds. Adjust if necessary.
  String formatDuration(int seconds) {
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
            Text(
              _isBlinking
                  ? (_showBlink ? "00:00" : "")
                  : formatDuration(_remainingSeconds),
              style: TextStyle(fontSize: 36, color: Colors.white),
            ),
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

  Widget buildSessionView() {
    return Column(
      children: [
        _buildSessionGrid(),
        Divider(thickness: 3),
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
        ElevatedButton(
          onPressed: () async {
            AudioPlayer testPlayer = AudioPlayer();
            await testPlayer.setReleaseMode(ReleaseMode.stop);
            await testPlayer.play(AssetSource('sounds/soft_beep_1.wav'));
          },
          child: Text('Test Sound'),
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
