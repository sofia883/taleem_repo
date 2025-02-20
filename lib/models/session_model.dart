// A simple model to hold session info

class Session {
  final String name;
  final int defaultDuration; // default duration in minutes
  int? selectedDuration;     // user-selected duration (null if not yet chosen)

  Session({
    required this.name,
    required this.defaultDuration,
    this.selectedDuration,
  });
}