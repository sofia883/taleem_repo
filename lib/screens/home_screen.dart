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

  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  bool _isServiceRunning = false;
  
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
    print("DEBUG: HomeScreen initState called");
    WidgetsBinding.instance.addObserver(this);
    _loadSelectedDurations();
    _initializeBackgroundService();
    _checkForActiveTimers();
  }

  @override
  void dispose() {
    print("DEBUG: HomeScreen dispose called");
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimer?.cancel();
    _sessionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeBackgroundService() async {
    print("DEBUG: Starting to initialize background service");
    await initializeService();
    
    // Initialize notifications
    print("DEBUG: Initializing local notifications");
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print("DEBUG: Local notifications initialized");
    
    // Listen for timer completion events
    print("DEBUG: Setting up timer completion listener");
    _backgroundService.on('timer_completed').listen((event) {
      print("DEBUG: Received timer_completed event: $event");
      if (event != null && event['sessionName'] != null) {
        print("DEBUG: Handling session progression for ${event['sessionName']}");
        _handleSessionProgression();
      }
    });
    print("DEBUG: Background service initialization complete");
  }
  
  // Check if there's an active timer when app resumes
  Future<void> _checkForActiveTimers() async {
    print("DEBUG: Checking for active timers");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isActive = prefs.getBool('timer_active') ?? false;
    bool isPaused = prefs.getBool('timer_paused') ?? false;
    
    print("DEBUG: Timer active: $isActive, paused: $isPaused");
    
    if (isActive) {
      _isServiceRunning = true;
      
      if (!isPaused) {
        String? endTimeString = prefs.getString('timer_end_time');
        String sessionName = prefs.getString('timer_session_name') ?? 'Session';
        
        print("DEBUG: Found active timer for $sessionName, end time: $endTimeString");
        
        if (endTimeString != null) {
          DateTime endTime = DateTime.parse(endTimeString);
          
          // Find the session index
          int index = sessions.indexWhere((s) => s.name == sessionName);
          print("DEBUG: Session index: $index");
          
          if (index != -1) {
            int secondsLeft = endTime.difference(DateTime.now()).inSeconds;
            print("DEBUG: Seconds left: $secondsLeft");
            
            setState(() {
              _isSessionActive = true;
              _currentSessionIndex = index;
              _sessionStatus = SessionStatus.running;
              _targetTime = endTime;
              _remainingSeconds = secondsLeft;
              
              if (_remainingSeconds <= 0) {
                // Timer already ended, just play the sound
                print("DEBUG: Timer already ended, playing completion sound");
                _playCompletionSound();
              } else {
                // Resume the timer
                print("DEBUG: Resuming timer with $secondsLeft seconds left");
                _startSession(syncToBackground: false);
              }
            });
          }
        }
      } else {
        // Handle paused timer
        int remainingSeconds = prefs.getInt('timer_remaining_seconds') ?? 0;
        String sessionName = prefs.getString('timer_session_name') ?? 'Session';
        
        print("DEBUG: Found paused timer for $sessionName with $remainingSeconds seconds left");
        
        if (remainingSeconds > 0) {
          int index = sessions.indexWhere((s) => s.name == sessionName);
          if (index != -1) {
            print("DEBUG: Setting UI to paused state");
            setState(() {
              _isSessionActive = true;
              _currentSessionIndex = index;
              _sessionStatus = SessionStatus.paused;
              _remainingSeconds = remainingSeconds;
            });
          }
        }
      }
    } else {
      print("DEBUG: No active timers found");
    }
  }

  Future<void> _loadSelectedDurations() async {
    print("DEBUG: Loading saved session durations");
    for (var session in sessions) {
      int? storedDuration =
          await storeService.loadSessionDuration(session.name);
      if (storedDuration != null) {
        print("DEBUG: Loaded duration for ${session.name}: $storedDuration minutes");
        setState(() {
          session.selectedDuration = storedDuration;
        });
      }
    }
  }

  void _startCountdown() {
    print("DEBUG: Starting countdown");
    setState(() {
      _sessionStatus = SessionStatus.countdown;
      _countdown = 3;
    });
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
        print("DEBUG: Countdown: $_countdown");
      } else {
        print("DEBUG: Countdown finished, starting session");
        timer.cancel();
        _startSession();
      }
    });
  }

  // Modified to start the background service
  void _startSession({bool syncToBackground = true}) async {
    print("DEBUG: Starting session ${sessions[_currentSessionIndex].name}");
    int duration = sessions[_currentSessionIndex].selectedDuration ??
        sessions[_currentSessionIndex].defaultDuration;
    
    print("DEBUG: Session duration: $duration minutes");
    
    // Calculate total seconds
    _remainingSeconds = duration * 60;
    
    // Set the target end time
    _targetTime = DateTime.now().add(Duration(minutes: duration));
    print("DEBUG: Target end time: $_targetTime");
    
    setState(() {
      _sessionStatus = SessionStatus.running;
    });
    
    if (syncToBackground) {
      print("DEBUG: Syncing with background service");
      // Get sound settings
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String selectedSound = prefs.getString('selected_sound') ?? 'sounds/soft_beep_1.wav';
      int soundDuration = prefs.getInt('sound_duration') ?? 2;
      
      print("DEBUG: Selected sound: $selectedSound, duration: $soundDuration seconds");
      
      // Start the background service if not running
      _isServiceRunning = await _backgroundService.isRunning();
      print("DEBUG: Is service running: $_isServiceRunning");
      
      if (!_isServiceRunning) {
        print("DEBUG: Starting background service");
        await _backgroundService.startService();
        _isServiceRunning = true;
      }
      
      // Start the timer in background service
      print("DEBUG: Sending start_timer event to background service");
      _backgroundService.invoke('start_timer', {
        'sessionName': sessions[_currentSessionIndex].name,
        'durationInSeconds': _remainingSeconds,
        'soundPath': selectedSound.replaceAll('assets/', ''),
        'soundDuration': soundDuration,
      });
    }
    
    // Still maintain a local timer for UI updates when app is in foreground
    print("DEBUG: Starting local UI timer");
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      int secondsLeft = _targetTime!.difference(DateTime.now()).inSeconds;
      if (secondsLeft > 0) {
        setState(() {
          _remainingSeconds = secondsLeft;
        });
        
        if (secondsLeft % 30 == 0) { // Log every 30 seconds to reduce spam
          print("DEBUG: UI timer update: $secondsLeft seconds left");
        }
      } else {
        timer.cancel();
        print("DEBUG: UI timer finished");
        setState(() {
          _remainingSeconds = 0;
        });
        
        // The background service should handle the sound, but if app is in
        // foreground, we can still play it here as a backup
        if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
          print("DEBUG: App in foreground, playing completion sound as backup");
          _playCompletionSound();
        }
      }
    });
  }
  
  // Modified to sync with background service
  void _pauseSession() async {
    if (_sessionStatus == SessionStatus.running) {
      print("DEBUG: Pausing session");
      _sessionTimer?.cancel();
      setState(() {
        _sessionStatus = SessionStatus.paused;
      });
      
      // Pause the background timer
      print("DEBUG: Sending pause_timer event to background service");
      _backgroundService.invoke('pause_timer');
    } else if (_sessionStatus == SessionStatus.paused) {
      print("DEBUG: Resuming session");
      setState(() {
        _sessionStatus = SessionStatus.running;
      });
      
      // Reset target time based on current remaining seconds
      _targetTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
      print("DEBUG: New target time: $_targetTime");
      
      // Resume the background timer
      print("DEBUG: Sending resume_timer event to background service");
      _backgroundService.invoke('resume_timer');
      
      // Local timer for UI updates
      print("DEBUG: Restarting local UI timer");
      _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        int secondsLeft = _targetTime!.difference(DateTime.now()).inSeconds;
        if (secondsLeft > 0) {
          setState(() {
            _remainingSeconds = secondsLeft;
          });
          
          if (secondsLeft % 30 == 0) { // Log every 30 seconds
            print("DEBUG: UI timer update: $secondsLeft seconds left");
          }
        } else {
          timer.cancel();
          print("DEBUG: UI timer finished");
          setState(() {
            _remainingSeconds = 0;
          });
          
          // The background service should handle sound
          if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
            print("DEBUG: App in foreground, playing completion sound as backup");
            _playCompletionSound();
          }
        }
      });
    }
  }
  
  void _playCompletionSound() async {
    print("DEBUG: Playing completion sound");
    try {
      // Get stored preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String selectedSound =
          prefs.getString('selected_sound') ?? 'assets/sounds/soft_beep_1.wav';
      int soundDuration = prefs.getInt('sound_duration') ?? 2;
      
      print("DEBUG: Selected sound: $selectedSound, duration: $soundDuration seconds");

      // Create a new audio player instance for this playback
      AudioPlayer player = AudioPlayer();
      _currentPlayer = player;

      // Change release mode to stop so the sound doesn't loop indefinitely
      await player.setReleaseMode(ReleaseMode.stop);
      
      // Start playing the sound - remove 'assets/' from the path since AssetSource adds it
      String soundPath = selectedSound.replaceAll('assets/', '');
      print("DEBUG: Playing sound from path: $soundPath");
      await player.play(AssetSource(soundPath));
      print("DEBUG: Sound playback started");

      // Schedule sound stop after duration
      print("DEBUG: Scheduling sound stop after $soundDuration seconds");
      Timer(Duration(seconds: soundDuration), () async {
        print("DEBUG: Stopping sound playback");
        await player.stop();
        await player.dispose();
        print("DEBUG: Sound player disposed");

        // Continue with session progression
        print("DEBUG: Handling session progression");
        _handleSessionProgression();
      });
    } catch (e) {
      print("DEBUG: Error playing completion sound: $e");
      // Even if sound fails, continue with session
      _handleSessionProgression();
    }
  }

  void _handleSessionProgression() {
    print("DEBUG: Handling session progression");
    _blinkingTimer?.cancel();
    setState(() {
      _isBlinking = false;
      _showBlink = false;
    });

    if (_currentSessionIndex < sessions.length - 1) {
      print("DEBUG: Moving to next session");
      setState(() {
        _currentSessionIndex++;
      });
      print("DEBUG: New session: ${sessions[_currentSessionIndex].name}");
      _startCountdown();
    } else {
      print("DEBUG: All sessions completed");
      setState(() {
        _sessionStatus = SessionStatus.ended;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("DEBUG: App lifecycle state changed to: $state");

    if (state == AppLifecycleState.resumed) {
      print("DEBUG: App resumed, checking active timers");
      _checkForActiveTimers();
    }
  }

  void _stopSession() async {
    print("DEBUG: Stopping session");
    _sessionTimer?.cancel();
    _blinkTimer?.cancel();
    
    if (_currentPlayer != null) {
      print("DEBUG: Stopping current sound player");
      await _currentPlayer?.stop();
      await _currentPlayer?.dispose();
    }

    // Stop the background service timer
    print("DEBUG: Sending stop_timer event to background service");
    _backgroundService.invoke('stop_timer');
    
    setState(() {
      _sessionStatus = SessionStatus.ended;
      _isBlinking = false;
      _isSessionActive = false;
      _currentSessionIndex = 0;
    });
    print("DEBUG: Session stopped");
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
