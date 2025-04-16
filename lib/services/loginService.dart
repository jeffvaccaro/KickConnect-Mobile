import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/config.dart';

class LoginService {
  final String baseUrl = Config.baseUrl;

  Future<void> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    final url = '$baseUrl/login/user-login';
    final body = jsonEncode({'email': email, 'password': password});
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: headers,
      );

      print(response.body); // Check if the response is successful

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', data['name']);
        await prefs.setString('token', data['token']);
        await prefs.setString('refreshToken', data['refreshToken']);
        await prefs.setString('accountCode', data['accountCode']);
        await prefs.setInt('accountId', data['accountId']);
        await prefs.setString('role', data['role']);
        await prefs.setInt(
          'expiry',
          DateTime.now().millisecondsSinceEpoch + 3600000,
        ); // Assuming the expiry is 1 hour from login

        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred')));
    }
  }

  Future<String> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/refresh-token'),
      body: jsonEncode({'refreshToken': refreshToken}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newToken = data['token'];
      await prefs.setString('token', newToken);
      await prefs.setInt(
        'expiry',
        DateTime.now().millisecondsSinceEpoch + 3600000,
      ); // Update the expiry time
      return newToken;
    } else {
      throw Exception('Failed to refresh token');
    }
  }
}
