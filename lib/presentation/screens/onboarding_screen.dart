import 'package:flutter/material.dart';

/// Onboarding 3 slide — tampil sekali (flag di SharedPreferences).
/// Konten compact supaya aman di viewport test (600px) & HP kecil.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _slides = [
    (
      icon: Icons.air,
      colors: [Color(0xFF34D399), Color(0xFF0EA5E9)],
      title: 'Kenal udara lu',
      body:
          'LUMAIR menunjukkan kualitas udara di sekitar lu — AQI, polutan utama, dan rekomendasi kesehatan, langsung jelas dalam hitungan detik.',
    ),
    (
      icon: Icons.my_location,
      colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
      title: 'Izin lokasi',
      body:
          'Biar angkanya akurat, izinkan akses lokasi. Kalau ditolak, LUMAIR memakai Jakarta sebagai contoh — dan lu tetap bisa ganti kota kapan aja.',
    ),
    (
      icon: Icons.speed,
      colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
      title: 'Cara bacanya',
      body:
          'Semua angka dijelaskan: skala AQI 0–500, batas aman tiap polutan, dan status aktivitas (aman/waspada/hindari). Tarik ke bawah untuk refresh data.',
    ),
    (
      icon: Icons.explore_outlined,
      colors: [Color(0xFFA78BFA), Color(0xFFF472B6)],
      title: 'Tur fitur',
      body: '5 tab di bawah — semua ada gunanya:',
    ),
  ];

  void _next() {
    if (_index < _slides.length - 1) {
      _page.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      widget.onDone();
    }
  }

  static const _fitur = [
    (Icons.home, 'Beranda', 'udara lu sekarang'),
    (Icons.show_chart, 'Prakiraan', 'udara bakal buruk atau enggak'),
    (Icons.map, 'Peta', 'udara kota-kota lain'),
    (Icons.favorite, 'Favorit', 'pantau kota penting buat lu'),
    (Icons.school, 'Edukasi', 'cara ngelindungin diri'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Lewati',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  final isTour = i == _slides.length - 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isTour) ...[
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: s.colors,
                              ),
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: Icon(s.icon, color: Colors.white, size: 56),
                          ),
                        ] else ...[
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: s.colors,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(s.icon, color: Colors.white, size: 36),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(s.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        if (!isTour)
                          Text(s.body,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 14.5,
                                  height: 1.5))
                        else
                          Text(s.body,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 13.5,
                                  height: 1.4)),
                        if (isTour) ...[
                          const SizedBox(height: 14),
                          for (final f in _fitur)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(f.$1,
                                        color: const Color(0xFF34D399),
                                        size: 17),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(f.$2,
                                      style: const TextStyle(
                                          color: Color(0xFFE2E8F0),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(f.$3,
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.5),
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
              child: Row(
                children: [
                  // Indikator titik.
                  for (var i = 0; i < _slides.length; i++)
                    Container(
                      width: i == _index ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == _index
                            ? const Color(0xFF34D399)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 14)),
                    child: Text(
                        _index == _slides.length - 1 ? 'Mulai' : 'Lanjut'),
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
