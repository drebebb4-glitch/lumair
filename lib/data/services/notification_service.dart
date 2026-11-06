import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Pembungkus flutter_local_notifications. Semua pemanggilan plugin ada di
/// sini, jadi kalau API paket berubah cukup perbaiki satu file ini.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'lumair_aqi_alerts';
  static const _channelName = 'Peringatan kualitas udara';
  static const _channelDesc =
      'Peringatan dini saat kualitas udara memburuk di lokasi kamu.';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    _inited = true;
  }

  /// Android 13+ butuh izin runtime POST_NOTIFICATIONS.
  /// Mengembalikan true bila notifikasi boleh tampil.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> show({
    required String placeKey,
    required String title,
    required String body,
    Color? color,
  }) async {
    await init();
    await _plugin.show(
      id: _idFor(placeKey),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: color,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  /// ID stabil per lokasi: peringatan baru menggantikan yang lama,
  /// bukan menumpuk. (hashCode String tidak dijamin stabil → hash manual.)
  int _idFor(String key) {
    var h = 17;
    for (final c in key.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return h;
  }
}
