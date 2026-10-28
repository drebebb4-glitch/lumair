import 'package:flutter/material.dart';

class _Article {
  final String title;
  final String icon;
  final String body;
  const _Article(
      {required this.title, required this.icon, required this.body});
}

const _articles = [
  _Article(
    title: 'Apa itu PM2.5?',
    icon: '🌫️',
    body:
        'PM2.5 adalah partikel udara berdiameter <2,5 mikrometer — 30x lebih tipis dari rambut. Sumber utama di kota: knalpot, bakar sampah, dan industri. Karena sangat kecil, ia menembus hingga alveoli paru dan masuk aliran darah. WHO menetapkan batas aman rata-rata tahunan 5 µg/m³.',
  ),
  _Article(
    title: 'Membaca angka AQI',
    icon: '📊',
    body:
        'US AQI 0–500. 0–50 Baik (hijau), 51–100 Sedang (kuning), 101–150 Sensitif (orange), 151–200 Tidak Sehat (merah), 201–300 Sangat Tidak Sehat (ungu), 300+ Berbahaya (maroon). LUMAIR memakai standar ini agar sebanding dengan aplikasi global.',
  ),
  _Article(
    title: 'Masker yang benar',
    icon: '😷',
    body:
        'Saat AQI >100, pakai masker N95/KN95 — masker kain & bedah tidak menyaring PM2.5. Pastikan rapat di hidung, ganti tiap 8 jam pemakaian atau saat lembap. Anak & lansia prioritas utama.',
  ),
  _Article(
    title: 'Olahraga saat polusi',
    icon: '🏃',
    body:
        'AQI <100: aman outdoor. 101–150: persingkat durasi, hindari jam 10–16 (ozon puncak). >150: pindah indoor. Atlet menghirup 10–20x udara lebih banyak — risikonya berlipat saat polusi.',
  ),
  _Article(
    title: 'Anak & penderita asma',
    icon: '🧒',
    body:
        'Kelompok sensitif bereaksi mulai AQI 101. Siapkan inhaler, tutup jendela saat AQI tinggi, nyalakan purifier bila ada. Sekolah: pindahkan istirahat ke dalam ruangan saat AQI >150.',
  ),
  _Article(
    title: 'Sumber polusi kota',
    icon: '🏭',
    body:
        'Tiga sumber terbesar udara kota Indonesia: transportasi (40–60%), pembakaran terbuka & rumah tangga, serta industri/PLTU. Musim kemarau + angin tenang membuat polutan terperangkap — itulah kenapa AQI memburuk berhari-hari.',
  ),
];

/// Edukasi statis (PRD P0).
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edukasi Udara')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (context, i) {
          final a = _articles[i];
          return Card(
            child: ListTile(
              leading: Text(a.icon, style: const TextStyle(fontSize: 28)),
              title: Text(a.title),
              subtitle: Text(a.body,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _ArticleDetail(article: a)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArticleDetail extends StatelessWidget {
  final _Article article;
  const _ArticleDetail({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(article.icon, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(article.title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(article.body,
              style: const TextStyle(fontSize: 16, height: 1.6)),
        ],
      ),
    );
  }
}
