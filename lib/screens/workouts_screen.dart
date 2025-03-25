import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final StorageService _storageService = StorageService();
  List<Machine> _machines = [];
  List<Workout> _workouts = [];
  final TextEditingController _workoutNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _storageService.initFiles();
    final machines = await _storageService.readMachines();
    final workouts = await _storageService.readWorkouts();
    final uniqueMachines = <int, Machine>{};
    for (var machine in machines) {
      uniqueMachines[machine.id] = machine;
    }
    setState(() {
      _machines = uniqueMachines.values.toList();
      _machines.sort((a, b) => a.name.compareTo(b.name));
      _workouts = workouts;
    });
  }

  Future<void> _addWorkout() async {
    final name = _workoutNameController.text.trim();
    if (name.isNotEmpty) {
      final newWorkout = Workout(
        id: _workouts.isEmpty ? 1 : _workouts.map((w) => w.id).reduce((a, b) => a > b ? a : b) + 1,
        name: name,
        exercises: [],
      );
      _workouts.add(newWorkout);
      await _storageService.writeWorkouts(_workouts);
      setState(() {});
      _workoutNameController.clear();
    }
  }

  Future<void> _deleteWorkout(Workout workout) async {
    _workouts.removeWhere((w) => w.id == workout.id);
    await _storageService.writeWorkouts(_workouts);

    final days = await _storageService.readDays();
    for (var day in days) {
      day.workoutIds.removeWhere((id) => id == workout.id);
    }
    await _storageService.writeDays(days);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _workoutNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Allenamento',
                      labelStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addWorkout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.white70),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1877F2),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF1877F2)),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white70), // Riga bianca dopo l'input
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 16.0, // Spazio ridotto tra le colonne
                columns: const [
                  DataColumn(
                    label: Text('Nome', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text('Esercizi', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text('Azioni', style: TextStyle(color: Colors.white)),
                  ),
                ],
                rows: _workouts.map((workout) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(workout.name, style: const TextStyle(color: Colors.white)),
                      ),
                      DataCell(
                        Text('${workout.exercises.length}', style: const TextStyle(color: Colors.white70)),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditWorkoutScreen(
                                      workout: workout,
                                      machines: _machines,
                                      onSave: (updatedWorkout) async {
                                        final idx = _workouts.indexWhere((w) => w.id == updatedWorkout.id);
                                        if (idx != -1) {
                                          _workouts[idx] = updatedWorkout;
                                          await _storageService.writeWorkouts(_workouts);
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _deleteWorkout(workout),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
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
    );
  }
}

class EditWorkoutScreen extends StatefulWidget {
  final Workout workout;
  final List<Machine> machines;
  final Function(Workout) onSave;

  const EditWorkoutScreen({Key? key, required this.workout, required this.machines, required this.onSave})
      : super(key: key);

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  late TextEditingController _nameController;
  late List<Exercise> _exercises;
  int? _selectedMachineId;
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _exercises = List<Exercise>.from(widget.workout.exercises);
    _nameController.addListener(_saveWorkout);
  }

  void _saveWorkout() {
    final updatedWorkout = Workout(
      id: widget.workout.id,
      name: _nameController.text,
      exercises: _exercises,
    );
    widget.onSave(updatedWorkout);
  }

  void _addOrUpdateExercise() {
    if (_selectedMachineId == null) return;
    final sets = int.tryParse(_setsController.text) ?? 0;
    final reps = _repsController.text.trim();
    final weight = _weightController.text.trim();

    if (reps.isEmpty || weight.isEmpty) return;

    final newExercise = Exercise(
      machineId: _selectedMachineId!,
      sets: sets,
      reps: reps,
      weight: weight,
    );

    setState(() {
      if (_editingIndex != null) {
        _exercises[_editingIndex!] = newExercise;
        _editingIndex = null;
      } else {
        _exercises.add(newExercise);
      }
    });

    _setsController.clear();
    _repsController.clear();
    _weightController.clear();
    _selectedMachineId = null;

    _saveWorkout();
  }

  void _editExercise(int index) {
    final exercise = _exercises[index];
    setState(() {
      _editingIndex = index;
      _selectedMachineId = exercise.machineId;
      _setsController.text = exercise.sets.toString();
      _repsController.text = exercise.reps;
      _weightController.text = exercise.weight;
    });
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _setsController.clear();
        _repsController.clear();
        _weightController.clear();
        _selectedMachineId = null;
      }
    });

    _saveWorkout();
  }

  @override
  void dispose() {
    _nameController.removeListener(_saveWorkout);
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Allenamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Allenamento',
                labelStyle: TextStyle(color: Colors.white70),
                contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white70),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedMachineId,
              decoration: const InputDecoration(
                labelText: 'Macchinario',
                labelStyle: TextStyle(color: Colors.white70),
                contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              dropdownColor: const Color(0xFF145DBF),
              items: widget.machines
                  .map((machine) => DropdownMenuItem<int>(
                        value: machine.id,
                        child: Text(machine.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMachineId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Serie',
                      labelStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Ripetizioni',
                      labelStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.numberWithOptions(decimal: false, signed: false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      labelStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addOrUpdateExercise,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.white70),
                ),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1877F2),
              ),
              child: Text(
                _editingIndex != null ? 'Aggiorna Esercizio' : 'Aggiungi Esercizio',
                style: const TextStyle(color: Color(0xFF1877F2)),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white70),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
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
                  rows: _exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    final machine = widget.machines.firstWhere(
                      (m) => m.id == exercise.machineId,
                      orElse: () => Machine(id: exercise.machineId, name: 'Sconosciuto'),
                    );
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(machine.name, style: const TextStyle(color: Colors.white)),
                        ),
                        DataCell(
                          Text(
                            '${exercise.sets}x${exercise.reps}@${exercise.weight}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: () => _editExercise(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white),
                                onPressed: () => _deleteExercise(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
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