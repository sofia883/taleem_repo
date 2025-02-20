import 'common_imports.dart';

void main() {
  runApp(MyApp());
}

// A simple model to hold session info
class Session {
  final String name;
  final int duration; // in minutes
  Session({required this.name, required this.duration});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talim Timer',
      home: HomeScreen(),
    );
  }
}
