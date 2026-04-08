import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/employee_model.dart';

class EmployeeRepository {
  static const String baseUrl = 'http://72.61.250.60:8069';
  final String sessionCookie;

  EmployeeRepository(this.sessionCookie);

  Future<EmployeeResponse> fetchEmployeeProfile() async {
    final url = Uri.parse('$baseUrl/api/my/employee');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': sessionCookie,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EmployeeResponse.fromJson(data);
    } else {
      throw Exception('Failed to load employee data');
    }
  }
}
