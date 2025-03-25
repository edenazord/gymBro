import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';
import '../models/day.dart';
import '../models/machine.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<Workout> _workouts = [];
  List<Machine> _machines = [];
  int? _selectedWorkoutIdForToday;
  bool _isWorkoutCompleted = false;
  List<bool> _exerciseCompleted = []; // Inizializzata come lista vuota

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkTodayWorkout();
  }

  Future<void> _loadData() async {
    await _storageService.initFiles();
    final workouts = await _storageService.readWorkouts();
    final machines = await _storageService.readMachines();
    setState(() {
      _workouts = workouts;
      _machines = machines;
    });
  }

  Future<void> _checkTodayWorkout() async {
    final today = DateTime.now();
    final days = await _storageService.readDays();
    final todayDay = days.firstWhere(
      (d) =>
          d.date.day == today.day &&
          d.date.month == today.month &&
          d.date.year == today.year,
      orElse: () => Day(date: DateTime(today.year, today.month, today.day), workoutIds: []),
    );
    if (todayDay.workoutIds.isNotEmpty) {
      final todayWorkoutId = todayDay.workoutIds.last;
      setState(() {
        _selectedWorkoutIdForToday = todayWorkoutId;
        _initializeExerciseCompleted();
      });
    }
  }

  void _initializeExerciseCompleted() {
    final selectedWorkout = _workouts.firstWhere(
      (w) => w.id == _selectedWorkoutIdForToday,
      orElse: () => Workout(id: 0, name: "Nessun allenamento", exercises: []),
    );
    _exerciseCompleted = List<bool>.filled(selectedWorkout.exercises.length, false);
  }

  Future<void> _completeWorkout() async {
    if (_selectedWorkoutIdForToday == null) return;

    final today = DateTime.now();
    final days = await _storageService.readDays();
    final todayDay = days.firstWhere(
      (d) =>
          d.date.day == today.day &&
          d.date.month == today.month &&
          d.date.year == today.year,
      orElse: () => Day(date: DateTime(today.year, today.month, today.day), workoutIds: []),
    );
    if (!todayDay.workoutIds.contains(_selectedWorkoutIdForToday)) {
      todayDay.workoutIds.add(_selectedWorkoutIdForToday!);
    }
    if (!days.any((d) =>
        d.date.day == today.day &&
        d.date.month == today.month &&
        d.date.year == today.year)) {
      days.add(todayDay);
    }
    await _storageService.writeDays(days);
    setState(() {
      _isWorkoutCompleted = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Allenamento completato e salvato nella cronologia!',
          style: TextStyle(color: Color(0xFF1877F2)),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedWorkout = _selectedWorkoutIdForToday != null
        ? _workouts.firstWhere(
            (w) => w.id == _selectedWorkoutIdForToday,
            orElse: () => Workout(id: 0, name: "Nessun allenamento", exercises: []),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allenamento di oggi'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white70),
              const SizedBox(height: 8),
              if (_workouts.isEmpty)
                const Text(
                  'Nessun allenamento disponibile. Creane uno!',
                  style: TextStyle(color: Colors.white),
                )
              else ...[
                DropdownButtonFormField<int>(
                  value: _selectedWorkoutIdForToday,
                  decoration: const InputDecoration(
                    labelText: 'Seleziona un allenamento',
                    labelStyle: TextStyle(color: Colors.white70),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF145DBF),
                  items: _workouts.map((workout) {
                    return DropdownMenuItem<int>(
                      value: workout.id,
                      child: Text(workout.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: _isWorkoutCompleted
                      ? null
                      : (int? newValue) {
                          setState(() {
                            _selectedWorkoutIdForToday = newValue;
                            _isWorkoutCompleted = false;
                            _initializeExerciseCompleted();
                          });
                        },
                ),
                if (_selectedWorkoutIdForToday != null && selectedWorkout != null) ...[
                  const SizedBox(height: 16),
                  if (selectedWorkout.exercises.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Esercizi:', style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 16.0,
                            columns: const [
                              DataColumn(
                                label: Text('Macchinario', style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('Esercizio', style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text('Azioni', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                            rows: selectedWorkout.exercises.asMap().entries.map((entry) {
                              final index = entry.key;
                              final exercise = entry.value;
                              final machine = _machines.firstWhere(
                                (m) => m.id == exercise.machineId,
                                orElse: () => Machine(id: exercise.machineId, name: 'Sconosciuto'),
                              );
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      machine.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: _exerciseCompleted[index]
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${exercise.sets}x${exercise.reps}@${exercise.weight}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: _exerciseCompleted[index]
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: Icon(
                                        _exerciseCompleted[index]
                                            ? Icons.check_circle
                                            : Icons.check,
                                        color: Colors.white,
                                      ),
                                      onPressed: _isWorkoutCompleted
                                          ? null
                                          : () {
                                              setState(() {
                                                _exerciseCompleted[index] = !_exerciseCompleted[index];
                                              });
                                            },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Nessun esercizio in questo allenamento.',
                      style: TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: _isWorkoutCompleted
                        ? const Text(
                            'Allenamento completato oggi!',
                            style: TextStyle(color: Colors.green),
                          )
                        : ElevatedButton(
                            onPressed: _completeWorkout,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.white70),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1877F2),
                            ),
                            child: const Text(
                              'Completa',
                              style: TextStyle(color: Color(0xFF1877F2)),
                            ),
                          ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}