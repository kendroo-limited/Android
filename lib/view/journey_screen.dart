import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/journey_model.dart';
import '../provider/auth_provider.dart';
import '../repo/odoo_json_rpc.dart';
import '../services/background_journey_service.dart';
import 'employee/all_employee_page.dart';
import 'employee_profile_page.dart';
import 'journey_map_screen.dart';


// class CheckinCache {
//   static const _kIsCheckedIn = "isCheckedIn";
//   static const _kStartAddress = "startAddress";
//   static const _kCheckInTime = "checkInTime";
//   static const _kFieldForceId = "fieldForceId";
//
//   static Future<void> save({
//     required bool isCheckedIn,
//     String? startAddress,
//     String? checkInTime,
//     int? fieldForceId,
//   }) async {
//     final sp = await SharedPreferences.getInstance();
//     await sp.setBool(_kIsCheckedIn, isCheckedIn);
//     await sp.setString(_kStartAddress, startAddress ?? "");
//     await sp.setString(_kCheckInTime, checkInTime ?? "");
//     if (fieldForceId != null) {
//       await sp.setInt(_kFieldForceId, fieldForceId);
//     } else {
//       await sp.remove(_kFieldForceId);
//     }
//   }
//
//   static Future<Map<String, dynamic>> load() async {
//     final sp = await SharedPreferences.getInstance();
//     return {
//       "isCheckedIn": sp.getBool(_kIsCheckedIn) ?? false,
//       "startAddress": sp.getString(_kStartAddress) ?? "",
//       "checkInTime": sp.getString(_kCheckInTime) ?? "",
//       "fieldForceId": sp.getInt(_kFieldForceId),
//     };
//   }
//
// // static Future<void> clear() async {
// //   final sp = await SharedPreferences.getInstance();
// //   await sp.remove(_kIsCheckedIn);
// //   await sp.remove(_kStartAddress);
// //   await sp.remove(_kCheckInTime);
// //   await sp.remove(_kFieldForceId);
// // }
// }



class CheckinCache {
  static const String _key = "checkin_data";

  static Future<void> save({
    required bool isCheckedIn,
    String? startAddress,
    String? checkInTime,
    int? fieldForceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCheckedIn', isCheckedIn);
    await prefs.setString('startAddress', startAddress ?? "");
    await prefs.setString('checkInTime', checkInTime ?? "");
    await prefs.setInt('fieldForceId', fieldForceId ?? -1);
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "isCheckedIn": prefs.getBool('isCheckedIn') ?? false,
      "startAddress": prefs.getString('startAddress') ?? "",
      "checkInTime": prefs.getString('checkInTime') ?? "",
      "fieldForceId": prefs.getInt('fieldForceId') == -1 ? null : prefs.getInt('fieldForceId'),
    };
  }
}
class JourneyProviderView extends ChangeNotifier {
  final loc.Location _location = loc.Location();

  bool isCheckedIn = false;
  String? startAddress;
  String? endAddress;

  bool _restored = false;
  bool _hasFetchedInitial = false;

  Timer? _autoTimer;
  List<Map<String, dynamic>> historyRows = [];
  String locationStatus = 'Ready';
  bool isSaving = false;

