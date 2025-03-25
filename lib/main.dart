import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/machines_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const GymTrainingApp());
}

class GymTrainingApp extends StatelessWidget {
  const GymTrainingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gymBro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1877F2), // Sfondo blu Facebook
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1877F2),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    WorkoutsScreen(),
    MachinesScreen(),
    HistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1877F2),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center), // Icona per Allenamento
            label: 'Allenamento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Icona diversa per Routine
            label: 'Routine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman), // Icona per Macchine
            label: 'Macchine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history), // Icona per Cronologia
            label: 'Cronologia',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(color: Colors.white, fontSize: 14),
        unselectedLabelStyle: const TextStyle(color: Colors.white, fontSize: 14),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}