import 'package:taleem_app/common_imports.dart';

// Define session statuses.
enum SessionStatus { notStarted, countdown, running, paused, ended }

class SessionScreen extends StatefulWidget {
  final List<Session> sessions;
  const SessionScreen({Key? key, required this.sessions}) : super(key: key);

  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  SessionStatus _sessionStatus = SessionStatus.notStarted;
  int _currentSessionIndex = 0;
  int _remainingSeconds = 0;
  Timer? _sessionTimer;
  Timer? _countdownTimer;
  int _countdown = 3; // For the 3-2-1 countdown

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
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

  void _startSession() {
    int duration = widget.sessions[_currentSessionIndex].selectedDuration ??
        widget.sessions[_currentSessionIndex].defaultDuration;
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
        if (_currentSessionIndex < widget.sessions.length - 1) {
          setState(() {
            _currentSessionIndex++;
          });
          _startSession();
        } else {
          setState(() {
            _sessionStatus = SessionStatus.ended;
          });
        }
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
          if (_currentSessionIndex < widget.sessions.length - 1) {
            setState(() {
              _currentSessionIndex++;
            });
            _startSession();
          } else {
            setState(() {
              _sessionStatus = SessionStatus.ended;
            });
          }
        }
      });
    }
  }

  void _stopSession() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Stop"),
          content: Text("Are you sure you want to end this session?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("End Session"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _sessionTimer?.cancel();
      setState(() {
        _sessionStatus = SessionStatus.ended;
      });
      // Additional cleanup if needed.
    }
  }

  // Format seconds as MM:SS.
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Build the content displayed inside the circular container.
  Widget _buildCenterContent() {
    switch (_sessionStatus) {
      case SessionStatus.notStarted:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 50, color: Colors.green),
            SizedBox(height: 8),
            Text("Start", style: TextStyle(fontSize: 20, color: Colors.white)),
          ],
        );
      case SessionStatus.countdown:
        return Text(
          "$_countdown",
          style: TextStyle(
              fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
        );
      case SessionStatus.running:
      case SessionStatus.paused:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.sessions[_currentSessionIndex].name,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              _formatTime(_remainingSeconds),
              style: TextStyle(fontSize: 36, color: Colors.white),
            ),
          ],
        );
      case SessionStatus.ended:
        return Text(
          "Session Ended",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        );
      default:
        return Container();
    }
  }

  // Build a horizontal list to show sessions with the active one highlighted.
  Widget _buildSessionGrid() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.sessions.length,
        itemBuilder: (context, index) {
          final session = widget.sessions[index];
          bool isActive = index == _currentSessionIndex &&
              (_sessionStatus == SessionStatus.running ||
                  _sessionStatus == SessionStatus.paused);
          return Container(
            width: 100,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                session.name,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Session Controller"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSessionGrid(),
            SizedBox(height: 20),
            // Circular container showing the session timer.
            SessionCircleContainer(
              onTap: () {
                if (_sessionStatus == SessionStatus.notStarted) {
                  _startCountdown();
                }
              },
              child: _buildCenterContent(),
            ),
            SizedBox(height: 30),
            // Row for Stop and Pause/Resume buttons.
            if (_sessionStatus == SessionStatus.running ||
                _sessionStatus == SessionStatus.paused)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _stopSession,
                    icon: Icon(Icons.stop, color: Colors.white),
                    label: Text("Stop"),
                    style: ElevatedButton.styleFrom(iconColor: Colors.red),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pauseSession,
                    icon: Icon(
                      _sessionStatus == SessionStatus.running
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    label: Text(_sessionStatus == SessionStatus.running
                        ? "Pause"
                        : "Resume"),
                    style: ElevatedButton.styleFrom(iconColor: Colors.blue),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
