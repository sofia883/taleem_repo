import 'common_imports.dart';

void main() {
  initializeNotifications();
  runApp(MyApp());
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