  int? _currentFieldForceId;
  bool _sessionClosed = false;
  bool isHydrating = true;
  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "https://demo.kendroo.com",
      sessionCookie: cookie,
    );
  }
  bool _initScheduled = false;

  void scheduleInit(String cookie, int uid) {
    if (_initScheduled) return;
    _initScheduled = true;
    Future.microtask(() => init(cookie, uid));
  }

  Future<void> init(String cookie, int uid) async {
    if (_hasFetchedInitial) return;
    _hasFetchedInitial = true;
    await restoreFromCache();
    try {
      await fetchHistory(cookie, uid, updateStatus: true);

    } catch (e) {
      print("Background sync failed, but we have cache: $e");
    }
  }


  Future<void> restoreFromCache() async {
    if (_restored) return;
    final data = await CheckinCache.load();

    isCheckedIn = data["isCheckedIn"] as bool;
    startAddress = (data["startAddress"] as String);
    _currentFieldForceId = data["fieldForceId"] as int?;

    _restored = true;
    isHydrating = false;
    notifyListeners();
  }

  Future<void> _saveCache({String? checkInTime}) async {
    await CheckinCache.save(
      isCheckedIn: isCheckedIn,
      startAddress: startAddress,
      checkInTime: checkInTime,
      fieldForceId: _currentFieldForceId,
    );
  }

  double get totalDistanceKm {
    if (historyRows.isEmpty) return 0.0;
    final rows = [...historyRows];
    rows.sort((a, b) {
      final at = (a['journey_time'] ?? '').toString();
      final bt = (b['journey_time'] ?? '').toString();
      DateTime da = DateTime.tryParse(at.replaceFirst(' ', 'T')) ?? DateTime.fromMillisecondsSinceEpoch(0);
      DateTime db = DateTime.tryParse(bt.replaceFirst(' ', 'T')) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });


    final points = <ll.LatLng>[];
    for (final r in rows) {
      final lat = (r['latitude'] as num?)?.toDouble();
      final lng = (r['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      points.add(ll.LatLng(lat, lng));
    }

    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += _haversineKm(points[i - 1], points[i]);
    }
    return total;
  }

  Future<void> _sendAutoLocationPing(String cookie, int uid) async {
    try {
      final point = await _getLatLng();
      final address = await getAddressFromLatLng(point);
      // await _rpc(cookie).checkInCreateOrUpdate(
      //   uid: uid,
      //   startLocation: address,
      //   latitude: point.latitude,
      //   longitude: point.longitude,
      //   journeyTime: DateTime.now(),
      // );

      _currentFieldForceId ??= await _rpc(cookie).getLatestFieldForceIdForUser(uid);


      await _rpc(cookie).addJourneyHistoryLine(
        // fieldForceId: uid,
        fieldForceId: _currentFieldForceId!,
        latitude: point.latitude,
        longitude: point.longitude,
        location: address,
        journeyTime: DateTime.now(),

      );
      locationStatus = "Auto update sent ✅ (${DateTime.now().toLocal()})";
      notifyListeners();
    } catch (e) {
      locationStatus = "Auto update failed: $e";
      notifyListeners();
    }
  }

  // Future<ll.LatLng> _getLatLng() async {
  //   final data = await _location.getLocation();
  //   if (data.latitude == null || data.longitude == null) {
  //     throw Exception("GPS not found");
  //   }
  //   return ll.LatLng(data.latitude!, data.longitude!);
  // }

  Future<ll.LatLng> _getLatLng() async {
    // 1) GPS service ON?
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception("GPS is OFF. Please turn on Location.");
      }
    }

    // 2) Permission granted?
    var permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    if (permission != loc.PermissionStatus.granted &&
        permission != loc.PermissionStatus.grantedLimited) {
      throw Exception("Location permission denied. Please allow location permission.");
    }

    // 3) Get location (with timeout)
    final data = await _location.getLocation().timeout(const Duration(seconds: 12));

    final lat = data.latitude;
    final lng = data.longitude;

    if (lat == null || lng == null) {
      throw Exception("GPS not found. Try going outside / wait a few seconds.");
    }

    return ll.LatLng(lat, lng);
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

  double _deg2rad(double deg) => deg * (pi / 180.0);
  double _haversineKm(ll.LatLng a, ll.LatLng b) {
    const double r = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);

    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final h = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1) * cos(lat2) * (sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return r * c;
  }
  Future<String> getAddressFromLatLng(ll.LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude).timeout(const Duration(seconds: 8));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return "${p.name}, ${p.locality}, ${p.country}";
      }
    } catch (_) {
      return "Lat:${point.latitude.toStringAsFixed(5)}, Lng:${point.longitude.toStringAsFixed(5)}";
    }
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

  Future<void> fetchHistory(String cookie, int uid, {bool updateStatus = true}) async {
    isSaving = true;
    notifyListeners();

    try {
      final rows = await _rpc(cookie).fetchLatestJourneyHistoryForUser(uid: uid);

      rows.sort((a, b) {
        final da = DateTime.tryParse(a['journey_time'].toString().replaceFirst(' ', 'T')) ?? DateTime(0);
        final db = DateTime.tryParse(b['journey_time'].toString().replaceFirst(' ', 'T')) ?? DateTime(0);
        return db.compareTo(da);
      });

      historyRows = rows;

      if (rows.isNotEmpty && updateStatus) {
        final latestAction = (rows.first['action'] ?? '').toString().toUpperCase();
        final bool serverStatus = latestAction.contains('IN');


        isCheckedIn = serverStatus;

        if (isCheckedIn) {
          startAddress = rows.first['location'] ?? startAddress;
          _currentFieldForceId = rows.first['field_force_id'] ?? await _rpc(cookie).getLatestFieldForceIdForUser(uid);

          if (_autoTimer == null) startAutoUpdates(cookie, uid);
        } else {
          stopAutoUpdates();
          _currentFieldForceId = null;
        }

        await _saveCache(checkInTime: rows.first['journey_time']?.toString());
      }

      locationStatus = rows.isEmpty ? "No history found." : "History loaded ✅";
    } catch (e) {
      locationStatus = "Sync failed: $e";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }



  Duration get totalWorkedDuration {
    if (historyRows.isEmpty) return Duration.zero;


    final rows = [...historyRows];
    rows.sort((a, b) {
      final at = (a['journey_time'] ?? '').toString();
      final bt = (b['journey_time'] ?? '').toString();
      final da = DateTime.tryParse(at.replaceFirst(' ', 'T')) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(bt.replaceFirst(' ', 'T')) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });

    DateTime? lastCheckIn;
    var totalSeconds = 0;

    for (final r in rows) {
      final action = (r['action'] ?? '').toString().toUpperCase();
      final timeStr = (r['journey_time'] ?? '').toString();
      final t = DateTime.tryParse(timeStr.replaceFirst(' ', 'T'));
      if (t == null) continue;

      final isIn = action.contains('IN');
      final isOut = action.contains('OUT');


      if (isIn) {
        lastCheckIn = t;
      }


      if (isOut && lastCheckIn != null && t.isAfter(lastCheckIn!)) {
        totalSeconds += t.difference(lastCheckIn!).inSeconds;
        lastCheckIn = null; // reset for next session
      }
    }

    return Duration(seconds: totalSeconds);
  }
  Duration get totalWorkedDurationIncludingRunning {
    final base = totalWorkedDuration;


    final lastIn = _lastCheckInTime();
    if (isCheckedIn && lastIn != null) {
      return base + DateTime.now().difference(lastIn);
    }
    return base;
  }

  DateTime? _lastCheckInTime() {
    final rows = [...historyRows];
    rows.sort((a, b) {
      final at = (a['journey_time'] ?? '').toString();
      final bt = (b['journey_time'] ?? '').toString();
      final da = DateTime.tryParse(at.replaceFirst(' ', 'T')) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(bt.replaceFirst(' ', 'T')) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });

    for (int i = rows.length - 1; i >= 0; i--) {
      final action = (rows[i]['action'] ?? '').toString().toUpperCase();
      if (action.contains('IN')) {
        final t = DateTime.tryParse((rows[i]['journey_time'] ?? '').toString().replaceFirst(' ', 'T'));
        if (t != null) return t;
      }
    }
    return null;
  }
  Future<void> handleCheckInOut(String cookie, int uid) async {
    if (isSaving) return;

    isSaving = true;
    locationStatus = "Fetching GPS...";
    notifyListeners();

    try {
      final point = await _getLatLng().timeout(const Duration(seconds: 12));
      locationStatus = "Step 2/3: Getting address...";
      notifyListeners();

      final address = await getAddressFromLatLng(point).timeout(const Duration(seconds: 10));
      locationStatus = "Step 3/3: Sending to server...";
      notifyListeners();
      final rpc = _rpc(cookie);

      if (!isCheckedIn) {
        final ffId = await rpc.checkInCreateOrUpdate(
          uid: uid,
          startLocation: address,
          latitude: point.latitude,
          longitude: point.longitude,
          journeyTime: DateTime.now(),
        ).timeout(const Duration(seconds: 20));

        startAddress = address;
        endAddress = null;
        isCheckedIn = true;
        _currentFieldForceId = ffId;
        locationStatus = "Check-in saved ✅";
        historyRows.clear();
        _sessionClosed = false;

        await _saveCache(checkInTime: DateTime.now().toIso8601String());

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
        ).timeout(const Duration(seconds: 20));

        stopAutoUpdates();
        await BackgroundJourneyService.stop();

        endAddress = address;
        isCheckedIn = false;
        _currentFieldForceId = null;
        locationStatus = "Check-out saved ✅";

        historyRows.clear();
        _sessionClosed = true;

        await _saveCache(checkInTime: "");

        locationStatus = "Check-out saved ✅";
      }

      notifyListeners();
      await fetchHistory(cookie, uid, updateStatus: false);
    } catch (e) {
      locationStatus = "Error: $e";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}

class JourneyScreen extends StatefulWidget {
  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final journey = Provider.of<JourneyProviderView>(context, listen: false);
      journey.init(auth.sessionCookie!, auth.user!.uid);
    });
  }

