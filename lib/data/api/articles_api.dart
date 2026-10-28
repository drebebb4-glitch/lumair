import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Artikel edukasi LUMAIR — hidup dari JSON di repo:
/// https://github.com/drebebb4-glitch/lumair/blob/main/content/articles.json
///
/// Rantai pengambilan: remote terbaru → cache SharedPreferences → bawaan
/// ([builtInArticles]). Berarti offline / repo rusak tetap tampil, gak kosong.
class Article {
  final String kicker;
  final String title;
  final String teaser;
  final String image;
  final String credit;
  final List<String> body;
  const Article({
    required this.kicker,
    required this.title,
    required this.teaser,
    required this.image,
    required this.credit,
    required this.body,
  });
}

class ArticlesResult {
  final List<Article> articles;
  final DateTime? lastModified;
  final bool fromRemote;
  const ArticlesResult({
    required this.articles,
    this.lastModified,
    required this.fromRemote,
  });
}

class ArticlesApi {
  static const _url =
      'https://raw.githubusercontent.com/drebebb4-glitch/lumair/main/content/articles.json';
  static const _cacheKey = 'lumair_articles_cache';
  static const _updatedKey = 'lumair_articles_updated';
  static const _headers = {
    'User-Agent': 'LumairApp/1.0 (educational; contact dev@lumair.id)',
  };

  final http.Client _client;
  ArticlesApi({http.Client? client}) : _client = client ?? http.Client();

  /// Coba remote dulu; gagal → cache; cache kosong → bawaan.
  Future<ArticlesResult> load() async {
    // 1) Remote
    try {
      final res = await _client
          .get(Uri.parse(_url), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final result = _parse(res.body);
        if (result != null) {
          // Catat waktu terakhir file berubah (header dari raw.githubusercontent).
          final lm =
              DateTime.tryParse(res.headers['last-modified'] ?? '')?.toUtc();
          await _saveCache(res.body, lm);
          return ArticlesResult(
            articles: result,
            lastModified: lm,
            fromRemote: true,
          );
        }
      }
    } catch (_) {}

    // 2) Cache
    final cached = await _loadCache();
    if (cached != null) return cached;

    // 3) Bawaan (dibundel di kode) — selalu ada.
    return const ArticlesResult(articles: builtInArticles, fromRemote: false);
  }

