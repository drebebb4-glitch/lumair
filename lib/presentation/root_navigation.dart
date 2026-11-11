import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../domain/alert_provider.dart';
import '../domain/auth_provider.dart';
import '../domain/providers.dart';
import 'screens/alert_settings_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/community_screen.dart';
import 'screens/education_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/glass.dart';
import 'widgets/slide_page.dart';
import '../core/app_theme.dart';

/// Gate peluncuran: splash statis → onboarding (1x) → navigasi utama.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(
        () => _onboarded = prefs.getBool(AppConstants.onboardedKey) ?? false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _onboarded = true);
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.onboardedKey, true);
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

/// Splash statis (tanpa timer/animasi — aman test).
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.night,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo-mark.png',
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
                    colors: [AppTheme.accent, AppTheme.skyDeep],
                  ),
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
                strokeWidth: 2.4,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RootNav extends ConsumerStatefulWidget {
  const _RootNav();

  @override
  ConsumerState<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends ConsumerState<_RootNav> {
  int _index = 0;
  final Set<int> _moving = {};
  Timer? _settle;

  static const _screens = [
    HomeScreen(),
    ForecastScreen(),
    FavoritesScreen(),
    EducationScreen(),
    CommunityScreen(),
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
    // Sinkronkan lokasi beranda ke penyimpanan untuk worker peringatan dini.
    ref.watch(alertLocationSyncProvider);
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : kSlideDuration;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BrandHeader(isHome: _index == 0),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (var i = 0; i < _screens.length; i++)
                    SlidePage(
                      offset: (i - _index).clamp(-1, 1).toDouble(),
                      visible: i == _index || _moving.contains(i),
                      duration: duration,
                      child: _screens[i],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.nightSurface,
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
            selectedItemColor: AppTheme.accent,
            unselectedItemColor: AppTheme.textFaint,
            selectedFontSize: 11.5,
            unselectedFontSize: 11.5,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: _select,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart_outlined),
                activeIcon: Icon(Icons.show_chart),
                label: 'Prakiraan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorit',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Edukasi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.campaign_outlined),
                activeIcon: Icon(Icons.campaign),
                label: 'Komunitas',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends ConsumerWidget {
  const _BrandHeader({required this.isHome});

  final bool isHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    final alertsOn = ref.watch(alertSettingsProvider.select((s) => s.enabled));
    final fromCache = ref
        .watch(aqiProvider)
        .maybeWhen(data: (reading) => reading.fromCache, orElse: () => false);
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : kSlideDuration;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedAlign(
              duration: duration,
              curve: Curves.easeInOutCubic,
              alignment: isHome ? Alignment.center : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo-mark.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    semanticLabel: 'Logo LUMAIR',
                    errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.accent, AppTheme.skyDeep],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.air, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LUMAIR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
            if (isHome)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fromCache)
                      const GlassChip(
                        icon: Icons.cloud_off_outlined,
                        label: 'offline',
                      ),
                    if (fromCache) const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Peringatan dini',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AlertSettingsScreen(),
                        ),
                      ),
                      icon: Icon(
                        alertsOn
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: alertsOn
                            ? AppTheme.accent
                            : AppTheme.textSoft,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(),
                        ),
                      ),
                      child: auth == null
                          ? Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppTheme.textSoft,
                                size: 20,
                              ),
                            )
                          : CircleAvatar(
                              radius: 19,
                              backgroundColor: AppTheme.accent,
                              child: Text(
                                auth.displayName.isEmpty
                                    ? '?'
                                    : auth.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF06111F),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
