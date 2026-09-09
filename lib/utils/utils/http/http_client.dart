import 'dart:convert';
import 'package:http/http.dart' as http;

class VoidHttpClient {
  static const String _baseUrl = "https://jsapi.maxbitz.com/api";

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, dynamic data) async {
    //print('$_baseUrl/$endpoint');

    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),

      // headers: {'Content-Type': 'application/json'},
      //body: json.encode(data),
      body: data,
    );

    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$endpoint'),
    );
    return handleResponse(response);
  }

  static Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 422 ||
        response.statusCode == 404) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
