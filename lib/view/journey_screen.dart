import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';

import '../model/journey_model.dart';
import '../provider/auth_provider.dart';
import '../repo/odoo_json_rpc.dart';
import '../services/background_journey_service.dart';
import 'journey_map_screen.dart';

class JourneyProviderView extends ChangeNotifier {
  final loc.Location _location = loc.Location();

  bool isCheckedIn = false;
  String? startAddress;
  String? endAddress;
  Timer? _autoTimer;
  List<Map<String, dynamic>> historyRows = [];
  String locationStatus = 'Ready';
  bool isSaving = false;

  // Guard flag to prevent infinite loops in StatelessWidgets
  bool _hasFetchedInitial = false;

  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "https://demo.kendroo.com",
      sessionCookie: cookie,
    );
  }

  // Called by the UI
  void init(String cookie, int uid) {
    if (_hasFetchedInitial || isSaving) return;
    _hasFetchedInitial = true;
    fetchHistory(cookie, uid);
  }

  Future<ll.LatLng> _getLatLng() async {
    final data = await _location.getLocation();
    if (data.latitude == null || data.longitude == null) {
      throw Exception("GPS not found");
    }
    return ll.LatLng(data.latitude!, data.longitude!);
  }

  void startAutoUpdates(String cookie, int uid) {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _sendAutoLocationPing(cookie, uid);
    });
  }

  void stopAutoUpdates() {
    _autoTimer?.cancel();
    _autoTimer = null;
    notifyListeners();
  }

  Future<void> _sendAutoLocationPing(String cookie, int uid) async {
    try {
      final point = await _getLatLng();
      final address = await getAddressFromLatLng(point);
      await _rpc(cookie).checkInCreateOrUpdate(
        uid: uid,
        startLocation: address,
        latitude: point.latitude,
        longitude: point.longitude,
        journeyTime: DateTime.now(),
      );
      locationStatus = "Auto update sent ✅ (${DateTime.now().toLocal()})";
      notifyListeners();
    } catch (e) {
      locationStatus = "Auto update failed: $e";
      notifyListeners();
    }
  }

  Future<void> handleCheckInOut(String cookie, int uid) async {
    if (isSaving) return;

    isSaving = true;
    locationStatus = "Fetching GPS...";
    notifyListeners();

    try {
      final point = await _getLatLng();
      final address = await getAddressFromLatLng(point);
      final rpc = _rpc(cookie);

      if (!isCheckedIn) {
        await rpc.checkInCreateOrUpdate(
          uid: uid,
          startLocation: address,
          latitude: point.latitude,
          longitude: point.longitude,
          journeyTime: DateTime.now(),
        );
        startAddress = address;
        endAddress = null;
        isCheckedIn = true; // Set locally first for immediate UI response

        await BackgroundJourneyService.start(
          cookie: cookie,
          uid: uid,
          baseUrl: "https://demo.kendroo.com",
        );
        startAutoUpdates(cookie, uid);
        locationStatus = "Check-in saved ✅";
      } else {
        await rpc.fieldForceCheckOut(
          uid: uid,
          endLocation: address,
          latitude: point.latitude,
          longitude: point.longitude,
          journeyTime: DateTime.now(),
        );
        stopAutoUpdates();
        await BackgroundJourneyService.stop();

        endAddress = address;
        isCheckedIn = false; // Set locally first
        locationStatus = "Check-out saved ✅";
      }

      // Fetch history to update the list, but we keep our local isCheckedIn state
      await fetchHistory(cookie, uid, updateStatus: false);
    } catch (e) {
      locationStatus = "Error: $e";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory(String cookie, int uid, {bool updateStatus = true}) async {
    isSaving = true;
    notifyListeners();
    try {
      final rows = await _rpc(cookie).fetchLatestJourneyHistoryForUser(uid: uid);
      historyRows = rows;

      if (rows.isNotEmpty && updateStatus) {
        final latest = rows.first;
        final type = (latest['action'] ?? '').toString().toUpperCase();
        isCheckedIn = type.contains('IN');
        if (isCheckedIn) {
          startAddress = latest['location'];
          if (_autoTimer == null) startAutoUpdates(cookie, uid);
        }
      }
      locationStatus = rows.isEmpty ? "No history found." : "History loaded ✅";
    } catch (e) {
      locationStatus = "Server error: $e";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String> getAddressFromLatLng(ll.LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return "${p.name}, ${p.locality}, ${p.country}";
      }
    } catch (_) {}
    return "Unknown Address";
  }

  JourneyMapData buildMapDataFromHistory() {
    final rows = [...historyRows];
    rows.sort((a, b) {
      final ar = (a['journey_time'] as String?) ?? '';
      final br = (b['journey_time'] as String?) ?? '';
      try {
        return DateTime.parse(ar.replaceFirst(' ', 'T') + 'Z')
            .compareTo(DateTime.parse(br.replaceFirst(' ', 'T') + 'Z'));
      } catch (_) { return 0; }
    });

    final events = <JourneyMapEvent>[];
    for (final r in rows) {
      final lat = (r['latitude'] as num?)?.toDouble();
      final lng = (r['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final actionRaw = (r['action'] ?? r['type'] ?? '').toString().toUpperCase();
      events.add(JourneyMapEvent(
        type: actionRaw.contains('OUT') ? 'OUT' : (actionRaw.contains('AUTO') ? 'AUTO' : 'IN'),
        location: ll.LatLng(lat, lng),
        address: r['location'] ?? 'Unknown',
        time: DateTime.tryParse(r['journey_time'] ?? '') ?? DateTime.now(),
        isAuto: actionRaw.contains('AUTO'),
      ));
    }
    return JourneyMapData(
      events: events,
      startLocation: events.isNotEmpty ? events.first.location : null,
      endLocation: events.isNotEmpty ? events.last.location : null,
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read auth once
    final auth = context.read<AuthProvider>();
    // Watch journey for UI updates
    final journey = context.watch<JourneyProviderView>();

    // Safety check: trigger fetch only if not already done
    if (!journey.isSaving && journey.historyRows.isEmpty) {
      Future.microtask(() =>
          journey.init(auth.sessionCookie!, auth.user!.uid)
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Journey Tracker"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => journey.fetchHistory(auth.sessionCookie!, auth.user!.uid),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusCard(journey),
                      const SizedBox(height: 12),
                      Text(
                        journey.locationStatus,
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("History Logs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const Divider(),
                      _buildHistoryList(journey),
                    ],
                  ),
                ),
              ),
            ),

            // Map Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: journey.historyRows.isEmpty ? null : () {
                    final data = journey.buildMapDataFromHistory();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JourneyMapScreen(data: data)),
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text("VIEW MAP"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildBottomBar(context, journey, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(JourneyProviderView journey) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(Icons.play_arrow, Colors.green, "Started at:", journey.startAddress),
            const Divider(height: 24),
            _row(Icons.stop, Colors.red, "Ended at:", journey.endAddress),
            if (journey.isSaving)
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                value ?? "Not recorded",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHistoryList(JourneyProviderView journey) {
    if (journey.historyRows.isEmpty && !journey.isSaving) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No activity yet"),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: journey.historyRows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = journey.historyRows[index];
        final isCheckIn = item['action'].toString().contains('IN');
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isCheckIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Icon(isCheckIn ? Icons.login : Icons.logout,
                color: isCheckIn ? Colors.green : Colors.red, size: 18),
          ),
          title: Text(item['location'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          subtitle: Text(item['journey_time'] ?? '', style: const TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            child: Text(item['action'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, JourneyProviderView journey, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: journey.isSaving
              ? null
              : () => journey.handleCheckInOut(auth.sessionCookie!, auth.user!.uid),
          icon: Icon(journey.isCheckedIn ? Icons.logout : Icons.login),
          label: Text(
            journey.isCheckedIn ? "CHECK OUT" : "CHECK IN",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: journey.isCheckedIn ? Colors.redAccent : Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
