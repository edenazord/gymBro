import 'package:gymBro/models/exercise.dart';

class Workout {
  final int id;
  final String name;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.name,
    required this.exercises,
  });

  // Converte il workout in una lista per il CSV
  List<String> toCsvRow() {
    return [
      id.toString(),
      name,
      exercises.map((e) => e.toString()).join("|"),
    ];
  }

  // Crea un workout da una riga CSV
  factory Workout.fromCsvRow(List<dynamic> row) {
    final id = int.parse(row[0].toString());
    final name = row[1].toString();
    final exerciseString = row[2].toString();
    final List<Exercise> exercises = exerciseString.isNotEmpty
        ? exerciseString.split("|").map((e) => Exercise.fromString(e)).toList()
        : [];
    return Workout(id: id, name: name, exercises: exercises);
  }

  // Serializza in stringa per altri formati
  String toFileString() {
    return '$id|$name|${exercises.map((e) => e.toString()).join("|")}';
  }

  // Deserializza da stringa
  factory Workout.fromFileString(String line) {
    final parts = line.split('|');
    final id = int.parse(parts[0]);
    final name = parts[1];
    final exerciseString = parts.length > 2 ? parts.sublist(2) : [];
    final List<Exercise> exercises = exerciseString.isNotEmpty
        ? exerciseString.map((e) => Exercise.fromString(e)).toList()
        : [];
    return Workout(id: id, name: name, exercises: exercises);
  }
}