//class JourneyScreen extends StatelessWidget {
 // JourneyScreen({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final journey = context.watch<JourneyProviderView>();

    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;

    final padding = isSmall ? 14.0 : 16.0;


   // Future.microtask(() => journey.init(auth.sessionCookie!, auth.user!.uid));
   // journey.scheduleInit(auth.sessionCookie!, auth.user!.uid);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F8FF),
      drawer: _appDrawer(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => journey.fetchHistory(auth.sessionCookie!, auth.user!.uid),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(
                    context,
                    isSmall: isSmall,
                    name: auth.user?.name ?? "User",
                    role: auth.user?.companyName ?? "",
                    onMenu: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    onBell: () {},
                    onProfile: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyProfilePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildCheckInCard(
                    context,
                    isSmall: isSmall,
                    journey: journey,
                    onMapTap: () {
                      if (journey.historyRows.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No checkin history found"),
                          ),
                        );
                        return;
                      }
                      final data = journey.buildMapDataFromHistory();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JourneyMapScreen(data: data)),
                      );
                    },

                    onSwipeTap: journey.isSaving
                        ? null
                        : () => journey.handleCheckInOut(auth.sessionCookie!, auth.user!.uid),
                  ),
                  Text(
                    "Hydrating: ${journey.isHydrating} | Saving: ${journey.isSaving}",
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    "Today’s Record",
                    style: TextStyle(
                      fontSize: isSmall ? 13 : 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C2A4A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _statTile(
                          isSmall: isSmall,
                          icon: Icons.route,
                          value: _distanceText(journey),
                          label: "Distance\nTravelled",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statTile(
                          isSmall: isSmall,
                          icon: Icons.access_time,
                          value: _workedDurationText(journey),
                          label: "Hrs\nworked",
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 16),

                  const SizedBox(height: 12),

                  Text(
                    journey.locationStatus,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                      fontSize: isSmall ? 11 : 12,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    "History Logs",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isSmall ? 14 : 16,
                      color: const Color(0xFF1C2A4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildHistoryList(journey, isSmall),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 80),
        children: [

          _drawerItem(context, icon: Icons.home, title: "Employees", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeListView()));
          }),

          _drawerItem(context, icon: Icons.info, title: "About", onTap: () {}),
          _drawerItem(context, icon: Icons.help_outline, title: "Query", onTap: () {}),
          _drawerItem(context, icon: Icons.share, title: "Share", onTap: () {}),
          _drawerItem(context, icon: Icons.privacy_tip, title: "Privacy policy", onTap: () {}),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
  Widget _buildTopHeader(
      BuildContext context, {
        required bool isSmall,
        required String name,
        required String role,
        required VoidCallback onMenu,
        required VoidCallback onBell,
        required VoidCallback onProfile,
      }) {
    return Row(
      children: [
        InkWell(
          onTap: onMenu,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.menu_rounded),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi!",
                style: TextStyle(
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1C2A4A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmall ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C2A4A),
                ),
              ),
              if (role.isNotEmpty)
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    color: const Color(0xFF7D8BB3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        _circleIconButton(icon: Icons.person_outline_rounded, onTap: onProfile),
      ],
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1C2A4A)),
      ),
    );
  }


  Widget _buildCheckInCard(
      BuildContext context, {
        required bool isSmall,
        required JourneyProviderView journey,
        required VoidCallback onMapTap,
        required VoidCallback? onSwipeTap,
      }) {
    final now = DateTime.now();
    final weekday = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][now.weekday - 1];
    final month = const ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][now.month - 1];

    final checkInTime = _latestTimeText(journey, wantIn: false);
    final checkOutTime = _latestTimeText(journey, wantIn: true);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF77A6FF), Color(0xFF4F7BFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "$weekday, $month ${now.day.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 12 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onMapTap,
                  child: Row(
                    children: [
                      const Icon(Icons.map_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "Map",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 12 : 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(isSmall ? 12 : 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _inOutMini(
                          isSmall: isSmall,
                          label: "Check IN",
                          timeText: checkInTime,
                          alignLeft: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _inOutMini(
                          isSmall: isSmall,
                          label: "Check OUT",
                          timeText: checkOutTime,
                          alignLeft: false,
                        ),
                      ),
                      if (journey.isCheckedIn) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC048),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "00:05",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: isSmall ? 11 : 12,
                              color: const Color(0xFF1C2A4A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // SwipeToAction(
                  //   isSmall: isSmall,
                  //   isLoading: journey.isSaving,
                  //   isCheckedIn: journey.isCheckedIn,
                  //   onSubmit: onSwipeTap,
                  // ),
// Inside _buildCheckInCard, look for the SwipeToAction part:

                  journey.isHydrating
                      ? const Center(child: CircularProgressIndicator()) // Show loading on cold start
                      : SwipeToAction(
                    isSmall: isSmall,
                    isLoading: journey.isSaving,
                    isCheckedIn: journey.isCheckedIn,
                    onSubmit: onSwipeTap,
                  ),



                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inOutMini({
    required bool isSmall,
    required String label,
    required String timeText,
    required bool alignLeft,
  }) {
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 11 : 12,
            color: const Color(0xFF7D8BB3),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          timeText,
          style: TextStyle(
            fontSize: isSmall ? 14 : 15,
            color: const Color(0xFF1C2A4A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }



  Widget _buildHistoryList(JourneyProviderView journey, bool isSmall) {
    if (journey.historyRows.isEmpty && !journey.isSaving) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No activity yet"),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: journey.historyRows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = journey.historyRows[index];
          final isCheckIn = item['action'].toString().toUpperCase().contains('IN');

          return Padding(
            padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isSmall ? 16 : 18,
                  backgroundColor: isCheckIn
                      ? const Color(0xFF3A6BFF).withOpacity(0.10)
                      : const Color(0xFFFF6B81).withOpacity(0.10),
                  child: Icon(
                    isCheckIn ? Icons.login : Icons.logout,
                    color: isCheckIn ? const Color(0xFF3A6BFF) : const Color(0xFFFF6B81),
                    size: isSmall ? 16 : 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['location'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C2A4A),
                        ),
                      ),
                      Text(
                        item['journey_time'] ?? '',
                        style: TextStyle(
                          fontSize: isSmall ? 10 : 11,
                          color: const Color(0xFF7D8BB3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD6E2FF)),
                  ),
                  child: Text(
                    (item['action'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: isSmall ? 9 : 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1C2A4A),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _statTile({
    required bool isSmall,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
        height: isSmall ? 92 : 98,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child:
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isSmall ? 20 : 22, color: const Color(0xFF3A6BFF)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C2A4A),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 11,
                    color: const Color(0xFF7D8BB3),
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        )

    );
  }


  static String _latestTimeText(JourneyProviderView journey, {required bool wantIn}) {
    final rows = journey.historyRows;

    for (final item in rows) {
      final action = (item['action'] ?? '').toString().toUpperCase();
      final isIn = action.contains('IN');
      if ((wantIn && isIn) || (!wantIn && !isIn)) {
        final t = (item['journey_time'] ?? '').toString();
        if (t.isNotEmpty) return t;
      }
    }
    return "00:00 am";
  }

  static String _distanceText(JourneyProviderView journey) {
    final km = journey.totalDistanceKm;
    return "${km.toStringAsFixed(2)} KM";
  }

  static String _workedDurationText(JourneyProviderView journey) {
    final d = journey.totalWorkedDurationIncludingRunning;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

}

class SwipeToAction extends StatefulWidget {
  final bool isSmall;
  final bool isLoading;
  final bool isCheckedIn;
  final VoidCallback? onSubmit;

  const SwipeToAction({
    super.key,
    required this.isSmall,
    required this.isLoading,
    required this.isCheckedIn,
    required this.onSubmit,
  });

  @override
  State<SwipeToAction> createState() => _SwipeToActionState();
}

class _SwipeToActionState extends State<SwipeToAction> {
  double _drag = 0.0;

  // @override
  // Widget build(BuildContext context) {
  //   final h = widget.isSmall ? 44.0 : 48.0;
  //   final knob = widget.isSmall ? 36.0 : 38.0;
  //   final maxDrag = (MediaQuery.of(context).size.width) - 32 /*screen padding approx*/ - 24 /*container padding*/ - knob;
  //
  //   final progress = (_drag / (maxDrag <= 1 ? 1 : maxDrag)).clamp(0.0, 1.0);
  //
  //   return GestureDetector(
  //     onHorizontalDragUpdate: widget.isLoading || widget.onSubmit == null
  //         ? null
  //         : (d) {
  //       setState(() {
  //         _drag = (_drag + d.delta.dx).clamp(0.0, maxDrag);
  //       });
  //     },
  //     onHorizontalDragEnd: widget.isLoading || widget.onSubmit == null
  //         ? null
  //         : (_) async {
  //
  //       if (progress >= 1) {
  //         widget.onSubmit?.call();
  //       }
  //
  //       setState(() => _drag = 0.0);
  //     },
  //     child: Container(
  //       height: h,
  //       decoration: BoxDecoration(
  //         color: const Color(0xFFEFF4FF),
  //         borderRadius: BorderRadius.circular(999),
  //         border: Border.all(color: const Color(0xFFD6E2FF)),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 12),
  //       child: Stack(
  //         alignment: Alignment.centerLeft,
  //         children: [
  //
  //           Align(
  //             alignment: Alignment.center,
  //             child: Text(
  //               widget.isCheckedIn ? "Swipe to Check Out" : "Swipe to Check In",
  //               style: TextStyle(
  //                 color: const Color(0xFF1C2A4A),
  //                 fontWeight: FontWeight.w800,
  //                 fontSize: widget.isSmall ? 12 : 13,
  //               ),
  //             ),
  //           ),
  //
  //
  //           AnimatedAlign(
  //             duration: const Duration(milliseconds: 80),
  //             alignment: Alignment(-1 + (2 * progress), 0),
  //             child: Container(
  //               width: knob,
  //               height: knob,
  //               decoration: BoxDecoration(
  //                 color: widget.isCheckedIn
  //                     ? const Color(0xFFFF6B81)
  //                     : const Color(0xFF3A6BFF),
  //                 borderRadius: BorderRadius.circular(999),
  //               ),
  //               child: widget.isLoading
  //                   ? const Padding(
  //                 padding: EdgeInsets.all(10),
  //                 child: CircularProgressIndicator(
  //                   strokeWidth: 2,
  //                   color: Colors.white,
  //                 ),
  //               )
  //                   : Icon(
  //                 widget.isCheckedIn ? Icons.logout_rounded : Icons.arrow_forward_rounded,
  //                 color: Colors.white,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  late Future<bool> _locationOnFuture;   // ✅ cache it once

  @override
  void initState() {
    super.initState();
    _locationOnFuture = Geolocator.isLocationServiceEnabled(); // ✅ only once
  }
  @override
  Widget build(BuildContext context) {
    final h = widget.isSmall ? 44.0 : 48.0;
    final knob = widget.isSmall ? 36.0 : 38.0;
    final maxDrag = (MediaQuery.of(context).size.width) -
        32 - 24 -
        knob;

    final progress = (_drag / (maxDrag <= 1 ? 1 : maxDrag)).clamp(0.0, 1.0);

    return FutureBuilder<bool>(
      future: _locationOnFuture,
      builder: (context, snap) {
        final isLocationOn = snap.data ?? true;
        final blockSwipe = !isLocationOn && (widget.isCheckedIn || !widget.isCheckedIn);

        final label = blockSwipe
            ? "Plz turn on the location"
            : (widget.isCheckedIn ? "Swipe to Check Out" : "Swipe to Check In");

        return GestureDetector(
          onHorizontalDragUpdate: widget.isLoading || widget.onSubmit == null || blockSwipe
              ? null
              : (d) {
            setState(() {
              _drag = (_drag + d.delta.dx).clamp(0.0, maxDrag);
            });
          },
          onHorizontalDragEnd: widget.isLoading || widget.onSubmit == null || blockSwipe
              ? null
              : (_) async {
            if (progress >= 1) {
              widget.onSubmit?.call();
            }
            setState(() => _drag = 0.0);
          },
          child: Opacity(
            opacity: blockSwipe ? 0.55 : 1.0,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD6E2FF)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: blockSwipe ? Colors.red : const Color(0xFF1C2A4A),
                        fontWeight: FontWeight.w800,
                        fontSize: widget.isSmall ? 12 : 13,
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 80),
                    alignment: Alignment(-1 + (2 * progress), 0),
                    child: Container(
                      width: knob,
                      height: knob,
                      decoration: BoxDecoration(
                        color: blockSwipe
                            ? Colors.grey
                            : (widget.isCheckedIn
                            ? const Color(0xFFFF6B81)
                            : const Color(0xFF3A6BFF)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: widget.isLoading
                          ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(
                        widget.isCheckedIn
                            ? Icons.logout_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}