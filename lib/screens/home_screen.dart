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
      int? storedDuration = await storeService.loadSessionDuration(session.name);
      if (storedDuration != null) {
        setState(() {
          session.selectedDuration = storedDuration;
        });
      }
    }
  }

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
                  storeService.saveSessionDuration(session.name, session.selectedDuration!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridItem(Session session) {
    return GestureDetector(
      onTap: () => _showTimePicker(session),
      child: Card(
        elevation: 4,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  session.selectedDuration != null
                      ? '${session.selectedDuration} min'
                      : 'Not Selected',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
                children: sessions.map((session) => _buildGridItem(session)).toList(),
              ),
            ),
          ),
          // Start session container at the bottom.
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SessionCircleContainer(
              onTap: () {
                // Navigate to your SessionScreen, passing the sessions list.
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
                  Icon(Icons.play_circle_outline, size: 50, color: Colors.green),
                  SizedBox(height: 8),
                  Text("Start", style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}