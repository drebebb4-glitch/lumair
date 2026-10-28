import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../core/app_theme.dart';
import '../../domain/providers.dart';
import '../widgets/glass.dart';
import '../widgets/activity_card.dart';

class _Article {
  final String title;
  final String kicker;
  final String teaser;
  final String image;
  final String credit;
  final List<String> body;
  const _Article({
    required this.title,
    required this.kicker,
    required this.teaser,
    required this.image,
    required this.credit,
    required this.body,
  });
}

/// Foto dokumentasi nyata (Wikimedia Commons) — biar terasa seperti berita,
/// bukan stok clip-art. Kredit tercantum di footer artikel detail.
const _articles = [
  _Article(
    kicker: 'PARTIKULAT',
    title: 'PM2.5: Musuh Halus yang Menembus Paru',
    teaser:
        'Seribu kali lebih tipis dari milimeter — cukup untuk melewati pertahanan tubuh dan masuk ke dalam darah.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Delhi_air_pollution_2019.jpg/1280px-Delhi_air_pollution_2019.jpg',
    credit: 'Prami.ap90, CC BY-SA 4.0 — Wikimedia Commons',
    body: [
      'Di kota-kota besar Indonesia, musim kemarau sering membawa langit keruh seperti pada foto di atas. Yang membuatnya berbahaya bukan sekadar tampaknya, melainkan partikel yang melayang di dalamnya — terutama PM2.5, partikel berdiameter di bawah 2,5 mikrometer. Bandingkan: satu helai rambut manusia berdiameter sekitar 70 mikrometer. PM2.5 lebih tipis tiga puluh kali lipat.',
      'Ukuran sekecil itu mengubah segalanya. Saat kita menarik napas, pertahanan alami di hidung dan tenggorokan mampu menyaring partikel kasar, tetapi PM2.5 lolos melewatinya — hingga jauh ke dalam alveoli paru, lalu masuk ke aliran darah. Di dalam tubuh, partikel ini dikaitkan dengan risiko asma, penyakit jantung, stroke, hingga gangguan pernapasan pada anak-anak.',
      'Sumber utamanya ada di sekitar kita: asap knalpot kendaraan, pembakaran sampah di sore hari, asap rokok, dan emisi industri. Karena tidak terlihat mata, satu-satunya cara memantau adalah lewat angka — itulah fungsi pengukur kualitas udara dan aplikasi seperti LUMAIR.',
      'Organisasi Kesehatan Dunia (WHO) menetapkan batas aman rata-rata tahunan PM2.5 sebesar 5 mikrogram per meter kubik — sebagian besar kota Indonesia melampaui angka itu setiap hari. Memahami angka ini adalah langkah pertama sebelum melangkah ke cara melindungi diri di artikel berikutnya.',
    ],
  ),
  _Article(
    kicker: 'SKALA',
    title: 'Panduan Membaca Angka AQI',
    teaser:
        'Satu angka, enam warna, dan arti pentingnya untuk keputusan harianmu — dari jendela tetap tertutup hingga batalnya olahraga pagi.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/67/Air_Monitoring_station%2C_Reno%2C_Nevada.jpg/1280px-Air_Monitoring_station%2C_Reno%2C_Nevada.jpg',
    credit: 'brewbooks, CC BY-SA 2.0 — Wikimedia Commons',
    body: [
      'Alat di foto di atas adalah salah satu stasiun pemantauan kualitas udara yang bekerja tanpa henti, dua puluh empat jam sehari. Datanya kemudian dirangkum menjadi satu angka yang mudah dibaca: Indeks Kualitas Udara, atau AQI.',
      'Skala US AQI yang dipakai LUMAIR berjalan dari 0 sampai 500, terbagi dalam enam kategori: hijau (0–50, baik), kuning (51–100, sedang), oranye (101–150, tidak sehat untuk kelompok sensitif), merah (151–200, tidak sehat), ungu (201–300, sangat tidak sehat), dan maroon (300+, berbahaya).',
      'Cara membacanya sederhana: semakin tinggi angkanya, semakin banyak orang yang perlu beradaptasi. Di zona hijau dan kuning, aktivitas berjalan seperti biasa. Masuk zona oranye, anak-anak, lansia, dan penderita penyakit pernapasan mulai perlu berhati-hati. Zona merah ke atas, proteksi seperti masker N95 dan membatasi aktivitas di luar ruangan menjadi kebutuhan, bukan pilihan.',
      'LUMAIR memakai standar AS ini agar datanya sebanding dengan aplikasi global dan catatan riset internasional — sehingga angka yang kamu lihat pagi ini bisa langsung dibandingkan dengan kota mana pun di dunia.',
    ],
  ),
  _Article(
    kicker: 'PROTEKSI',
    title: 'Masker Kain Tidak Cukup: Kapan Perlu N95',
    teaser:
        'Sembilan puluh lima persen partikel tersaring — angka yang membedakan masker yang bekerja dengan yang sekadar menghangatkan wajah.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/92/3M_9132_N95_Mask.jpg/1280px-3M_9132_N95_Mask.jpg',
    credit: 'ASHillocks, CC BY-SA 4.0 — Wikimedia Commons',
    body: [
      'Ketika AQI menembus angka 100, pertanyaannya bukan lagi "pakai masker atau tidak", melainkan "masker apa yang benar". Jawabannya tercetak di kemasan pada foto di atas: respirator berlabel N95 atau KN95. Tanda N95 berarti masker menyaring setidaknya 95 persen partikel sangat halus — termasuk PM2.5 yang disinggung di artikel pertama.',
      'Di sisi lain, masker kain dan masker bedah dirancang untuk tujuan berbeda: menahan percikan dan tetesan besar, bukan partikel mikroskopis. PM2.5 melayang melewatinya dengan mudah, sehingga saat polusi memuncak, masker jenis itu memberi rasa aman tanpa perlindungan nyata.',
      'Yang sama pentingnya dengan memilih masker adalah cara memakainya. Pastikan bagian hidung menempel rapat — celah sedikit saja di sisi masker sudah membuat udara kotor dapat tersedot masuk. Ganti masker setiap delapan jam pemakaian, atau lebih cepat bila ia menjadi lembap atau rusak bentuknya.',
      'Prioritas perlindungan tertinggi ada pada anak-anak, lansia, dan penderita penyakit pernapasan kronis — kelompok yang paling cepat terdampak saat kualitas udara memburuk.',
    ],
  ),
  _Article(
    kicker: 'AKTIVITAS',
    title: 'Olahraga di Hari Polusi: Kapan Boleh, Kapan Harus Berhenti',
    teaser:
        'Berlari memang menyehatkan, tetapi di udara kotor justru bisa jadi dua kali lebih berisiko. Inilah ambangnya.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/75/Morning_Jogging_%28197426589%29.jpeg/1280px-Morning_Jogging_%28197426589%29.jpeg',
    credit: 'Wikimedia Commons, CC BY 3.0',
    body: [
      'Tubuh yang berlari menuntut lebih banyak udara. Pada napas biasa, orang dewasa menghirup sekitar enam liter per menit; saat berlari berat, angkanya melonjak sampai seratus liter. Itulah sebabnya berolahraga di udara yang sama bisa berarti menghirup sepuluh hingga dua puluh kali lebih banyak polutan daripada orang yang duduk diam — semakin jauh melangkah, semakin besar dosanya.',
      'Aturannya bisa disederhanakan. AQI di bawah 100: aman untuk olahraga di luar ruangan. 101–150: tetap bisa jalan, tetapi persingkat durasinya dan hindari rentang pukul 10 hingga 16, ketika ozon permukaan biasanya mencapai puncaknya. Di atas 150: pindahkan latihan ke dalam ruangan sampai udara membaik.',
      'Perhatikan juga waktunya. Pagi dini hari sering menjadi jendela terbaik saat polusi sedang naik, sisi terjauh dari jam sibuk. Dan sebelum lari, sekali cek angka AQI di layar lebih tahu kondisi udara daripada menebak dari warna langit — hari yang terlihat cerah bisa saja menyimpan PM2.5 di atas batas aman.',
    ],
  ),
  _Article(
    kicker: 'KELOMPOK RENTAN',
    title: 'Anak dan Penderita Asma: Lindungi yang Paling Rentan',
    teaser:
        'Paru yang masih kecil menarik udara lebih cepat, dan nyawa yang bergantung pada satu inhaler tak boleh menebak-nebak.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/da/Treating_Kids_with_Asthma_%285%29_%287163885241%29.jpg/1280px-Treating_Kids_with_Asthma_%285%29_%287163885241%29.jpg',
    credit: 'Foto FDA — Domain Publik, via Wikimedia Commons',
    body: [
      'Anak-anak bernapas lebih cepat daripada orang dewasa dalam proporsi tubuhnya, dan paru mereka yang masih dalam tahap pertumbuhan lebih mudah teriritasi. Yang pada orang dewasa mungkin tak terasa, pada anak bisa memicu batuk berkepanjangan, sesak napas, atau serangan asma. Penderita asma mulai bereaksi bahkan lebih awal — di zona oranye, mulai dari AQI 101.',
      'Kesiapan adalah kata kuncinya. Untuk penderita asma: selalu sediakan inhaler atau obat pencair di tempat mudah dijangkau, dan mulai tutup jendela rumah ketika AQI naik. Bila tersedia, purifier udara akan membantu menurunkan tingkatan partikel di dalam ruangan.',
      'Bagi sekolah dan orang tua, kebijakan sederhana berpengaruh besar: saat AQI melewati 150, pindahkan jam istirahat dan olahraga ke dalam ruangan. Anak tidak merasa dihukum — mereka hanya butuh lingkungan yang sama aman seperti yang orang dewasa harapkan untuk dirinya sendiri.',
    ],
  ),
  _Article(
    kicker: 'SUMBER EMISI',
    title: 'Dari Mana Asal Polusi di Kotamu',
    teaser:
        'Di hampir semua kota besar Indonesia, penyumbang terbesar udara kotor bukan pabrik — melainkan kendaraan yang berbaris setiap hari.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0f/Traffic_jam_in_Kuningan%2C_Jakarta%2C_Indonesia.jpg/1280px-Traffic_jam_in_Kuningan%2C_Jakarta%2C_Indonesia.jpg',
    credit: 'Serenity, CC BY-SA 3.0 — Wikimedia Commons',
    body: [
      'Foto di atas adalah pemandangan harian macet di ibu kota — dan juga wajah paling nyata dari sumber polusi kota. Studi di sejumlah kota Indonesia menempatkan transportasi sebagai penyumbang terbesar, sekitar 40 hingga 60 persen emisi partikulat dan gas nitrogen. Setiap kali mesin menyala dan knalpot mengeluarkan asap, sisa pembakarannya ikut masuk ke udara yang kita hirup.',
      'Dua penyumbang berikutnya menyusul di belakangnya: pembakaran terbuka — sampah yang dibakar terbuka di musim kemarau, ladang yang dibersihkan dengan cara dibakar setelah panen — serta aktivitas industri dan pembangkit listrik batubara di pinggiran kota.',
      'Yang membuat polusi semakin terasa adalah kondisi cuaca. Saat kemarau panjang bertemu dengan angin yang tenang, udara kotor terperangkap dekat permukaan tanah tanpa dorongan untuk pergi. Inilah mengapa AQI di banyak kota tidak memburuk sejam-hari semalam, tetapi menumpuk bertahap — lalu bertahan buruk berhari-hari sampai hujan akhirnya datang.',
      'Kabar baiknya: semuanya ini terukur, dan yang terukur bisa ditindaklanjuti. Karena itu data udara harian — termasuk dari aplikasi ini — berguna bukan sekadar sebagai peringatan, tetapi sebagai dasar keputusan, baik untuk menyesuaikan jadwal, memilih rute, maupun menekan penggunaan kendaraan privat di hari-hari terburuk.',
    ],
  ),
];

