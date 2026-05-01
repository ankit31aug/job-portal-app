import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/browse_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_profile_screens.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const JobPortalApp(),
    ),
  );
}

class JobPortalApp extends StatelessWidget {
  const JobPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const _AppShell(),
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/browse': (ctx) => const BrowseScreen(),
        '/dashboard': (ctx) => const DashboardScreen(),
        '/profile': (ctx) => const ProfileScreen(),
      },
    );
  }
}

// ─── App Shell with Bottom Navigation ────────────────────────────────
class _AppShell extends StatefulWidget {
  const _AppShell();
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    BrowseScreen(),
    _DashboardOrLoginPrompt(),
    _ProfileOrLoginPrompt(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.assignment_outlined),
                if (auth.isLoggedIn)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.assignment),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: auth.isLoggedIn
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    auth.user!.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                )
              : const Icon(Icons.person_outline),
            activeIcon: auth.isLoggedIn
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    auth.user!.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                )
              : const Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Helper screens for unauthenticated users
class _DashboardOrLoginPrompt extends StatelessWidget {
  const _DashboardOrLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const DashboardScreen();
    return _LoginPromptScreen(
      icon: Icons.assignment_outlined,
      title: 'Track Your Applications',
      subtitle: 'Sign in to view your job applications and saved jobs',
    );
  }
}

class _ProfileOrLoginPrompt extends StatelessWidget {
  const _ProfileOrLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const ProfileScreen();
    return _LoginPromptScreen(
      icon: Icons.person_outlined,
      title: 'Your Profile',
      subtitle: 'Sign in to manage your profile and preferences',
    );
  }
}

class _LoginPromptScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _LoginPromptScreen({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
