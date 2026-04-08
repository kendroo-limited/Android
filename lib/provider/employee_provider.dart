
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/employee_model.dart';
import '../repo/odoo_json_rpc.dart';
import 'auth_provider.dart';

class EmployeeProvider extends ChangeNotifier {
  final AuthProvider? auth;
  EmployeeProvider(this.auth);

  EmployeeResponse? _profile;
  bool _isLoading = false;
  String? _error;

  EmployeeResponse? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile() async {
    if (auth?.sessionCookie == null) {
      _error = 'No session cookie found';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('http://72.61.250.60:8069/api/my/employee');
      final cookie = auth!.sessionCookie!;

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookie,
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {},
          "id": null,
        }),
      );

      debugPrint('➡️ [Employee] POST $url');
      debugPrint('➡️ [Employee] Cookie: $cookie');
      debugPrint('⬅️ [Employee] Response: ${res.statusCode} ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _profile = EmployeeResponse.fromJson(data);

        // Optional: debug what the image URL actually returns
        await _debugImageFetch(_profile!.employee, cookie);
      } else {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e, st) {
      debugPrint('❌ [EmployeeProvider] Error: $e\n$st');
      _error = 'Exception: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _debugImageFetch(Employee emp, String cookie) async {
    if (emp.imageUrl.isEmpty) {
      debugPrint('🖼 Employee has no imageUrl');
      return;
    }

    final fullUrl = 'http://72.61.250.60:8069${emp.imageUrl}';
    try {
      final imgRes = await http.get(
        Uri.parse(fullUrl),
        headers: {'Cookie': cookie},
      );
      debugPrint('🖼 IMAGE URL: $fullUrl');
      debugPrint('🖼 IMAGE status: ${imgRes.statusCode}');
      debugPrint('🖼 IMAGE content-type: ${imgRes.headers['content-type']}');

      final body = imgRes.body;
      if (body.isNotEmpty) {
        final len = body.length;
        final preview = body.substring(0, len > 200 ? 200 : len);
        debugPrint('🖼 IMAGE body preview: $preview');
      }
    } catch (e, st) {
      debugPrint('🟥 Image debug failed: $e\n$st');
    }
  }
}


