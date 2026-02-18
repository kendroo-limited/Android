import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
@pragma('vm:entry-point')
class BackgroundJourneyService {
  static Future<void> start({
    required String baseUrl,
    required String cookie,
    required int uid,
  }) async {
    final service = FlutterBackgroundService();


    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'journey_tracking',
      'Journey Tracking Service',
      description: 'This channel is used for journey tracking features.',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);


    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,

        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: 'journey_tracking',
        initialNotificationTitle: 'Journey Tracking',
        initialNotificationContent: 'Location tracking active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );

    await service.startService();

    service.invoke('setData', {

      'baseUrl': baseUrl,

      'cookie': cookie,

      'uid': uid,

    });

  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    final location = Location();
    String? baseUrl;
    String? cookie;
    int? uid;

    service.on('setData').listen((event) {
      baseUrl = event?['baseUrl'];
      cookie = event?['cookie'];
      uid = event?['uid'];
    });

    service.on('stopService').listen((_) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(minutes: 15), (_) async {
      if (baseUrl == null || cookie == null || uid == null) return;

      try {
        final data = await location.getLocation();
        if (data.latitude == null || data.longitude == null) return;

        final payload = {
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "kio.field.force",
            "method": "check_in_create_or_update",
            "args": [],
            "kwargs": {
              "uid": uid,
              "latitude": data.latitude,
              "longitude": data.longitude,
            }
          },
          "id": DateTime.now().millisecondsSinceEpoch,
        };

        await http.post(
          Uri.parse('$baseUrl/web/dataset/call_kw'),
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookie!,
          },
          body: jsonEncode(payload),
        );
      } catch (_) {

      }
    });
  }
}


