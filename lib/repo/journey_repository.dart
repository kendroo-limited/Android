import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../model/journey_model.dart';

// class JourneyRepository {
//   final String baseUrl;
//   final http.Client _client;
//
//   JourneyRepository({
//     required this.baseUrl,
//     http.Client? client,
//   }) : _client = client ?? http.Client();
//
//
//   Future<Journey> saveJourney(Journey journey) async {
//     final url = Uri.parse('$baseUrl/api/field_force/check');
//
//
//     final response = await _client.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(journey.toJson()),
//     );
//
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       final Map<String, dynamic> data = jsonDecode(response.body);
//       return Journey.fromJson(data);
//     } else {
//       throw Exception(
//         'Failed to save journey (status: ${response.statusCode}): ${response.body}',
//       );
//     }
//   }
//
//
//   Future<List<Journey>> fetchJourneys({int page = 1, int limit = 20}) async {
//     final url = Uri.parse('$baseUrl/journeys?page=$page&limit=$limit');
//
//     final response = await _client.get(url);
//
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data
//           .map((item) => Journey.fromJson(item as Map<String, dynamic>))
//           .toList();
//     } else {
//       throw Exception(
//         'Failed to fetch journeys (status: ${response.statusCode}): ${response.body}',
//       );
//     }
//   }
//
//
//   Future<Journey> fetchJourneyById(String id) async {
//     final url = Uri.parse('$baseUrl/journeys/$id');
//
//     final response = await _client.get(url);
//
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       final Map<String, dynamic> data = jsonDecode(response.body);
//       return Journey.fromJson(data);
//     } else {
//       throw Exception(
//         'Failed to fetch journey (status: ${response.statusCode}): ${response.body}',
//       );
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/journey_model.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class FieldForceRepository {
  final String baseUrl;
  final String sessionCookie;

  FieldForceRepository({required this.baseUrl,required this.sessionCookie,});


  Future<CheckInResponse> postCheckIn(CheckInRequest data, {String? address}) async {
    debugPrint("✅ postCheckIn() entered");
    final url = Uri.parse('$baseUrl/api/field_force/check');


    debugPrint("📤 Posting Check-In:");
    debugPrint("➡️ Action     : ${data.action}");
    debugPrint("➡️ Latitude   : ${data.latitude}");
    debugPrint("➡️ Longitude  : ${data.longitude}");
    debugPrint("➡️ Timestamp  : ${data.timestamp}");
    debugPrint("➡️ Address    : ${address ?? 'N/A'}");
    debugPrint("➡️ URL        : $url");
    debugPrint("➡️ Payload    : ${jsonEncode(data.toJson())}");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      debugPrint("📥 Server Response:");
      debugPrint("⬅️ Status Code: ${response.statusCode}");
      debugPrint("⬅️ Body       : ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return CheckInResponse.fromJson(responseData, address: address);
      } else {
        throw Exception('Server Error: ${response.statusCode} | ${response.body}');
      }
    } catch (e, st) {
      debugPrint("❌ Connection Failed: $e");
      debugPrint("❌ StackTrace: $st");
      rethrow;
    }
  }

}
