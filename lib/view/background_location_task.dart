import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location/location.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  final Location _location = Location();

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print('Foreground task started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      final locData = await _location.getLocation();

      if (locData.latitude == null || locData.longitude == null) {
        print('Location is null');
        return;
      }

      final point = ll.LatLng(locData.latitude!, locData.longitude!);

      print('Location: ${point.latitude}, ${point.longitude}');

      sendPort?.send({
        'lat': point.latitude,
        'lng': point.longitude,
        'time': timestamp.toIso8601String(),
      });
    } catch (e, s) {
      print('LocationTaskHandler error: $e');
      print(s);
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    print('Foreground task destroyed at $timestamp');
  }

  @override
  void onButtonPressed(String id) {
    print('Notification button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}