/// Edukasi statis (PRD P0) + kartu live yang nyambung ke AQI user.
class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqi = ref.watch(aqiProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const ScreenTitle(
          title: 'Edukasi Udara',
          purpose: 'Kenapa udara kotor bahaya & cara ngelindungin diri',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Kartu live: konteks AQI user saat ini ──
          aqi.maybeWhen(
            data: (r) {
              final c = AqiHelper.color(r.usAqi);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UDARA LU SEKARANG',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('${r.usAqi}',
                              style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: c,
                                  height: 1.0)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                '${AqiHelper.category(r.usAqi)} • ${r.placeName}',
                                style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ActivityCard(aqi: r.usAqi),
                      const SizedBox(height: 6),
                      Text(
                          'Penjelasan lengkap skala & batas aman ada di artikel bawah.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11.5)),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 10, 2, 10),
            child: Text('ARTIKEL PILIHAN',
                style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4)),
          ),
          // ── 6 artikel (PRD), bergaya berita dengan foto ──
          for (final a in _articles) _ArticleCard(article: a),
          const SizedBox(height: 8),
          Text(
            'Foto dokumentasi dari Wikimedia Commons, digunakan sesuai lisensinya masing-masing.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Kartu artikel bergaya berita: foto di atas, judul + teaser di bawah.
class _ArticleCard extends StatelessWidget {
  final _Article article;
  const _ArticleCard({required this.article});

  static const _headers = {
    'User-Agent': 'LumairApp/1.0 (educational; contact dev@lumair.id)',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => _ArticleDetail(article: article)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ArticleImage(image: article.image),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.kicker,
                        style: const TextStyle(
                            color: AppTheme.emerald,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6)),
                    const SizedBox(height: 6),
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                    const SizedBox(height: 6),
                    Text(article.teaser,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12.5,
                            height: 1.45),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Baca selengkapnya',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 18, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder + fade-in untuk foto artikel.
class _ArticleImage extends StatelessWidget {
  final String image;
  const _ArticleImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        image,
        fit: BoxFit.cover,
        headers: _ArticleCard._headers,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12203A), Color(0xFF0B1220)],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined,
            color: Color(0xFF334155), size: 40),
      );
}

class _ArticleDetail extends StatelessWidget {
  final _Article article;
  const _ArticleDetail({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.kicker)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                article.image,
                fit: BoxFit.cover,
                headers: _ArticleCard._headers,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF0B1220)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(article.credit,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          const SizedBox(height: 14),
          Text(article.title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 6),
          Text(article.teaser,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w500)),
          const Divider(color: Color(0xFF1E293B), height: 32),
          for (final p in article.body) ...[
            Text(p,
                style: const TextStyle(
                    fontSize: 15, height: 1.75, color: Color(0xFFCBD5E1))),
            const SizedBox(height: 14),
          ],
          const GlassChip(
            icon: Icons.school_outlined,
            label: 'Edukasi LUMAIR',
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
