import 'dart:convert';
import 'package:http/http.dart' as http;

// class OdooSessionRpc {
//   final String baseUrl;
//   final String sessionCookie;
//
//   OdooSessionRpc({
//     required this.baseUrl,
//     required this.sessionCookie,
//   });
//
//   Future<dynamic> callKw({
//     required String model,
//     required String method,
//     List args = const [],
//     Map<String, dynamic> kwargs = const {},
//   }) async {
//     final url = Uri.parse('$baseUrl/web/dataset/call_kw/$model/$method');
//
//     final payload = {
//       "jsonrpc": "2.0",
//       "method": "call",
//       "params": {
//         "model": model,
//         "method": method,
//         "args": args,
//         "kwargs": kwargs,
//       },
//       "id": DateTime.now().millisecondsSinceEpoch,
//     };
//
//     final res = await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//         "Cookie": sessionCookie,
//       },
//       body: jsonEncode(payload),
//     );
//
//     final data = jsonDecode(res.body);
//
//     if (data["error"] != null) {
//       final msg = data["error"]["data"]?["message"] ?? data["error"]["message"];
//       throw Exception(msg);
//     }
//
//     return data["result"];
//   }
//
//   Future<int> getEmployeeId(int uid) async {
//     final result = await callKw(
//       model: "hr.employee",
//       method: "search_read",
//       args: [
//         [
//           ["user_id", "=", uid]
//         ]
//       ],
//       kwargs: {"fields": ["id"], "limit": 1},
//     );
//
//     if ((result as List).isEmpty) {
//       throw Exception("No employee linked to this user (Employee → Related User missing)");
//     }
//     return result[0]["id"] as int;
//   }
//
//   Future<int> startJourney({
//     required int uid,
//
//   }) async {
//     final employeeId = await getEmployeeId(uid);
//
//     final newId = await callKw(
//       model: "kio.field.force",
//       method: "create",
//       args: [
//         {
//           "employee_id": employeeId,
//           "start_location": null,
//         }
//       ],
//     );
//
//
//
//     return newId as int;
//   }
//
//   Future<int> fieldForceCheckIn({
//     required int uid,
//     required String startLocation,
//   }) async {
//     final employeeId = await getEmployeeId(uid);
//
//     final open = await callKw(
//       model: "kio.field.force",
//       method: "search_read",
//       args: [
//         [
//           ["employee_id", "=", employeeId],
//           ["start_location", "=", false],
//         ]
//       ],
//       kwargs: {"fields": ["id"], "order": "id desc", "limit": 1},
//     );
//
//     if ((open as List).isEmpty) {
//       throw Exception("No open journey found (already checked out / not checked in)");
//     }
//
//     final id = open[0]["id"] as int;
//
//     await callKw(
//       model: "kio.field.force",
//       method: "write",
//       args: [
//         [id],
//         {"start_location": startLocation},
//       ],
//     );
//     return id;
//   }
//
//   Future<void> fieldForceCheckOut({
//     required int uid,
//     required String endLocation,
//   }) async {
//     final employeeId = await getEmployeeId(uid);
//
//     final open = await callKw(
//       model: "kio.field.force",
//       method: "search_read",
//       args: [
//         [
//           ["employee_id", "=", employeeId],
//           ["end_location", "=", false],
//         ]
//       ],
//       kwargs: {"fields": ["id"], "order": "id desc", "limit": 1},
//     );
//
//     if ((open as List).isEmpty) {
//       throw Exception("No open journey found (already checked out / not checked in)");
//     }
//
//     final id = open[0]["id"] as int;
//
//     await callKw(
//       model: "kio.field.force",
//       method: "write",
//       args: [
//         [id],
//         {"end_location": endLocation},
//       ],
//     );
//   }
//
//
//   Future<void> deleteOpenJourney(int uid) async {
//     final employeeId = await getEmployeeId(uid);
//
//     final open = await callKw(
//       model: "kio.field.force",
//       method: "search_read",
//       args: [
//         [
//           ["employee_id", "=", employeeId],
//           ["end_location", "=", false],
//         ]
//       ],
//       kwargs: {
//         "fields": ["id"],
//         "order": "id desc",
//         "limit": 1,
//       },
//     );
//
//     if ((open as List).isEmpty) {
//       throw Exception("No open journey found");
//     }
//
//     final id = open[0]["id"] as int;
//
//     await callKw(
//       model: "kio.field.force",
//       method: "unlink",
//       args: [
//         [id]
//       ],
//     );
//   }
//
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

class OdooSessionRpc {
  final String baseUrl;
  final String sessionCookie;

  OdooSessionRpc({
    required this.baseUrl,
    required this.sessionCookie,
  });

  Future<dynamic> callKw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    final url = Uri.parse('$baseUrl/web/dataset/call_kw/$model/$method');

