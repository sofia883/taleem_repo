import 'package:taleem_app/common_imports.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StoreService storeService = StoreService();

  List<Session> sessions = [
    Session(name: 'Halqa', defaultDuration: 10),
    Session(name: 'Taleem', defaultDuration: 20),
    Session(name: '6 Sifat', defaultDuration: 5),
    Session(name: 'Mashwarah', defaultDuration: 5),
    Session(name: 'Tashkeel', defaultDuration: 10),
  ];

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

  // Opens a bottom sheet with a CupertinoTimerPicker.
  void _showTimePicker(Session session) {
    Duration initialDuration =
        Duration(minutes: session.selectedDuration ?? session.defaultDuration);
    Duration tempDuration = initialDuration;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: initialDuration,
                  onTimerDurationChanged: (Duration newDuration) {
                    tempDuration = newDuration;
                  },
                ),
              ),
              ElevatedButton(
                child: Text("Select Time"),
                onPressed: () {
                  setState(() {
                    session.selectedDuration = tempDuration.inMinutes;
                  });
                  storeService.saveSessionDuration(
                      session.name, session.selectedDuration!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Build each grid item for the session.
  Widget _buildGridItem(Session session) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              session.name,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // deafult time with small dropdown to change the time.
            DropdownButton<int>(
              value: session.selectedDuration ?? session.defaultDuration,
              items: [5, 10, 15, 20, 25, 30].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value min'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  session.selectedDuration = newValue;
                });
                storeService.saveSessionDuration(
                    session.name, session.selectedDuration!);
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Talim Time Selector"),
      ),
      body: Column(
        children: [
          // Grid for session items.
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: sessions
                    .map((session) => GestureDetector(
                          onTap: () => _showTimePicker(session),
                          child: _buildGridItem(session),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Start session container at the bottom.
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SessionCircleContainer(
              onTap: () {
                // Navigate to the SessionScreen, passing the sessions list.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SessionScreen(sessions: sessions),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 50, color: Colors.green),
                  SizedBox(height: 8),
                  Text("Start",
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
