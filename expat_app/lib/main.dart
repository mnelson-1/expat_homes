import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expat_app/models/user_profile.dart';
import 'package:expat_app/screens/agent_home_screen.dart';
import 'package:expat_app/screens/expat_home_screen.dart';
import 'package:expat_app/screens/get_started_screen.dart';
import 'package:expat_app/screens/landlord_home_screen.dart';
import 'package:expat_app/screens/splash_screen.dart';
import 'package:expat_app/services/agents_service.dart';
import 'package:expat_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
    if (!_EntryState.splashCompleted) {
      return SplashScreen(onComplete: _onSplashComplete);
    }
    // Auth stream drives sign-out: Firestore profile listeners can error when the
    // token is revoked, which previously left StreamBuilder stuck on the last profile.
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = authSnap.data;
        if (user == null) {
          return const GetStartedScreen();
        }

        return StreamBuilder<UserProfile?>(
          stream: AuthService().userProfileStream(user.uid),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final profile = profileSnap.data;
            if (profileSnap.hasError || profile == null) {
              return const GetStartedScreen();
            }
            AgentsService().seedLicensedAgents();
            return _buildHomeForRole(profile.role);
          },
        );
      },
    );
  }

  Widget _buildHomeForRole(UserRole role) {
    switch (role) {
      case UserRole.expat:
        return const ExpatHomeScreen();
      case UserRole.landlord:
        return const LandlordHomeScreen();
      case UserRole.agent:
        return const AgentHomeScreen(initialIndex: 1);
      case UserRole.superAdmin:
        // TODO: Super Admin web panel; for now show expat home
        return const ExpatHomeScreen();
    }
  }
}
