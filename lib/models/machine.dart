class Machine {
  final int id;
  final String name;

  Machine({required this.id, required this.name});

  // Converte la macchina in una lista per il CSV
  List<String> toCsvRow() {
    return [id.toString(), name];
  }

  // Crea una macchina da una riga CSV
  factory Machine.fromCsvRow(List<dynamic> row) {
    return Machine(
      id: int.parse(row[0].toString()),
      name: row[1].toString(),
    );
  }

  // Serializza in stringa per altri formati
  String toFileString() {
    return '$id;$name';
  }

  // Deserializza da stringa
  factory Machine.fromFileString(String line) {
    final parts = line.split(';');
    return Machine(
      id: int.parse(parts[0]),
      name: parts[1],
    );
  }
}