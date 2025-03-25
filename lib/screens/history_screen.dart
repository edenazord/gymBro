import 'package:flutter/material.dart';
import '../models/day.dart';
import '../models/workout.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<Day> _pastDays = [];
  List<Workout> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _storageService.initFiles();
    final days = await _storageService.readDays();
    final workouts = await _storageService.readWorkouts();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final pastDays = days.where((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate.isBefore(todayDate);
    }).toList();

    setState(() {
      _pastDays = pastDays;
      _workouts = workouts;
    });
  }

  Future<void> _deleteDay(Day day) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF145DBF),
        title: const Text('Conferma eliminazione', style: TextStyle(color: Colors.white)),
        content: Text(
          'Sei sicuro di voler eliminare il giorno ${day.date.day}/${day.date.month}/${day.date.year}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white70),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1877F2),
            ),
            child: const Text('Elimina', style: TextStyle(color: Color(0xFF1877F2))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final allDays = await _storageService.readDays();
      allDays.removeWhere((d) =>
          d.date.year == day.date.year &&
          d.date.month == day.date.month &&
          d.date.day == day.date.day);
      await _storageService.writeDays(allDays);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cronologia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white70),
            const SizedBox(height: 8),
            _pastDays.isEmpty
                ? const Center(
                    child: Text(
                      'Nessuna giornata passata registrata.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : SizedBox(
                    width: double.infinity, // Per centrare orizzontalmente la tabella
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 16.0,
                        columns: const [
                          DataColumn(
                            label: Text('Data', style: TextStyle(color: Colors.white)),
                          ),
                          DataColumn(
                            label: Text('Allenamenti', style: TextStyle(color: Colors.white)),
                          ),
                          DataColumn(
                            label: Text('Azioni', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                        rows: _pastDays.map((day) {
                          final dayWorkouts = _workouts.where((w) => day.workoutIds.contains(w.id)).toList();
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${day.date.day}/${day.date.month}/${day.date.year}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(
                                Text(
                                  dayWorkouts.isNotEmpty
                                      ? dayWorkouts.map((w) => w.name).join(', ')
                                      : 'Nessun allenamento',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white),
                                  onPressed: () => _deleteDay(day),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}