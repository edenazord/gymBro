import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/workout.dart';
import '../models/day.dart';
import '../models/machine.dart';

class StorageService {
  late File _workoutsFile;
  late File _daysFile;
  late File _machinesFile;

  Future<void> initFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    _workoutsFile = File('${directory.path}/workouts.csv');
    _daysFile = File('${directory.path}/days.csv');
    _machinesFile = File('${directory.path}/machines.csv');

    await _copyCsvFilesFromAssets();

    if (!await _workoutsFile.exists()) {
      await _workoutsFile.create();
      await _workoutsFile.writeAsString('id,name,exercises\n');
    }
    if (!await _daysFile.exists()) {
      await _daysFile.create();
      await _daysFile.writeAsString('date,workoutIds\n');
    } else {
      final content = await _daysFile.readAsString();
      if (!content.startsWith('date,workoutIds')) {
        await _daysFile.writeAsString('date,workoutIds\n$content');
      }
    }
    if (!await _machinesFile.exists()) {
      await _machinesFile.create();
      await _machinesFile.writeAsString('id,name\n');
    }
  }

  Future<void> _copyCsvFilesFromAssets() async {
    final csvFiles = {
      'workouts.csv': _workoutsFile,
      'days.csv': _daysFile,
      'machines.csv': _machinesFile,
    };

    for (var entry in csvFiles.entries) {
      final assetPath = 'assets/csv/${entry.key}';
      final targetFile = entry.value;

      if (!await targetFile.exists()) {
        try {
          final data = await rootBundle.loadString(assetPath);
          await targetFile.writeAsString(data);
        } catch (e) {
          // Eccezione gestita silenziosamente
        }
      }
    }
  }

  Future<List<Workout>> readWorkouts() async {
    try {
      final fileContent = await _workoutsFile.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(fileContent);
      return csvData
          .skip(1)
          .where((row) => row.isNotEmpty && row.length >= 3)
          .map((row) => Workout.fromCsvRow(row))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> writeWorkouts(List<Workout> workouts) async {
    final List<List<String>> csvData = [
      ['id', 'name', 'exercises'],
      ...workouts.map((w) => w.toCsvRow()),
    ];
    final csvString = const ListToCsvConverter().convert(csvData);
    await _workoutsFile.writeAsString(csvString);
  }

  Future<List<Day>> readDays() async {
    try {
      final fileExists = await _daysFile.exists();
      if (!fileExists) {
        return [];
      }

      final fileContent = await _daysFile.readAsString();
      if (fileContent.trim().isEmpty) {
        return [];
      }

      final List<List<dynamic>> csvData = const CsvToListConverter().convert(fileContent);
      final dataRows = csvData.skip(1);
      return dataRows
          .where((row) => row.isNotEmpty && row.length >= 2)
          .map((row) => Day.fromCsvRow(row))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> writeDays(List<Day> days) async {
    final List<List<String>> csvData = [
      ['date', 'workoutIds'],
      ...days.map((d) => d.toCsvRow()),
    ];
    final csvString = const ListToCsvConverter().convert(csvData);
    await _daysFile.writeAsString(csvString);
  }

  Future<List<Machine>> readMachines() async {
    try {
      final fileContent = await _machinesFile.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(fileContent);
      return csvData
          .skip(1)
          .where((row) => row.isNotEmpty && row.length >= 2)
          .map((row) => Machine.fromCsvRow(row))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> writeMachines(List<Machine> machines) async {
    final List<List<String>> csvData = [
      ['id', 'name'],
      ...machines.map((m) => m.toCsvRow()),
    ];
    final csvString = const ListToCsvConverter().convert(csvData);
    await _machinesFile.writeAsString(csvString);
  }
}