  static List<Article>? _parse(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final list = (json['articles'] as List?) ?? const [];
      final arts = list
          .map((m) {
            m as Map<String, dynamic>;
            final body =
                (m['body'] as List?)?.map((e) => '$e').toList() ?? const [];
            return Article(
              kicker: '${m['kicker'] ?? ''}',
              title: '${m['title'] ?? ''}',
              teaser: '${m['teaser'] ?? ''}',
              image: '${m['image'] ?? ''}',
              credit: '${m['credit'] ?? ''}',
              body: List<String>.from(body),
            );
          })
          .where((a) => a.title.isNotEmpty && a.image.isNotEmpty)
          .toList();
      return arts.isNotEmpty ? arts : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(String raw, DateTime? lm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, raw);
      if (lm != null) {
        await prefs.setString(_updatedKey, lm.toIso8601String());
      }
    } catch (_) {}
  }

  Future<ArticlesResult?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final arts = _parse(raw);
      if (arts == null) return null;
      return ArticlesResult(
        articles: arts,
        lastModified: DateTime.tryParse(prefs.getString(_updatedKey) ?? ''),
        fromRemote: false,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Bawaan mingguan — dipakai hanya sebelum ever fetch sukses dan offline.
const builtInArticles = [
  Article(
    kicker: 'PARTIKULAT',
    title: 'PM2.5: Musuh Halus yang Menembus Paru',
    teaser:
        'Seribu kali lebih tipis dari milimeter — cukup untuk melewati pertahanan tubuh dan masuk ke dalam darah.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Delhi_air_pollution_2019.jpg/1280px-Delhi_air_pollution_2019.jpg',
    credit: 'Prami.ap90, CC BY-SA 4.0 — Wikimedia Commons',
    body: [
      'Di kota-kota besar Indonesia, musim kemarau sering membawa langit keruh. Yang membuatnya berbahaya bukan sekadar tampaknya, melainkan partikel yang melayang di dalamnya — terutama PM2.5, partikel berdiameter di bawah 2,5 mikrometer: lebih tipis tiga puluh kali dari helai rambut.',
      'Ukuran sekecil itu membuat PM2.5 lolos dari pertahanan hidung hingga masuk ke alveoli paru dan aliran darah — dikaitkan dengan asma, penyakit jantung, dan stroke. Sumber utamanya: asap knalpot, pembakaran sampah, asap rokok, dan emisi industri.',
      'Karena tak terlihat mata, satu-satunya cara memantau adalah lewat angka. WHO menetapkan batas aman rata-rata tahunan PM2.5 sebesar 5 mikrogram per meter kubik — sebagian besar kota Indonesia melampauinya setiap hari.',
    ],
  ),
  Article(
    kicker: 'SKALA',
    title: 'Panduan Membaca Angka AQI',
    teaser:
        'Satu angka, enam warna, dan arti pentingnya untuk keputusan harianmu.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/67/Air_Monitoring_station%2C_Reno%2C_Nevada.jpg/1280px-Air_Monitoring_station%2C_Reno%2C_Nevada.jpg',
    credit: 'brewbooks, CC BY-SA 2.0 — Wikimedia Commons',
    body: [
      'AQI dirangkum dari data stasiun pemantauan yang bekerja 24 jam. Skala US AQI 0–500: hijau (baik), kuning (sedang), oranye (sensitif), merah (tidak sehat), ungu (sangat tidak sehat), maroon (berbahaya).',
      'Semakin tinggi angkanya, semakin banyak orang yang perlu beradaptasi: zona oranye memicu kewaspadaan anak, lansia, dan penderita asma; zona merah ke atas menjadikan masker N95 dan pembatasan keluar rumah sebagai kebutuhan.',
      'LUMAIR memakai standar AS agar datanya sebanding dengan aplikasi global — angka pagi ini bisa dibandingkan dengan kota mana pun di dunia.',
    ],
  ),
  Article(
    kicker: 'PROTEKSI',
    title: 'Masker Kain Tidak Cukup: Kapan Perlu N95',
    teaser:
        'Sembilan puluh lima persen partikel tersaring — itulah bedanya proteksi nyata dan rasa aman semata.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/92/3M_9132_N95_Mask.jpg/1280px-3M_9132_N95_Mask.jpg',
    credit: 'ASHillocks, CC BY-SA 4.0 — Wikimedia Commons',
    body: [
      'Saat AQI melewati 100, gunakan respirator N95/KN95 — namanya berarti menyaring setidaknya 95 persen partikel sangat halus, termasuk PM2.5. Masker kain dan bedah tidak menyaring partikel mikroskopis.',
      'Pastikan rapat di hidung — celah kecil membuat udara kotor tersedot masuk. Ganti tiap 8 jam pemakaian atau saat lembap.',
      'Prioritas perlindungan tertinggi: anak, lansia, dan penderita penyakit pernapasan kronis.',
    ],
  ),
  Article(
    kicker: 'AKTIVITAS',
    title: 'Olahraga di Hari Polusi: Kapan Boleh, Kapan Harus Berhenti',
    teaser:
        'Di udara kotor, lari bisa berarti dua puluh kali lebih banyak polutan.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/75/Morning_Jogging_%28197426589%29.jpeg/1280px-Morning_Jogging_%28197426589%29.jpeg',
    credit: 'Wikimedia Commons, CC BY 3.0',
    body: [
      'Saat lari berat, tubuh menghirup sampai seratus liter udara per menit — belasan kali lebih banyak dari duduk. AQI <100 aman outdoor; 101–150 persingkat durasi dan hindari jam 10–16; >150 pindah indoor.',
      'Pagi dini hari biasanya jendela terbaik; cek angka AQI dulu sebelum berangkat — langit cerah tidak selalu berarti aman.',
    ],
  ),
  Article(
    kicker: 'KELOMPOK RENTAN',
    title: 'Anak dan Penderita Asma: Lindungi yang Paling Rentan',
    teaser:
        'Paru kecil menarik udara lebih cepat — dan menebak-nebak bukan opsi.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/da/Treating_Kids_with_Asthma_%285%29_%287163885241%29.jpg/1280px-Treating_Kids_with_Asthma_%285%29_%287163885241%29.jpg',
    credit: 'Foto FDA — Domain Publik, via Wikimedia Commons',
    body: [
      'Anak bernapas lebih cepat dalam proporsinya dan parunya sedang tumbuh — polusi yang tak terasa pada dewasa bisa memicu batuk berkepanjangan atau serangan asma. Penderita asma mulai bereaksi pada AQI 101.',
      'Siapkan inhaler, tutup jendela saat AQI naik, nyalakan purifier bila ada. Saat AQI >150, pindahkan istirahat dan olahraga sekolah ke dalam ruangan.',
    ],
  ),
  Article(
    kicker: 'SUMBER EMISI',
    title: 'Dari Mana Asal Polusi di Kotamu',
    teaser:
        'Penyumbang terbesar udara kota biasanya bukan pabrik — melainkan mesin kendaraan.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0f/Traffic_jam_in_Kuningan%2C_Jakarta%2C_Indonesia.jpg/1280px-Traffic_jam_in_Kuningan%2C_Jakarta%2C_Indonesia.jpg',
    credit: 'Serenity, CC BY-SA 3.0 — Wikimedia Commons',
    body: [
      'Transportasi menyumbang 40–60 persen emisi di kebanyakan kota besar Indonesia; dua penyumbang berikutnya: pembakaran terbuka dan industri/PLTU. Kemarau + angin tenang membuat polutan terperangkap bertahap, bukan sekali jadi.',
      'Yang terukur bisa ditindaklanjuti — itu sebabnya data udara harian berguna sebagai dasar keputusan, bukan cuma peringatan.',
    ],
  ),
  Article(
    kicker: 'INDOOR',
    title: 'Rumah Lebih Aman? Bisa — Kalau Dikelola Benar',
    teaser:
        'Udara dalam ruangan tidak otomatis bersih — masak, debu, dan VOC ikut menumpuk.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/05/Xiaomi_Smart_Air_Purifier_2S_fan.jpg/1280px-Xiaomi_Smart_Air_Purifier_2S_fan.jpg',
    credit: 'Wikimedia Commons, CC BY 2.0',
    body: [
      'Berlindung di rumah saat AQI memburuk memang tepat, tetapi udara dalam ruangan bisa mendekati udara luar karena memasak tanpa ventilasi, debu, dan asap rokok yang terakumulasi.',
      'Tiga kuncinya: ventilasi silang saat AQI luar zona hijau, exhaust fan saat memasak, dan purifier berfilter HEPA yang menyala terus di ruang utama.',
      'Jangan berharap dari pengharum ruangan — ia menutupi bau, bukan membersihkan udara; yang ditambahkannya justru senyawa baru.',
    ],
  ),
  Article(
    kicker: 'DATA',
    title: 'Sensor Murah Bisa Dipercaya? Seberapa Akurat Angkamu',
    teaser:
        'Sensor laser sekecil kancing — andal untuk tren, bukan untuk satu angka tunggal.',
    image:
        'https://upload.wikimedia.org/wikipedia/commons/a/a5/Real-time_Particulate_Matter_Sensor_%288118c90f-2657-48ca-8191-fc77de7a47cf%29.jpg',
    credit: 'Foto US EPA — Domain Publik',
    body: [
      'Sensor optik bekerja dengan laser dan fotodioda: partikel yang lewat memantulkan cahaya, dan dari frekuensi pantulan itulah PM2.5 dihitung.',
      'Kekuatannya di jumlah: data dari ribuan stasiun komunitas saling meniadakan kesalahan kecilnya, sehingga tren naik-turunnya hampir setara stasiun referensi.',
      'Kelemahannya: kelembapan tinggi membuat pembacaan terlalu tinggi, umur alat umumnya 2–3 tahun, dan tidak semua model memisahkan PM1.0/PM2.5/PM10. Rata-rata beberapa stasiun terdekat jauh lebih aman daripada satu angka tunggal.',
    ],
  ),
  Article(
    kicker: 'ATMOSFIR',
    title: 'Kenapa Polusi Bisa Kabur ke Langit Tapi Balik Lagi',
    teaser:
        'Lapisan udara hangat di atas kota itu seperti penutup panci: polutan terkurung di bawahnya.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/df/Smog_Layer_Over_Upstate_New_York_%2C_Image_of_the_Day_DVIDS695291.jpg/1280px-Smog_Layer_Over_Upstate_New_York_%2C_Image_of_the_Day_DVIDS695291.jpg',
    credit: 'Foto NASA/DVIDS — Domain Publik',
    body: [
      'Temperature inversion: udara hangat berada di atas udara dingin sehingga udara tidak bisa berputar naik — polutan terkurung di lapisan tipis dekat tanah, seperti uap dalam panci tertutup.',
      'Inversi terbentuk hampir setiap malam saat tanah mendingin — itulah sebabnya AQI sering paling buruk dini hari hingga pagi buta, lalu turun cepat begitu matahari memecah lapisannya.',
      'Di kemarau inversi lebih kuat dan minim hujan pembersih; itulah asal-usul musim polusi. Polusi tidak pernah hilang ke langit — ia menunggu cuaca yang tepat untuk pergi.',
    ],
  ),
  Article(
    kicker: 'CUACA',
    title: 'Hujan: Deterjen Alami Udara',
    teaser:
        'Butir hujan menangkap partikel yang melayang — udara dibersihkan dari atas.',
    image:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f9/Heavy_Rain_In_Cebu.jpg/1280px-Heavy_Rain_In_Cebu.jpg',
    credit: 'Wikimedia Commons — Domain Publik',
    body: [
      'Wet scavenging: tiap butir hujan menabrak jutaan partikel melayang dan membawanya turun ke tanah — pembersihan tanpa listrik dan tanpa filter ganti.',
      'Hujan deras dan lama menurunkan AQI puluhan angka dalam hitungan jam; gerimis tipis minim pengaruh karena butirnya terlalu sedikit.',
      'Batasnya: hujan membersihkan partikel, bukan gas, dan debu akan kembali melayang begitu jalan mengering. Karena itu udara membaik satu-dua hari setelah hujan, lalu naik lagi perlahan.',
    ],
  ),
];
