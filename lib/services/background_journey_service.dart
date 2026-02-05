import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class BackgroundJourneyService {
  static Future<void> start({
    required String baseUrl,
    required String cookie,
    required int uid,
  }) async {
    final service = FlutterBackgroundService();

    // --- ADD THIS BLOCK ---
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    // Define the channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'journey_tracking', // Must match notificationChannelId below
      'Journey Tracking Service',
      description: 'This channel is used for journey tracking features.',
      importance: Importance.low, // low importance = no sound/interruption
    );

    // Create the channel on the device
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    // ----------------------

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: 'journey_tracking', // Matches the channel above
        initialNotificationTitle: 'Journey Tracking',
        initialNotificationContent: 'Location tracking active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );

    await service.startService();
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

  static void _onStart(ServiceInstance service) async {
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
        // silent fail – background safe
      }
    });
  }
}


