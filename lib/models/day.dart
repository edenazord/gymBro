class Day {
  final DateTime date;
  final List<int> workoutIds;

  Day({required this.date, required this.workoutIds});

  // Converte il giorno in una lista per il CSV
  List<String> toCsvRow() {
    return [
      date.toIso8601String(), // Usa il formato ISO 8601 completo
      workoutIds.join(","),
    ];
  }

  // Crea un giorno da una riga CSV
  factory Day.fromCsvRow(List<dynamic> row) {
    final dateString = row[0].toString();
    final date = DateTime.parse(dateString); // Parsea il formato ISO 8601
    final workoutIdsString = row[1].toString();
    final workoutIds = workoutIdsString.isNotEmpty
        ? workoutIdsString.split(',').map((id) => int.parse(id.trim())).toList()
        : <int>[];
    return Day(date: date, workoutIds: workoutIds);
  }

  // Serializza in stringa per altri formati (opzionale, lasciato per compatibilità)
  String toFileString() {
    return '${date.year}-${date.month}-${date.day};${workoutIds.join(",")}';
  }

  // Deserializza da stringa (opzionale, lasciato per compatibilità)
  factory Day.fromFileString(String line) {
    final parts = line.split(';');
    final dateParts = parts[0].split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    final workoutIdsString = parts.length > 1 ? parts[1] : '';
    final workoutIds = workoutIdsString.isNotEmpty
        ? workoutIdsString.split(',').map((id) => int.parse(id.trim())).toList()
        : <int>[];
    return Day(date: date, workoutIds: workoutIds);
  }
}