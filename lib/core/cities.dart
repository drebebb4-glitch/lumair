/// 20 kota besar Indonesia — sumber fitur "Semua Daerah".
/// Koordinat: pusat kota (presisi 2 desimal cukup untuk AQI model 11km).
class IdCity {
  final String name;
  final double lat;
  final double lon;
  const IdCity({required this.name, required this.lat, required this.lon});
}

const idCities = [
  IdCity(name: 'Jakarta', lat: -6.2, lon: 106.82),
  IdCity(name: 'Bekasi', lat: -6.24, lon: 106.98),
  IdCity(name: 'Bandung', lat: -6.92, lon: 107.62),
  IdCity(name: 'Semarang', lat: -6.97, lon: 110.42),
  IdCity(name: 'Yogyakarta', lat: -7.8, lon: 110.37),
  IdCity(name: 'Solo', lat: -7.58, lon: 110.82),
  IdCity(name: 'Surabaya', lat: -7.26, lon: 112.75),
  IdCity(name: 'Malang', lat: -7.97, lon: 112.63),
  IdCity(name: 'Denpasar', lat: -8.67, lon: 115.21),
  IdCity(name: 'Medan', lat: 3.6, lon: 98.67),
  IdCity(name: 'Padang', lat: -0.95, lon: 100.42),
  IdCity(name: 'Pekanbaru', lat: 0.51, lon: 101.45),
  IdCity(name: 'Palembang', lat: -2.99, lon: 104.76),
  IdCity(name: 'Bandar Lampung', lat: -5.43, lon: 105.26),
  IdCity(name: 'Pontianak', lat: -0.02, lon: 109.34),
  IdCity(name: 'Banjarmasin', lat: -3.32, lon: 114.59),
  IdCity(name: 'Balikpapan', lat: -1.27, lon: 116.83),
  IdCity(name: 'Makassar', lat: -5.15, lon: 119.43),
  IdCity(name: 'Manado', lat: 1.47, lon: 124.84),
  IdCity(name: 'Jayapura', lat: -2.53, lon: 140.72),
];
