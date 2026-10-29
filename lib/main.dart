import 'dart:async';
import 'dart:math' as math;

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

/// Durasi minimal splash tampil — cukup buat intro logo (scale + fade)
/// selesai terasa, tanpa ngehang lama. (di web flag onboarding terbaca cepat)
const kSplashMinDuration = Duration(milliseconds: 900);

/// Gate peluncuran: splash animasi (durasi minimal) → onboarding (1x) →
/// navigasi utama.
class _RootGate extends StatefulWidget {
  const _RootGate();
  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool? _onboarded;
  bool _splashDone = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _loadFlag();
    _splashTimer = Timer(kSplashMinDuration, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFlag() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(
          () => _onboarded = p.getBool(AppConstants.onboardedKey) ?? false);
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
    final Widget child;
    if (_onboarded == null || !_splashDone) {
      child =
          const KeyedSubtree(key: ValueKey('splash'), child: _SplashScreen());
    } else if (_onboarded == false) {
      child = KeyedSubtree(
          key: const ValueKey('onboarding'),
          child: OnboardingScreen(onDone: _finishOnboarding));
    } else {
      child = const KeyedSubtree(key: ValueKey('nav'), child: _RootNav());
    }
    // Perbedaan antar-state di-fade halus — splash gak nyolot langsung ganti.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}

/// Splash animasi: logo muncul di tengah (scale + fade), latar aurora samar
/// berputar pelan dengan blob cahaya lembut. Tanpa timer — tampil sampai
/// flag onboarding selesai dibaca, lalu transisi fade via [AnimatedSwitcher]
/// di _RootGate. Teks brand tidak ditulis di sini supaya asersi test 'LUMAIR'
/// tetap tepat 1x.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _loaderFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const _SplashFrame(
          logoScale: 1, logoFade: 1, loaderFade: 1, ambient: 0, glow: 0.35);
    }
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _ambient]),
        builder: (context, _) {
          final t = _ambient.value;
          return _SplashFrame(
            logoScale: _logoScale.value,
            logoFade: _logoFade.value,
            loaderFade: _loaderFade.value,
            ambient: t,
            glow: _splashLerp(0.28, 0.45, (math.sin(t * 2 * math.pi) + 1) / 2),
          );
        },
      ),
    );
  }
}

double _splashLerp(double a, double b, double t) => a + (b - a) * t;

class _SplashFrame extends StatelessWidget {
  const _SplashFrame({
    required this.logoScale,
    required this.logoFade,
    required this.loaderFade,
    required this.ambient,
    required this.glow,
  });

  final double logoScale;
  final double logoFade;
  final double loaderFade;
  final double ambient;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final t = ambient * 2 * math.pi;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Latar dasar: gradasi radial biru gelap ke hampir hitam.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.7),
                radius: 1.5,
                colors: [Color(0xFF0C1830), Color(0xFF070B14)],
              ),
            ),
          ),
          // Aurora: sapuan warna hijau-biru sangat tipis, berputar pelan —
          // cukup untuk nuansa hidup, bukan perhatian utama.
          Opacity(
            opacity: 0.9,
            child: Transform.rotate(
              angle: ambient * 2 * math.pi,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      Color(0x0010B981),
                      Color(0x1610B981),
                      Color(0x0010B981),
                      Color(0x120EA5E9),
                      Color(0x0010B981),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Dua blob cahaya samar yang bergerak lambat.
          Positioned(
            top: size.height * 0.14 + math.sin(t) * 26,
            right: size.width * 0.12 + math.cos(t) * 34,
            child: _blob(const Color(0x1434D399), 260),
          ),
          Positioned(
            bottom: size.height * 0.16 + math.cos(t) * 22,
            left: size.width * 0.08 + math.sin(t) * 30,
            child: _blob(const Color(0x100EA5E9), 230),
          ),
          // Logo di tengah: scale + fade masuk, lalu float lembut.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, math.sin(t) * 7),
                  child: Transform.scale(
                    scale: logoScale,
                    child: Opacity(
                      opacity: logoFade,
                      child: _logoWithGlow(),
                    ),
                  ),
                ),
                Opacity(
                  opacity: loaderFade,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Color(0xFF34D399)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoWithGlow() {
    return Container(
      width: 130,
      height: 130,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          const Color(0xFF34D399).withValues(alpha: glow),
          const Color(0xFF34D399).withValues(alpha: 0),
        ]),
      ),
      child: Image.asset(
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
    );
  }

  Widget _blob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color,
            color.withValues(alpha: 0),
          ]),
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
    final dur = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : kSlideDuration;

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
