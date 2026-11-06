// Notifikasi browser (Notification API) untuk versi web LUMAIR.
// Dipilih otomatis lewat conditional import di notification_service.dart.
//
// Catatan: notifikasi web hanya muncul saat tab aplikasi masih terbuka
// dan butuh konteks aman (HTTPS atau localhost).
import 'dart:js_interop';

@JS('Notification')
extension type JsNotification._(JSObject _) implements JSObject {
  external factory JsNotification(String title, JsNotificationOptions options);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
}

extension type JsNotificationOptions._(JSObject _) implements JSObject {
  external factory JsNotificationOptions({String body, String tag});
}

bool webNotificationsSupported() {
  try {
    return JsNotification.permission.isNotEmpty;
  } catch (_) {
    return false; // browser tidak punya Notification API
  }
}

/// Harus dipanggil dari aksi pengguna (mis. mengetuk tombol/saklar).
Future<bool> requestWebNotificationPermission() async {
  try {
    final result = await JsNotification.requestPermission().toDart;
    return result.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

bool showWebNotification({
  required String title,
  required String body,
  required String tag,
}) {
  try {
    if (JsNotification.permission != 'granted') return false;
    JsNotification(title, JsNotificationOptions(body: body, tag: tag));
    return true;
  } catch (_) {
    return false;
  }
}