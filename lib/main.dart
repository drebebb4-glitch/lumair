import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'presentation/screens/education_screen.dart';
import 'presentation/screens/favorites_screen.dart';
import 'presentation/screens/forecast_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/widgets/slide_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LumairApp()));
}

class LumairApp extends StatelessWidget {
  const LumairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUMAIR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _RootGate(),
    );
  }
}

/// Gate peluncuran: splash statis → onboarding (1x) → navigasi utama.
class _RootGate extends StatefulWidget {
  const _RootGate();
  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _onboarded = p.getBool(AppConstants.onboardedKey) ?? false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _onboarded = true); // gagal baca → skip onboarding
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(AppConstants.onboardedKey, true);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) return const _SplashScreen();
    if (_onboarded == false) {
      return OnboardingScreen(onDone: _finishOnboarding);
    }
    return const _RootNav();
  }
}

/// Splash statis (tanpa timer/animasi — aman test). Teks brand tidak
/// ditulis di sini supaya asersi test 'LUMAIR' tetap tepat 1x di Beranda.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 96,
              height: 96,
              fit: BoxFit.contain,
              semanticLabel: 'Logo LUMAIR',
              errorBuilder: (_, __, ___) => Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF34D399), Color(0xFF0EA5E9)]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.air, color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 26),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: Color(0xFF34D399)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RootNav extends StatefulWidget {
  const _RootNav();
  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0;

  /// Tab yang masih bergeser keluar layar. Setelah animasi selesai, dikosongkan.
  final Set<int> _moving = {};
  Timer? _settle;

  static const _screens = [
    HomeScreen(),
    ForecastScreen(),
    MapScreen(),
    FavoritesScreen(),
    EducationScreen(),
  ];

  void _select(int i) {
    if (i == _index) return;
    _settle?.cancel();
    setState(() {
      _moving.add(_index);
      _index = i;
    });
    _settle = Timer(kSlideDuration, () {
      if (mounted) setState(_moving.clear);
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hormati pengaturan aksesibilitas "kurangi animasi".
    final dur =
        MediaQuery.of(context).disableAnimations ? Duration.zero : kSlideDuration;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < _screens.length; i++)
            SlidePage(
              offset: (i - _index).clamp(-1, 1).toDouble(),
              visible: i == _index || _moving.contains(i),
              duration: dur,
              child: _screens[i],
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _index,
            selectedItemColor: const Color(0xFF34D399),
            unselectedItemColor: const Color(0xFF64748B),
            selectedFontSize: 11.5,
            unselectedFontSize: 11.5,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: _select,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart_outlined),
                  activeIcon: Icon(Icons.show_chart),
                  label: 'Prakiraan'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Peta'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.favorite),
                  label: 'Favorit'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school_outlined),
                  activeIcon: Icon(Icons.school),
                  label: 'Edukasi'),
            ],
          ),
        ),
      ),
    );
  }
}
