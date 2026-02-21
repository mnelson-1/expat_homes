import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expat_app/screens/get_started_screen.dart';
import 'package:expat_app/screens/splash_screen.dart';

void main() {
  runApp(const ExpatApp());
}

/// Remembers whether splash has completed so we don't show splash again
/// when the app is resumed from background (e.g. after Activity recreation).
class _EntryState {
  static bool splashCompleted = false;
}

class ExpatApp extends StatelessWidget {
  const ExpatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpatHomes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF212C2F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  void _onSplashComplete() {
    _EntryState.splashCompleted = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_EntryState.splashCompleted) {
      return const GetStartedScreen();
    }
    return SplashScreen(onComplete: _onSplashComplete);
  }
}