    final payload = {
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "model": model,
        "method": method,
        "args": args,
        "kwargs": kwargs,
      },
      "id": DateTime.now().millisecondsSinceEpoch,
    };

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": sessionCookie,
      },
      body: jsonEncode(payload),
    );

    final data = jsonDecode(res.body);

    if (data["error"] != null) {
      final msg = data["error"]["data"]?["message"] ?? data["error"]["message"];
      throw Exception(msg);
    }

    return data["result"];
  }


  String _toOdooDatetime(DateTime dt) {
    final u = dt.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return "${u.year}-${two(u.month)}-${two(u.day)} ${two(u.hour)}:${two(u.minute)}:${two(u.second)}";
  }

  Future<int> getEmployeeId(int uid) async {
    final result = await callKw(
      model: "hr.employee",
      method: "search_read",
      args: [
        [
          ["user_id", "=", uid]
        ]
      ],
      kwargs: {"fields": ["id"], "limit": 1},
    );

    if ((result as List).isEmpty) {
      throw Exception("No employee linked to this user (Employee → Related User missing)");
    }
    return result[0]["id"] as int;
  }


  Future<int> _getOpenJourneyId(int employeeId) async {
    final open = await callKw(
      model: "kio.field.force",
      method: "search_read",
      args: [
        [
          ["employee_id", "=", employeeId],
          ["end_location", "=", false],
        ]
      ],
      kwargs: {"fields": ["id"], "order": "id desc", "limit": 1},
    );

    if ((open as List).isEmpty) {
      throw Exception("No open journey found");
    }
    return open[0]["id"] as int;
  }

  Future<int> addJourneyHistoryLine({
    required int fieldForceId,
    required double latitude,
    required double longitude,
    required String location,
    DateTime? journeyTime,

  }) async {
    const linkField = "field_force_id";

      final lineId = await callKw(
        model: "kio.field.force.journey",
        method: "create",
        args: [
          {
            linkField: fieldForceId,
            "journey_time": _toOdooDatetime(journeyTime ?? DateTime.now()),
            "latitude": latitude,
            "longitude": longitude,
            "location": location,
          }
        ],
      );

    return lineId as int;
  }


  Future<int> checkInCreateOrUpdate({
    required int uid,
    required String startLocation,
    required double latitude,
    required double longitude,
    DateTime? journeyTime,
  }) async {
    final employeeId = await getEmployeeId(uid);

    final open = await callKw(
      model: "kio.field.force",
      method: "search_read",
      args: [
        [
          ["employee_id", "=", employeeId],
        //  "|",
        //  ["end_location", "=", false],
       //   ["end_location", "=", ""],
        ]
      ],
      kwargs: {
        "fields": ["id", "start_location", "check_in_time", "end_location"],
        "order": "id desc",
        "limit": 1
      },
    );

    final now = _toOdooDatetime(journeyTime ?? DateTime.now());

    int fieldForceId;

    if ((open as List).isEmpty) {

      final newId = await callKw(
        model: "kio.field.force",
        method: "create",
        args: [
          {
            "employee_id": employeeId,
            "start_location": startLocation,
            "check_in_time": now,
          }
        ],
      );
      fieldForceId = newId as int;
    } else {
      fieldForceId = open[0]["id"] as int;

      final existingStart = open[0]["start_location"];
      final existingCheckIn = open[0]["check_in_time"];

      final valsToWrite = <String, dynamic>{};

      final isEmptyStart = (existingStart == false ||
          existingStart == null ||
          (existingStart is String && existingStart.trim().isEmpty));
      final isEmptyCheckIn = (existingCheckIn == false || existingCheckIn == null);

      if (isEmptyStart) valsToWrite["start_location"] = startLocation;
      if (isEmptyCheckIn) valsToWrite["check_in_time"] = now;

      // if (valsToWrite.isNotEmpty) {
      //   await callKw(
      //     model: "kio.field.force",
      //     method: "write",
      //     args: [
      //       [fieldForceId],
      //       valsToWrite,
      //     ],
      //   );
      // }
    }


    await addJourneyHistoryLine(
      fieldForceId: fieldForceId,
      latitude: latitude,
      longitude: longitude,
      location: startLocation,
      journeyTime: journeyTime,
    );

    return fieldForceId;
  }


  Future<void> fieldForceCheckOut({
    required int uid,
    required String endLocation,
    required double latitude,
    required double longitude,
    DateTime? journeyTime,
  }) async {
    final employeeId = await getEmployeeId(uid);

    final open = await callKw(
      model: "kio.field.force",
      method: "search_read",
      args: [
        [
          ["employee_id", "=", employeeId],
         // "|",
       //   ["end_location", "=", false],
       //   ["end_location", "=", ""],
        ]
      ],
      kwargs: {
        "fields": ["id", "check_out_time", "end_location"],
        "order": "id desc",
        "limit": 1
      },
    );

    if ((open as List).isEmpty) {
      throw Exception("No open journey found (already checked out / not checked in)");
    }

    final id = open[0]["id"] as int;
    final now = _toOdooDatetime(journeyTime ?? DateTime.now());

    // await callKw(
    //   model: "kio.field.force",
    //   method: "write",
    //   args: [
    //     [id],
    //     {
    //       "end_location": endLocation,
    //       "check_out_time": now,
    //     },
    //   ],
    // );

    // await addJourneyHistoryLine(
    //   fieldForceId: id,
    //   latitude: latitude,
    //   longitude: longitude,
    //   location: endLocation,
    //   journeyTime: journeyTime,
    // );
  }


  Future<void> deleteOpenJourney(int uid) async {
    final employeeId = await getEmployeeId(uid);
    final id = await _getOpenJourneyId(employeeId);

    await callKw(
      model: "kio.field.force",
      method: "unlink",
      args: [
        [id]
      ],
    );
  }
}


