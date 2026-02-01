import 'package:flutter/foundation.dart';
import '../model/journey_model.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../repo/journey_repository.dart';


// class JourneyProvider extends ChangeNotifier {
//   final JourneyRepository _repository;
//
//   JourneyProvider(this._repository);
//
//   Journey? _current;
//   List<Journey> _history = [];
//   bool _isSaving = false;
//   String? _error;
//
//   Journey? get current => _current;
//   List<Journey> get history => List.unmodifiable(_history);
//   bool get isSaving => _isSaving;
//   String? get error => _error;
//
//
//   void initJourney({
//     required ll.LatLng startLocation,
//     required String startAddress,
//   }) {
//     _current = Journey(
//       startLocation: startLocation,
//       startAddress: startAddress,
//       endLocation: null,
//       endAddress: null,
//       distanceInMeters: null,
//       events: [],
//       startedAt: DateTime.now(),
//       endedAt: null,
//     );
//     _error = null;
//     notifyListeners();
//   }
//
//
//
//   void addCheckEvent({
//     required String type,
//     required ll.LatLng location,
//     required String address,
//     bool isAuto = false,
//   }) {
//     _current?.events.add(
//       JourneyCheckEvent(
//         type: type,
//         location: location,
//         address: address,
//         timestamp: DateTime.now(),
//         isAuto: isAuto,
//       ),
//     );
//     notifyListeners();
//   }
//
//
//   void completeJourney({
//     required ll.LatLng endLocation,
//     required String endAddress,
//     double? distanceInMeters,
//   }) {
//     if (_current == null) return;
//
//     _current = _current!.copyWith(
//       endLocation: endLocation,
//       endAddress: endAddress,
//       distanceInMeters: distanceInMeters,
//       endedAt: DateTime.now(),
//     );
//     notifyListeners();
//   }
//
//
//   Future<void> saveCurrentJourney() async {
//     if (_current == null) return;
//
//     _isSaving = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       final saved = await _repository.saveJourney(_current!);
//       _history.insert(0, saved);
//       _current = null;
//     } catch (e) {
//       _error = e.toString();
//       if (kDebugMode) {
//         print('Error saving journey: $e');
//       }
//     } finally {
//       _isSaving = false;
//       notifyListeners();
//     }
//   }
//
//
//   Future<void> loadHistory() async {
//     _isSaving = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       final journeys = await _repository.fetchJourneys();
//       _history = journeys;
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _isSaving = false;
//       notifyListeners();
//     }
//   }
//
//
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
// }
class JourneyProvider extends ChangeNotifier {
  final FieldForceRepository _repository;
  final String _authToken;

  JourneyProvider({
    required FieldForceRepository repository,
    required String authToken,
  })  : _repository = repository,
        _authToken = authToken;

  CheckInResponse? _lastResponse;
  final List<CheckInResponse> _history = [];
  final List<CheckInLocation> _locations = [];
  bool _isSaving = false;
  String? _error;

  CheckInResponse? get lastResponse => _lastResponse;
  List<CheckInResponse> get history => List.unmodifiable(_history);
  List<CheckInLocation> get locations => List.unmodifiable(_locations);
  bool get isSaving => _isSaving;
  String? get error => _error;


  Future<void> performCheck({
    required String action,
    required ll.LatLng location,
    String? address,
  }) async {
    debugPrint("✅ performCheck called: action=$action, lat=${location.latitude}, lng=${location.longitude}");
    _isSaving = true;
    _error = null;

    final now = DateTime.now();


    _locations.insert(
      0,
      CheckInLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: now,
        action: action,
        address: address
      ),
    );

    notifyListeners();

    try {
      final request = CheckInRequest(
        token: _authToken,
        action: action,
        timestamp: now.toIso8601String(),
        latitude: location.latitude,
        longitude: location.longitude,
      );

      final response = await _repository.postCheckIn(request, address: address);


      if (response.ok) {
        _lastResponse = response;
        _history.insert(0, response);
      } else {
        _error = "Server returned ok: false";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }


  // void completeJourney({
  //   required ll.LatLng endLocation,
  //   required String endAddress,
  //   double? distanceInMeters,
  // }) {
  //   if (_current == null) return;
  //
  //   _current = _current!.copyWith(
  //     endLocation: endLocation,
  //     endAddress: endAddress,
  //     distanceInMeters: distanceInMeters,
  //     endedAt: DateTime.now(),
  //   );
  //   notifyListeners();
  // }
  //
  //
  // Future<void> saveCurrentJourney() async {
  //   if (_current == null) return;
  //
  //   _isSaving = true;
  //   _error = null;
  //   notifyListeners();
  //
  //   try {
  //     final saved = await _repository.saveJourney(_current!);
  //     _history.insert(0, saved);
  //     _current = null;
  //   } catch (e) {
  //     _error = e.toString();
  //     if (kDebugMode) {
  //       print('Error saving journey: $e');
  //     }
  //   } finally {
  //     _isSaving = false;
  //     notifyListeners();
  //   }
  // }
  //
  //
  // Future<void> loadHistory() async {
  //   _isSaving = true;
  //   _error = null;
  //   notifyListeners();
  //
  //   try {
  //     final journeys = await _repository.fetchJourneys();
  //     _history = journeys;
  //   } catch (e) {
  //     _error = e.toString();
  //   } finally {
  //     _isSaving = false;
  //     notifyListeners();
  //   }
  // }


  void clearError() {
    _error = null;
    notifyListeners();
  }
}

