import 'package:flutter/material.dart';
import 'package:mobile/screens/login-screen.dart';
import 'screens/main-screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/':
            (context) => FutureBuilder<bool>(
              future: _checkLoginStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  return snapshot.data!
                      ? FutureBuilder<Map<String, dynamic>>(
                        future: _getApiResponse(),
                        builder: (context, apiResponseSnapshot) {
                          if (apiResponseSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (apiResponseSnapshot.hasData) {
                            return MainScreen(
                              apiResponse: apiResponseSnapshot.data!,
                            );
                          } else {
                            return LoginScreen();
                          }
                        },
                      )
                      : LoginScreen();
                }
              },
            ),
        '/main':
            (context) => FutureBuilder<Map<String, dynamic>>(
              future: _getApiResponse(),
              builder: (context, apiResponseSnapshot) {
                if (apiResponseSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (apiResponseSnapshot.hasData) {
                  return MainScreen(apiResponse: apiResponseSnapshot.data!);
                } else {
                  return LoginScreen();
                }
              },
            ),
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final expiryDate = prefs.getInt('expiry') ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < expiryDate) {
        return true;
      } else {
        await _refreshToken();
        return prefs.getString('token') != null;
      }
    }
    return false;
  }

  Future<void> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken != null) {
      final response = await http.post(
        Uri.parse('http://localhost:3000/auth/refresh-token'),
        body: jsonEncode({'refreshToken': refreshToken}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final newTokens = json.decode(response.body);
        await prefs.setString('token', newTokens['token']);
        await prefs.setInt(
          'expiry',
          DateTime.now().millisecondsSinceEpoch + 3600000,
        ); // Update the expiry time
      } else {
        await prefs.remove('token');
        await prefs.remove('refreshToken');
      }
    }
  }

  Future<Map<String, dynamic>> _getApiResponse() async {
    final prefs = await SharedPreferences.getInstance();
    print('Debug: Fetching API Response from SharedPreferences');
    print(
      'Debug: Name - ${prefs.getString('name')}, Role - ${prefs.getString('role')}, AccountId - ${prefs.getInt('accountId')}, Token - ${prefs.getString('token')}',
    );
    return {
      "name": prefs.getString('name') ?? '',
      "auth": true,
      "token": prefs.getString('token') ?? '',
      "refreshToken": prefs.getString('refreshToken') ?? '',
      "accountCode": prefs.getString('accountCode') ?? '',
      "accountId": prefs.getInt('accountId') ?? 0,
      "role": prefs.getString('role') ?? '',
    };
  }
}
