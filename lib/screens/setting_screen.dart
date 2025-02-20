import 'package:taleem_app/common_imports.dart';
class SettingsPage extends StatefulWidget {
  final int halkaTime;
  final int talimTime;
  final int sifatTime;
  final int mashwaraTime;
  final int tashqeerTime;
  final Function(int, int, int, int, int) onSave;

  SettingsPage({
    required this.halkaTime,
    required this.talimTime,
    required this.sifatTime,
    required this.mashwaraTime,
    required this.tashqeerTime,
    required this.onSave,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController halkaController;
  late TextEditingController talimController;
  late TextEditingController sifatController;
  late TextEditingController mashwaraController;
  late TextEditingController tashqeerController;

  @override
  void initState() {
    super.initState();
    halkaController = TextEditingController(text: widget.halkaTime.toString());
    talimController = TextEditingController(text: widget.talimTime.toString());
    sifatController = TextEditingController(text: widget.sifatTime.toString());
    mashwaraController = TextEditingController(text: widget.mashwaraTime.toString());
    tashqeerController = TextEditingController(text: widget.tashqeerTime.toString());
  }

  @override
  void dispose() {
    halkaController.dispose();
    talimController.dispose();
    sifatController.dispose();
    mashwaraController.dispose();
    tashqeerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Session Durations'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: halkaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Halka Duration (minutes)'),
            ),
            TextField(
              controller: talimController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Talim Duration (minutes)'),
            ),
            TextField(
              controller: sifatController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '6 Sifat Duration (minutes)'),
            ),
            TextField(
              controller: mashwaraController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Mashwara Duration (minutes)'),
            ),
            TextField(
              controller: tashqeerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Tashqeer Duration (minutes)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                int newHalka = int.tryParse(halkaController.text) ?? widget.halkaTime;
                int newTalim = int.tryParse(talimController.text) ?? widget.talimTime;
                int newSifat = int.tryParse(sifatController.text) ?? widget.sifatTime;
                int newMashwara = int.tryParse(mashwaraController.text) ?? widget.mashwaraTime;
                int newTashqeer = int.tryParse(tashqeerController.text) ?? widget.tashqeerTime;
                widget.onSave(newHalka, newTalim, newSifat, newMashwara, newTashqeer);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
