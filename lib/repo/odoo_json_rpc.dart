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
    ).timeout(const Duration(seconds: 40));

    final data = jsonDecode(res.body);

    if (data["error"] != null) {
      final msg = data["error"]["data"]?["message"] ?? data["error"]["message"];
      throw Exception(msg);
    }

    return data["result"];
  }
  Future<int> getLatestFieldForceIdForUser(int uid) async {
    final employeeId = await getEmployeeId(uid);

    final rows = await callKw(
      model: "kio.field.force",
      method: "search_read",
      args: [[["employee_id", "=", employeeId]]],
      kwargs: {"fields": ["id"], "order": "id desc", "limit": 1},
    );

    if ((rows as List).isEmpty) throw Exception("No field force record found");
    return rows[0]["id"] as int;
  }

  Future<List<Map<String, dynamic>>> fetchJourneyHistory({
    required int fieldForceId,
    int limit = 50,
    int offset = 0,
    String order = "journey_time desc",
    DateTime? from,
    DateTime? to,
  }) async {
    final domain = <dynamic>[
      ["field_force_id", "=", fieldForceId],
    ];

    if (from != null) {
      domain.add(["journey_time", ">=", _toOdooDatetime(from)]);
    }
    if (to != null) {
      domain.add(["journey_time", "<=", _toOdooDatetime(to)]);
    }

    final result = await callKw(
      model: "kio.field.force.journey",
      method: "search_read",
      args: [domain],
      kwargs: {
        "fields": ["id", "journey_time", "latitude", "longitude", "location"],
        "order": order,
        "limit": limit,
        "offset": offset,
      },
    );

    return (result as List).cast<Map<String, dynamic>>();
  }


  Future<DateTime?> fetchCheckInTime({
    required String cookie,
    required int uid,
  }) async {
    final rpc = OdooSessionRpc(
      baseUrl: baseUrl,
      sessionCookie: cookie,
    );

    final rows = await rpc.callKw(
      model: "kio.field.force",
      method: "search_read",
      args: [],
      kwargs: {
        "domain": [
          ["employee_id.user_id", "=", uid],
        ],
        "fields": ["check_in_time"],
        "limit": 1,
        "order": "id desc"
      },
    );

    if (rows.isEmpty) return null;

    final timeStr = rows[0]["check_in_time"];
    if (timeStr == null) return null;

    return DateTime.tryParse(timeStr.replaceFirst(' ', 'T'));
  }

  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
    Map<String, dynamic> context = const {},
  }) async {
    final result = await callKw(
      model: model,
      method: "create",
      args: [values],
      kwargs: {
        "context": context,
      },
    );

    if (result is int) return result;


    final parsed = int.tryParse(result?.toString() ?? "");
    if (parsed != null) return parsed;

    throw Exception("Create failed: unexpected result: $result");
  }

  Future<List<Map<String, dynamic>>> fetchLatestJourneyHistoryForUser({
    required int uid,
    int limit = 50,
    int offset = 0,
    String order = "journey_time desc",
  }) async {
    final employeeId = await getEmployeeId(uid);

    final journeys = await callKw(
      model: "kio.field.force",
      method: "search_read",
      args: [
        [
          ["employee_id", "=", employeeId],
        ]
      ],
      kwargs: {
        "fields": ["id"],
        "order": "id desc",
        "limit": 1,
      },
    );

    if ((journeys as List).isEmpty) return [];

    final fieldForceId = journeys[0]["id"] as int;

    return fetchJourneyHistory(
      fieldForceId: fieldForceId,
      limit: limit,
      offset: offset,
      order: order,
    );
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
        ]
      ],
      kwargs: {
        "fields": ["id", "check_out_time", "end_location"],
        "order": "id desc",
        "limit": 1,
      },
    );

    if ((open as List).isEmpty) {
      throw Exception("No journey found");
    }

    final id = open[0]["id"] as int;


    final alreadyOut = open[0]["check_out_time"];
    if (alreadyOut != null && alreadyOut != false && alreadyOut.toString().isNotEmpty) {
      throw Exception("Already checked out");
    }

    final now = _toOdooDatetime(journeyTime ?? DateTime.now());


    final ok = await callKw(
      model: "kio.field.force",
      method: "write",
      args: [
        [id],
        {
          "check_out_time": now,
         // "end_location": endLocation,
          //"end_latitude": latitude,
         // "end_longitude": longitude,
        }
      ],
      kwargs: {},
    );

    if (ok != true) {
      throw Exception("Checkout failed");
    }
  }

  // Future<void> deleteOpenJourney(int uid) async {
  //   final employeeId = await getEmployeeId(uid);
  //   final id = await _getOpenJourneyId(employeeId);
  //
  //   await callKw(
  //     model: "kio.field.force",
  //     method: "unlink",
  //     args: [
  //       [id]
  //     ],
  //   );
  // }

  Future<List<Map<String, dynamic>>> fetchEmployeeData({
    required List<dynamic> domain,
    required List<String> fields,
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await callKw(
      model: "hr.employee",
      method: "search_read",
      args: [domain],
      kwargs: {
        "fields": fields,
        "limit": limit,
        "offset": offset,
      },
    );
    return (result as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List<dynamic> domain = const [],
    required List<String> fields,
    int limit = 0,
    int offset = 0,
    String? order,
    Map<String, dynamic>? context,
  }) async {
    final kwargs = <String, dynamic>{
      "fields": fields,
      "offset": offset,
    };

    if (limit > 0) kwargs["limit"] = limit;
    if (order != null && order.trim().isNotEmpty) kwargs["order"] = order;
    if (context != null && context.isNotEmpty) kwargs["context"] = context;

    final result = await callKw(
      model: model,
      method: "search_read",
      args: [domain],
      kwargs: kwargs,
    );

    return (result as List).cast<Map<String, dynamic>>();
  }


  Future<bool> write({
    required String model,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    final result = await callKw(
      model: model,
      method: "write",
      args: [ids, values],
    );

    return result == true;
  }

}

