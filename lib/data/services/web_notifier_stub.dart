// Stub untuk platform non-web (Android/iOS/desktop/test).
// Dipilih otomatis lewat conditional import di notification_service.dart.

bool webNotificationsSupported() => false;

Future<bool> requestWebNotificationPermission() async => false;

bool showWebNotification({
  required String title,
  required String body,
  required String tag,
}) =>
    false;
