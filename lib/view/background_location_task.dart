import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart' as ll;

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  final Location _location = Location();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {

  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      final locData = await _location.getLocation();
      if (locData.latitude == null || locData.longitude == null) return;

      final point = ll.LatLng(locData.latitude!, locData.longitude!);

      sendPort?.send({
        'lat': point.latitude,
        'lng': point.longitude,
        'time': timestamp.toIso8601String(),
      });
    } catch (e) {

    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {

  }

  @override
  void onButtonPressed(String id) {

  }

  @override
  void onNotificationPressed() {

  }
}
