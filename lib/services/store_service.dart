import 'package:taleem_app/common_imports.dart';

class StoreService {
  /// Loads the stored duration (in minutes) for a given session name.
  Future<int?> loadSessionDuration(String sessionName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(sessionName);
  }

  /// Saves the provided duration (in minutes) for the given session name.
  Future<void> saveSessionDuration(String sessionName, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(sessionName, duration);
  }

  /// Loads durations for all session names provided in the list.
  /// Returns a map of session names and their stored durations.
  Future<Map<String, int>> loadAllSessionDurations(
      List<String> sessionNames) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> durations = {};
    for (String name in sessionNames) {
      int? duration = prefs.getInt(name);
      if (duration != null) {
        durations[name] = duration;
      }
    }
    return durations;
  }
}
