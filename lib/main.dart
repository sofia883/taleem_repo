import 'common_imports.dart';

void main() {
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
