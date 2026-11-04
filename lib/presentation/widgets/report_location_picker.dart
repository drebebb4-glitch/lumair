import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Future<LatLng?> pickReportLocation(
  BuildContext context, {
  required LatLng initialLocation,
}) {
  return showModalBottomSheet<LatLng>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1220),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReportLocationPicker(initialLocation: initialLocation),
  );
}

class _ReportLocationPicker extends StatefulWidget {
  const _ReportLocationPicker({required this.initialLocation});

  final LatLng initialLocation;

  @override
  State<_ReportLocationPicker> createState() => _ReportLocationPickerState();
}

class _ReportLocationPickerState extends State<_ReportLocationPicker> {
  late LatLng _selected = widget.initialLocation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: SizedBox(
        height: (size.height * 0.78).clamp(360.0, 720.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih titik laporan',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Geser peta lalu ketuk lokasi kejadian.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.initialLocation,
                          initialZoom: 14,
                          onTap: (_, point) =>
                              setState(() => _selected = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.hartono.lumair',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selected,
                                width: 48,
                                height: 48,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color(0xFF34D399),
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1220)
                                .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: TextStyle(
                                  color: Color(0xFFE2E8F0), fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_selected.latitude.toStringAsFixed(5)}, '
                '${_selected.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  icon: const Icon(Icons.check),
                  label: const Text('Gunakan titik ini'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
