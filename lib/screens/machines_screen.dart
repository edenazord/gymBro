import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../services/storage_service.dart';

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({Key? key}) : super(key: key);

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final StorageService _storageService = StorageService();
  List<Machine> _machines = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    await _storageService.initFiles();
    final machines = await _storageService.readMachines();
    final uniqueMachines = <int, Machine>{};
    for (var machine in machines) {
      uniqueMachines[machine.id] = machine;
    }
    setState(() {
      _machines = uniqueMachines.values.toList();
      _machines.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _addMachine() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final maxId = _machines.isEmpty ? 0 : _machines.map((m) => m.id).reduce((a, b) => a > b ? a : b);
      final newMachine = Machine(id: maxId + 1, name: name);
      _machines.add(newMachine);
      _machines.sort((a, b) => a.name.compareTo(b.name));
      await _storageService.writeMachines(_machines);
      setState(() {});
      _nameController.clear();
    }
  }

  Future<void> _editMachine(Machine machine) async {
    final TextEditingController editController = TextEditingController(text: machine.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF145DBF), // Sfondo dialogo coerente
        title: const Text('Modifica Macchinario', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Nome Macchinario',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, editController.text),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white70),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1877F2),
            ),
            child: const Text('Salva', style: TextStyle(color: Color(0xFF1877F2))),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final updatedMachine = Machine(id: machine.id, name: result.trim());
      final index = _machines.indexWhere((m) => m.id == machine.id);
      if (index != -1) {
        _machines[index] = updatedMachine;
        _machines.sort((a, b) => a.name.compareTo(b.name));
        await _storageService.writeMachines(_machines);
        setState(() {});
      }
    }
  }

  Future<void> _deleteMachine(Machine machine) async {
    _machines.removeWhere((m) => m.id == machine.id);
    _machines.sort((a, b) => a.name.compareTo(b.name));
    await _storageService.writeMachines(_machines);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Macchine'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Macchinario',
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
                  onPressed: _addMachine,
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
                    label: Text('Azioni', style: TextStyle(color: Colors.white)),
                  ),
                ],
                rows: _machines.map((machine) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(machine.name, style: const TextStyle(color: Colors.white)),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _editMachine(machine),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _deleteMachine(machine),
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