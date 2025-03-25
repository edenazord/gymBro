class Exercise {
  final int machineId;
  final int sets;
  final String reps;
  final String weight;

  Exercise({
    required this.machineId,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  // Converte l'esercizio in una lista per il CSV
  List<String> toCsvRow() {
    return [machineId.toString(), sets.toString(), reps, weight];
  }

  // Crea un esercizio da una riga CSV
  factory Exercise.fromCsvRow(List<dynamic> row) {
    return Exercise(
      machineId: int.parse(row[0].toString()),
      sets: int.parse(row[1].toString()),
      reps: row[2].toString(),
      weight: row[3].toString(),
    );
  }

  // Serializza in stringa per altri formati
  @override
  String toString() {
    return '$machineId;$sets;$reps;$weight';
  }

  // Deserializza da stringa
  factory Exercise.fromString(String exerciseString) {
    final parts = exerciseString.split(';');
    return Exercise(
      machineId: int.parse(parts[0]),
      sets: int.parse(parts[1]),
      reps: parts[2],
      weight: parts[3],
    );
  }
}