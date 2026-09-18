import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/alarm_service.dart';
import 'services/puzzle_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize persistent storage
  final storageService = await StorageService.init();

  // Initialize core services
  final soundService = SoundService();
  final puzzleService = PuzzleService();
  final alarmService = AlarmService(
    storage: storageService,
    soundService: soundService,
  );

  runApp(PuzzleWakeApp(
    storageService: storageService,
    soundService: soundService,
    puzzleService: puzzleService,
    alarmService: alarmService,
  ));
}

class PuzzleWakeApp extends StatefulWidget {
  final StorageService storageService;
  final SoundService soundService;
  final PuzzleService puzzleService;
  final AlarmService alarmService;

  const PuzzleWakeApp({
    super.key,
    required this.storageService,
    required this.soundService,
    required this.puzzleService,
    required this.alarmService,
  });

  @override
  State<PuzzleWakeApp> createState() => _PuzzleWakeAppState();
}

class _PuzzleWakeAppState extends State<PuzzleWakeApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.storageService.getDarkMode();
  }

  void _onThemeChanged(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PuzzleWake',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        alarmService: widget.alarmService,
        soundService: widget.soundService,
        storageService: widget.storageService,
        puzzleService: widget.puzzleService,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}
