// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
//
// import 'package:flutter_map/flutter_map.dart' as ll;
// import 'package:latlong2/latlong.dart' as ll;
// import 'package:flutter_map/flutter_map.dart';
// import 'package:location/location.dart' as loc;
// import 'package:geocoding/geocoding.dart';
// import 'package:provider/provider.dart';
// import '../model/journey_model.dart';
// import '../provider/journey_provider.dart';
// import 'background_location_task.dart';
// import 'journey_map_screen.dart';
//
//
// class JourneyScreen extends StatefulWidget {
//   const JourneyScreen({super.key});
//
//   @override
//   State<JourneyScreen> createState() => _JourneyScreenState();
// }
//
// class _JourneyScreenState extends State<JourneyScreen> {
//
//   final loc.Location _location = loc.Location();
//
//   ll.LatLng? _startLocation;
//   ll.LatLng? _endLocation;
//   Timer? _autoTimer;
//   DateTime? _lastLocationUpdateTime;
//
//
//   bool isCheckedIn = false;
//   String? _startAddress;
//   String? _endAddress;
//
//   double? _distanceInMeters;
//   final ll.Distance distance = const ll.Distance();
//
//   String _locationStatus = 'Initializing...';
//
//
//   final ll.LatLng _fallbackCenter = const ll.LatLng(23.780573, 90.279239);
//   StreamSubscription<loc.LocationData>? _locationSub;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _checkLocationAndPermission();
//     _listenLiveLocation();
//   }
//
//   void _listenLiveLocation() {
//     _locationSub = _location.onLocationChanged.listen((loc.LocationData data) async {
//       if (data.latitude != null && data.longitude != null) {
//         final point = ll.LatLng(data.latitude!, data.longitude!);
//         setState(() {
//           _locationStatus = "Live location updated";
//         });
//       }
//       final now = DateTime.now();
//
//       if (_lastLocationUpdateTime == null ||
//           now.difference(_lastLocationUpdateTime!).inMinutes >= 15) {
//
//         _lastLocationUpdateTime = now;
//
//         final point = ll.LatLng(
//           data.latitude!,
//           data.longitude!,
//         );
//
//         setState(() {
//           _locationStatus = "Location updated at ${now.hour}:${now.minute}";
//         });
//
//
//         // saveLocation(point);
//         // sendToServer(point);
//         // updateMap(point);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _locationSub?.cancel();
//     _stopAutoLocationUpdates();
//     super.dispose();
//   }
//
//
//   Future<String> _getAddressFromLatLng(ll.LatLng point) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
//       if (placemarks.isNotEmpty) {
//         final p = placemarks.first;
//         final parts = <String>[
//           if ((p.street ?? '').isNotEmpty) p.street!,
//           if ((p.locality ?? '').isNotEmpty)
//             p.locality!
//           else if ((p.subLocality ?? '').isNotEmpty)
//             p.subLocality!,
//           if ((p.country ?? '').isNotEmpty) p.country!,
//         ];
//         return parts.join(', ');
//       }
//       return '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
//     } catch (_) {
//       return '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
//     }
//   }
//
//   void _handleCheckInOut() {
//     setState(() {
//       isCheckedIn = !isCheckedIn;
//     });
//
//     if (isCheckedIn) {
//       _setStartFromDevice();
//
//       print("Checked in");
//     } else {
//       _onEndJourney();
//
//
//     }
//   }
//
//
//   Future<List<(String, ll.LatLng)>> _forwardGeocode(String query) async {
//     final results = await locationFromAddress(query);
//     final limited = results.take(5).toList();
//     final List<(String, ll.LatLng)> items = [];
//     for (final r in limited) {
//       final point = ll.LatLng(r.latitude, r.longitude);
//       final nice = await _getAddressFromLatLng(point);
//       items.add((nice, point));
//     }
//     return items;
//   }
//
//   Future<void> _checkLocationAndPermission() async {
//     setState(() => _locationStatus = 'Checking permissions and services...');
//
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) {
//         setState(() => _locationStatus = 'Location Service is disabled. Please enable it.');
//         return;
//       }
//     }
//
//     loc.PermissionStatus permissionGranted = await _location.hasPermission();
//     if (permissionGranted == loc.PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != loc.PermissionStatus.granted) {
//         setState(() => _locationStatus = 'Location Permission is denied.');
//         return;
//       }
//     }
//
//     setState(() => _locationStatus = 'Ready. Set start location by search.');
//   }
//
//
//
//   List<Marker> _buildMapMarkers(Journey? journey) {
//     final markers = <Marker>[];
//
//     if (_startLocation != null) {
//       markers.add(
//         Marker(
//           point: _startLocation!,
//           width: 50,
//           height: 50,
//           alignment: Alignment.topCenter,
//           child: const Icon(
//             Icons.flag,
//             size: 36,
//             color: Colors.indigo,
//           ),
//         ),
//       );
//     }
//
//
//     if (_endLocation != null) {
//       markers.add(
//         Marker(
//           point: _endLocation!,
//           width: 50,
//           height: 50,
//           alignment: Alignment.topCenter,
//           child: const Icon(
//             Icons.place,
//             size: 36,
//             color: Colors.red,
//           ),
//         ),
//       );
//     }
//
//     final events = journey?.events ?? [];
//     for (final e in events) {
//       final isIn = e.type == 'IN';
//
//       markers.add(
//         Marker(
//           point: e.location,
//           width: 40,
//           height: 40,
//           alignment: Alignment.center,
//           child: Icon(
//             isIn ? Icons.login : Icons.logout,
//             size: 24,
//             color: isIn ? Colors.green : Colors.orange,
//           ),
//         ),
//       );
//     }
//
//     return markers;
//   }
//
//   void _startAutoLocationUpdates() {
//     _autoTimer?.cancel();
//
//     _autoTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
//       final journeyProvider = context.read<JourneyProvider>();
//
//
//       if (_startLocation == null || _startAddress == null) return;
//       if (!mounted) return;
//
//       final data = await _location.getLocation();
//       if (data.latitude == null || data.longitude == null) return;
//
//       final point = ll.LatLng(data.latitude!, data.longitude!);
//       final address = await _getAddressFromLatLng(point);
//
//       journeyProvider.addCheckEvent(
//         type: 'AUTO',
//         location: point,
//         address: address,
//         isAuto: true,
//       );
//
//       if (!mounted) return;
//       setState(() {
//         _locationStatus = "Auto updated location (15 min)";
//       });
//     });
//   }
//
//   void _stopAutoLocationUpdates() {
//     _autoTimer?.cancel();
//     _autoTimer = null;
//   }
//
//   Future<void> _setStartFromDevice() async {
//     final journeyProvider = context.read<JourneyProvider>();
//
//
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enable Location Service.')),
//         );
//         return;
//       }
//     }
//
//     loc.PermissionStatus permission = await _location.hasPermission();
//     if (permission == loc.PermissionStatus.denied) {
//       permission = await _location.requestPermission();
//       if (permission != loc.PermissionStatus.granted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permission required.')),
//         );
//         return;
//       }
//     }
//
//     final loc.LocationData data = await _location.getLocation();
//     if (data.latitude == null || data.longitude == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Unable to get current location for START.')),
//       );
//       return;
//     }
//
//     final ll.LatLng point = ll.LatLng(data.latitude!, data.longitude!);
//     final address = await _getAddressFromLatLng(point);
//
//     setState(() {
//       _startLocation = point;
//       _startAddress = address;
//       _locationStatus = 'Start location set from current GPS.';
//     });
//
//
//     journeyProvider.initJourney(
//       startLocation: point,
//       startAddress: address,
//     );
//     _startAutoLocationUpdates();
//     await FlutterForegroundTask.startService(
//       notificationTitle: 'Journey in progress',
//       notificationText: 'Location updates every 15 minutes',
//       callback: startCallback,
//     );
//
//     debugPrint('START set at: $point ($address)');
//   }
//
//
//   void _calculateDistance() {
//     if (_startLocation != null && _endLocation != null) {
//       final d = distance(_startLocation!, _endLocation!);
//       setState(() {
//         _distanceInMeters = d;
//       });
//     } else {
//       setState(() => _distanceInMeters = null);
//     }
//   }
//
//   String _formatDistance(double? meters) {
//     if (meters == null) return '—';
//     if (meters < 1000) return '${meters.toStringAsFixed(1)} meters';
//     return '${(meters / 1000).toStringAsFixed(2)} kilometers';
//   }
//
//   ll.LatLng get _mapCenter => _startLocation ?? _fallbackCenter;
//
//
//   void _onEndJourney() async {
//     _stopAutoLocationUpdates();
//     await FlutterForegroundTask.stopService();
//
//     final journeyProvider = context.read<JourneyProvider>();
//
//     if (_startLocation == null || _startAddress == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please set START location (via search) first.')),
//       );
//       return;
//     }
//
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enable Location Service.')),
//         );
//         return;
//       }
//     }
//
//     loc.PermissionStatus permission = await _location.hasPermission();
//     if (permission == loc.PermissionStatus.denied) {
//       permission = await _location.requestPermission();
//       if (permission != loc.PermissionStatus.granted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permission required.')),
//         );
//         return;
//       }
//     }
//
//     final loc.LocationData data = await _location.getLocation();
//     if (data.latitude == null || data.longitude == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Unable to get current location for END.')),
//       );
//       return;
//     }
//
//     final ll.LatLng point = ll.LatLng(data.latitude!, data.longitude!);
//     final address = await _getAddressFromLatLng(point);
//
//     debugPrint('END JOURNEY at: $point ($address) from START: $_startLocation');
//
//     setState(() {
//       _endLocation = point;
//       _endAddress = address;
//       _locationStatus = 'Journey ended at current GPS location.';
//     });
//
//     _calculateDistance();
//
//
//
//     journeyProvider.addCheckEvent(
//       type: 'OUT',
//       location: point,
//       address: address,
//     );
//
//
//     journeyProvider.completeJourney(
//       endLocation: point,
//       endAddress: address,
//       distanceInMeters: _distanceInMeters,
//     );
//
//
//     try {
//       await journeyProvider.saveCurrentJourney();
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Journey saved successfully.')),
//       );
//     } catch (_) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to save journey.')),
//       );
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     final journeyProvider = context.watch<JourneyProvider>();
//     final currentJourney = journeyProvider.current;
//     final isSaving = journeyProvider.isSaving;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add location'),
//         backgroundColor: Colors.indigo,
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Info
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
//             child: Column(
//               children: [
//                 _buildInfoCard(currentJourney),
//                 const SizedBox(height:6),
//                 Text(
//                   _locationStatus,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontStyle: FontStyle.italic,
//                     color: Colors.black54,
//                   ),
//                 ),
//                 if (isSaving) ...[
//                   const SizedBox(height: 6),
//                   const LinearProgressIndicator(minHeight: 2),
//                 ],
//               ],
//             ),
//           ),
//
//           Padding(
//           padding: EdgeInsets.symmetric(
//           horizontal: MediaQuery.of(context).size.width < 360 ? 10 : 16,
//           vertical: MediaQuery.of(context).size.width < 360 ? 4 : 5,
//           ),
//           child: SizedBox(
//           width: double.infinity,
//           height: MediaQuery.of(context).size.width < 380
//           ? 45
//               : MediaQuery.of(context).size.width < 600
//           ? 50
//               : 60,
//           child: ElevatedButton.icon(
//           onPressed: () {
//     if (currentJourney == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//     content: Text('No journey data to show on map.'),
//     ),
//     );
//     return;
//     }
//
//     Navigator.push(
//     context,
//     MaterialPageRoute(
//     builder: (_) => JourneyMapScreen(
//     journey: currentJourney,
//     startLocation: _startLocation,
//     endLocation: _endLocation,
//     ),
//     ),
//     );
//     },
//
//     icon: Icon(
//     Icons.map,
//     size: MediaQuery.of(context).size.width < 380
//     ? 18
//         : MediaQuery.of(context).size.width < 600
//     ? 22
//         : 26, // responsive icon size
//     ),
//
//     label: Text(
//     'VIEW MAP',
//     style: TextStyle(
//     fontSize: MediaQuery.of(context).size.width < 380
//     ? 13
//         : MediaQuery.of(context).size.width < 600
//     ? 15
//         : 18, // responsive text
//     fontWeight: FontWeight.w600,
//     ),
//     ),
//
//     style: ElevatedButton.styleFrom(
//     padding: const EdgeInsets.symmetric(vertical: 0),
//     shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(10),
//     ),
//     ),
//     ),
//     ),
//     ),
//
//
// SizedBox(height: 20,),
//     Padding(
//     padding: EdgeInsets.fromLTRB(
//     MediaQuery.of(context).size.width < 360 ? 8 : 10,   // left
//     0,
//     MediaQuery.of(context).size.width < 360 ? 12 : 16,  // right
//     MediaQuery.of(context).size.width < 400 ? 16 : 20,  // bottom
//     ),
//     child: Builder(
//     builder: (context) {
//     final width = MediaQuery.of(context).size.width;
//     final bool isSmall = width < 380;
//     final double buttonHeight = isSmall ? 44 : 50;
//     final double primaryFontSize = isSmall ? 13 : 14;
//     final double endFontSize = isSmall ? 13 : 14.5;
//     final double gapLarge = isSmall ? 8 : 12;
//     final double gapSmall = isSmall ? 6 : 8;
//
//     return Column(
//     crossAxisAlignment: CrossAxisAlignment.stretch,
//     children: [
//     Row(
//     children: [
//     Expanded(
//     child: SizedBox(
//       height: buttonHeight,
//       child: ElevatedButton.icon(
//         onPressed: _handleCheckInOut,
//         icon: Icon(
//           isCheckedIn ? Icons.logout : Icons.search,
//           size: isSmall ? 18 : 20,
//         ),
//         label: Text(
//           isCheckedIn ? 'Check Out' : 'Check In',
//           style: TextStyle(
//             fontSize: primaryFontSize,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor:
//           isCheckedIn ? Colors.red : Colors.indigo,
//           foregroundColor: Colors.white,
//           padding: EdgeInsets.zero,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       ),
//     ),
//       ),
//       ],
//       ),
//
//
//       SizedBox(height: gapLarge),
//
//
//
//     ],
//     );
//     },
//     ),
//     )
//
//
//     ],
//       ),
//     );
//   }
//
//
//   Widget _buildInfoCard(Journey? journey) {
//     final distanceText = _formatDistance(_distanceInMeters);
//     Color distanceColor = _distanceInMeters != null
//         ? Colors.indigo
//         : (_startLocation != null ? Colors.orange.shade700 : Colors.grey);
//
//     final events = journey?.events ?? [];
//
//
//     final width = MediaQuery.of(context).size.width;
//     final bool isVerySmall = width < 340;
//     final bool isSmall = width < 400;
//     final bool isTablet = width >= 600;
//
//     final double cardPadding = isVerySmall ? 12 : (isSmall ? 14 : 18);
//     final double titleFontSize = isVerySmall ? 13.5 : (isSmall ? 14.5 : 16);
//     final double bodyFontSize = isVerySmall ? 12.5 : (isSmall ? 13.5 : 15);
//     final double historyHeight = isVerySmall
//         ? 100
//         : (isSmall ? 120 : (isTablet ? 180 : 140));
//
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(cardPadding),
//         child: Column(
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: _buildLocationDetail(
//                     'Start Location:',
//                     _startAddress,
//                     Icons.flag,
//                     Colors.indigo,
//                     titleFontSize: titleFontSize,
//                     bodyFontSize: bodyFontSize,
//                   ),
//                 ),
//               ],
//             ),
//
//             const Divider(height: 20),
//
//             _buildLocationDetail(
//               'End Location:',
//               _endAddress,
//               Icons.place,
//               Colors.red,
//               titleFontSize: titleFontSize,
//               bodyFontSize: bodyFontSize,
//             ),
//
//             const Divider(height: 20),
//
//             if (events.isNotEmpty) ...[
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Check-in / Check-out History',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: isSmall ? 13.5 : 15,
//                     color: Colors.grey.shade800,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 6),
//               SizedBox(
//                 height: historyHeight,
//                 child: ListView.builder(
//                   itemCount: events.length,
//                   itemBuilder: (context, index) {
//                     return _buildHistoryRow(
//                       events[index],
//                       compact: isSmall || isVerySmall,
//                     );
//                   },
//                 ),
//               ),
//             ] else ...[
//               Text(
//                 'No check-in / check-out yet.',
//                 style: TextStyle(
//                   fontSize: isSmall ? 13 : 14,
//                   fontStyle: FontStyle.italic,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//
//             const SizedBox(height: 5),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildHistoryRow(
//       JourneyCheckEvent e, {
//         bool compact = false,
//       }) {
//     final isIn = e.type == 'IN';
//     final typeColor = isIn ? Colors.green : Colors.orange;
//     final typeLabel = isIn ? 'CHECK IN' : 'CHECK OUT';
//
//     final time = e.timestamp.toLocal();
//     final dateStr =
//         '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
//         '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
//
//
//     final width = MediaQuery.of(context).size.width;
//     final bool verySmall = width < 340;
//     final bool small = width < 400;
//
//     final double dateFontSize =
//     compact || small ? 11.0 : 12.0;
//     final double addrFontSize = compact || small ? 11.0 : 12.0;
//     final double chipFontSize = compact || small ? 10.0 : 11.0;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: typeColor.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             // child: Text(
//             //   typeLabel,
//             //   style: TextStyle(
//             //     color: typeColor,
//             //     fontWeight: FontWeight.bold,
//             //     fontSize: chipFontSize,
//             //   ),
//             // ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   dateStr,
//                   style: TextStyle(
//                     fontSize: dateFontSize,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   e.address,
//                   maxLines: verySmall ? 2 : 3,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: addrFontSize,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const Divider(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildLocationDetail(
//       String label,
//       String? address,
//       IconData icon,
//       Color iconColor, {
//         required double titleFontSize,
//         required double bodyFontSize,
//       }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 20, color: iconColor),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: titleFontSize,
//               ),
//             ),
//           ],
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 28.0, top: 4.0),
//           child: Text(
//             address ?? 'Not set yet…',
//             style: TextStyle(
//               fontSize: bodyFontSize,
//               fontStyle: address == null ? FontStyle.italic : FontStyle.normal,
//               color: address == null ? Colors.grey.shade600 : Colors.black87,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart' as loc;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geocoding/geocoding.dart';
import '../provider/auth_provider.dart';
import '../provider/journey_provider.dart';
import '../repo/odoo_json_rpc.dart';

// class JourneyScreen extends StatefulWidget {
//   const JourneyScreen({super.key});
//
//   @override
//   State<JourneyScreen> createState() => _JourneyScreenState();
// }
//
// class _JourneyScreenState extends State<JourneyScreen> {
//   final loc.Location _location = loc.Location();
//
//   bool isCheckedIn = false;
//   String? _startAddress;
//   String? _endAddress;
//
//   String _locationStatus = 'Ready';
//
//   Future<void> _handleCheckInOut() async {
//     final provider = context.read<JourneyProvider>();
//
//     setState(() => _locationStatus = "Fetching GPS...");
//
//     final data = await _location.getLocation();
//     if (data.latitude == null || data.longitude == null) {
//       setState(() => _locationStatus = "Error: GPS not found");
//       return;
//     }
//
//     final point = ll.LatLng(data.latitude!, data.longitude!);
//
//     setState(() => _locationStatus = "Resolving address...");
//     final address = await _getAddressFromLatLng(point);
//
//     final action = isCheckedIn ? "check_out" : "check_in";
//
//     await provider.performCheck(
//       action: action,
//       location: point,
//       address: address,
//     );
//
//     setState(() {
//       if (!isCheckedIn) {
//         _startAddress = address;
//         isCheckedIn = true;
//       } else {
//         _endAddress = address;
//         isCheckedIn = false;
//       }
//
//       _locationStatus = provider.error == null
//           ? "Live location updated"
//           : "Live location updated (server error)";
//     });
//   }
//
//   Future<String> _getAddressFromLatLng(ll.LatLng point) async {
//     try {
//       final placemarks =
//       await placemarkFromCoordinates(point.latitude, point.longitude);
//       if (placemarks.isNotEmpty) {
//         final p = placemarks.first;
//
//         final name = (p.name ?? '').trim();
//         final locality = (p.locality ?? '').trim();
//         final country = (p.country ?? '').trim();
//
//         final parts =
//         [name, locality, country].where((e) => e.isNotEmpty).toList();
//
//         return parts.isEmpty ? "Unknown Address" : parts.join(', ');
//       }
//     } catch (_) {}
//     return "Unknown Address";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<JourneyProvider>();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Add location"),
//         backgroundColor: Colors.indigo,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Main content scroll
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     _buildMainCard(provider),
//                     const SizedBox(height: 14),
//                     Text(
//                       _locationStatus,
//                       style: TextStyle(
//                         fontStyle: FontStyle.italic,
//                         color: _locationStatus.toLowerCase().contains("error")
//                             ? Colors.red
//                             : Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton.icon(
//                         onPressed: () {
//
//                         },
//                         icon: const Icon(Icons.map_outlined),
//                         label: const Text("VIEW MAP"),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           side: BorderSide(color: Colors.grey.shade300),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton.icon(
//                   onPressed: provider.isSaving ? null : _handleCheckInOut,
//                   icon: const Icon(Icons.search),
//                   label: Text(isCheckedIn ? "Check Out" : "Check In"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.indigo,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMainCard(JourneyProvider provider) {
//     return Card(
//       elevation: 6,
//       shadowColor: Colors.black12,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//
//             _locationRow(
//               icon: Icons.flag,
//               iconColor: Colors.indigo,
//               title: "Start Location:",
//               value: _startAddress ?? "Not set",
//             ),
//             const Divider(height: 18),
//
//
//             _locationRow(
//               icon: Icons.location_on,
//               iconColor: Colors.red,
//               title: "End Location:",
//               value: _endAddress ?? "Not set",
//             ),
//             const SizedBox(height: 12),
//
//             Text(
//               "Check-in / Check-out History",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 8),
//
//
//             if (provider.locations.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//                 child: Text(
//                   "No history yet",
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               )
//             else
//               ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: provider.locations.length,
//                 separatorBuilder: (_, __) => const Divider(height: 1),
//                 itemBuilder: (context, index) {
//                   final item = provider.locations[index];
//
//                   final dt = item.timestamp;
//                   final dateText =
//                       "${dt.year.toString().padLeft(4, '0')}-"
//                       "${dt.month.toString().padLeft(2, '0')}-"
//                       "${dt.day.toString().padLeft(2, '0')} "
//                       "${dt.hour.toString().padLeft(2, '0')}:"
//                       "${dt.minute.toString().padLeft(2, '0')}";
//
//                   return ListTile(
//                     dense: true,
//                     contentPadding: EdgeInsets.zero,
//                     leading: Container(
//                       width: 34,
//                       height: 34,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade200,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         item.action == "check_in"
//                             ? Icons.login
//                             : Icons.logout,
//                         size: 18,
//                         color: item.action == "check_in"
//                             ? Colors.green
//                             : Colors.red,
//                       ),
//                     ),
//                     title: Text(
//                       dateText,
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     subtitle: Text(
//                       item.address ??
//                           "Lat: ${item.latitude.toStringAsFixed(5)}, Lng: ${item.longitude.toStringAsFixed(5)}",
//                     ),
//                   );
//                 },
//               ),
//
//             if (provider.isSaving) ...[
//               const SizedBox(height: 10),
//               const LinearProgressIndicator(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _locationRow({
//     required IconData icon,
//     required Color iconColor,
//     required String title,
//     required String value,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: iconColor),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 value,
//                 style: TextStyle(color: Colors.grey[800]),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }


class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final loc.Location _location = loc.Location();

  bool isCheckedIn = false;
  String? _startAddress;
  String? _endAddress;
  Timer? _autoTimer;
  bool _autoRunning = false;

  String _locationStatus = 'Ready';
  bool _saving = false;

  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "https://demo.kendroo.com",
      sessionCookie: cookie,
    );
  }

  Future<ll.LatLng> _getLatLng() async {
    // Ensure GPS permission/service etc. (keep minimal; your existing setup may already handle)
    final data = await _location.getLocation();
    final lat = data.latitude;
    final lng = data.longitude;

    if (lat == null || lng == null) {
      throw Exception("GPS not found");
    }
    return ll.LatLng(lat, lng);
  }

  Future<void> _startJourney() async {
    final auth = context.read<AuthProvider>();
    final cookie = auth.sessionCookie;
    final uid = auth.user?.uid;

    if (cookie == null || uid == null) {
      setState(() => _locationStatus = "Error: Not logged in");
      return;
    }

    setState(() {
      _saving = true;
      _locationStatus = "Creating journey...";
    });

    try {
      // Only creates parent kio.field.force record
    //  await _rpc(cookie).startJourney(uid: uid);

      setState(() {
        // parent created; start/end will be set only after check-in/out
        _startAddress = null;
        _endAddress = null;
        isCheckedIn = false;
        _locationStatus = "Journey created ✅ Now Check In";
      });
    } catch (e) {
      setState(() => _locationStatus = "Server error: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteJourney() async {
    final auth = context.read<AuthProvider>();
    final cookie = auth.sessionCookie;
    final uid = auth.user?.uid;

    if (cookie == null || uid == null) {
      setState(() => _locationStatus = "Error: Not logged in");
      return;
    }

    setState(() {
      _saving = true;
      _locationStatus = "Deleting open journey...";
    });

    try {
      await _rpc(cookie).deleteOpenJourney(uid);

      setState(() {
        _startAddress = null;
        _endAddress = null;
        isCheckedIn = false;
        _locationStatus = "Deleted ✅";
      });
    } catch (e) {
      setState(() => _locationStatus = "Server error: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  void _startAutoUpdates() {
    _autoTimer?.cancel();
    _autoRunning = true;

    _autoTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _sendAutoLocationPing();
    });
  }

  void _stopAutoUpdates() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _autoRunning = false;
  }

  Future<void> _sendAutoLocationPing() async {
    final auth = context.read<AuthProvider>();
    final cookie = auth.sessionCookie;
    final uid = auth.user?.uid;

    if (cookie == null || uid == null) return;

    try {
      final point = await _getLatLng();
      final address = await _getAddressFromLatLng(point);

      final rpc = _rpc(cookie);
      await rpc.checkInCreateOrUpdate(
        uid: uid,
        startLocation: address,
        latitude: point.latitude,
        longitude: point.longitude,
        journeyTime: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _locationStatus = "Auto update sent ✅ (${DateTime.now().toLocal()})";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = "Auto update failed: $e";
        });
      }
    }
  }


  Future<void> _handleCheckInOut() async {
    final auth = context.read<AuthProvider>();
    final cookie = auth.sessionCookie;
    final uid = auth.user?.uid;

    if (cookie == null || uid == null) {
      setState(() => _locationStatus = "Error: Not logged in");
      return;
    }

    setState(() {
      _saving = true;
      _locationStatus = "Fetching GPS...";
    });

    try {
      // 1) get GPS
      final point = await _getLatLng();

      // 2) reverse geocode
      setState(() => _locationStatus = "Resolving address...");
      final address = await _getAddressFromLatLng(point);

      // 3) send to Odoo
      final rpc = _rpc(cookie);

      if (!isCheckedIn) {
        setState(() => _locationStatus = "Checking in...");

        await rpc.checkInCreateOrUpdate(
          uid: uid,
          startLocation: address,
          latitude: point.latitude,
          longitude: point.longitude,
           journeyTime: DateTime.now(),
        );

        setState(() {
          _startAddress = address;
          _endAddress = null;
          isCheckedIn = true;
          _locationStatus = "Check-in saved ✅";
        });

        _startAutoUpdates();
      } else {
        setState(() => _locationStatus = "Checking out...");

        await rpc.fieldForceCheckOut(
          uid: uid,
          endLocation: address,
          latitude: point.latitude,
          longitude: point.longitude,
           journeyTime: DateTime.now(),
        );

        setState(() {
          _endAddress = address;
          isCheckedIn = false;
          _locationStatus = "Check-out saved ✅";
        });
      }
    } catch (e) {
      setState(() => _locationStatus = "Server error: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<String> _getAddressFromLatLng(ll.LatLng point) async {
    try {
      final placemarks =
      await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final name = (p.name ?? '').trim();
        final locality = (p.locality ?? '').trim();
        final country = (p.country ?? '').trim();

        final parts =
        [name, locality, country].where((e) => e.isNotEmpty).toList();
        return parts.isEmpty ? "Unknown Address" : parts.join(', ');
      }
    } catch (_) {}
    return "Unknown Address";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add location"),
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMainCard(),
                    const SizedBox(height: 14),
                    Text(
                      _locationStatus,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: _locationStatus.toLowerCase().contains("error")
                            ? Colors.red
                            : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map_outlined),
                        label: const Text("VIEW MAP"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // START JOURNEY (parent create)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _startJourney,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Journey"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // CHECK IN / OUT (writes start/end + creates journey history lat/long)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _handleCheckInOut,
                  icon: Icon(isCheckedIn ? Icons.logout : Icons.login),
                  label: Text(isCheckedIn ? "Check Out" : "Check In"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // DELETE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _deleteJourney,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Card(
      elevation: 6,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _locationRow(
              icon: Icons.flag,
              iconColor: Colors.indigo,
              title: "Start Location:",
              value: _startAddress ?? "Not set",
            ),
            const Divider(height: 18),
            _locationRow(
              icon: Icons.location_on,
              iconColor: Colors.red,
              title: "End Location:",
              value: _endAddress ?? "Not set",
            ),
            if (_saving) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: Colors.grey[800])),
            ],
          ),
        ),
      ],
    );
  }
}

