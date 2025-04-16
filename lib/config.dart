import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Use localhost for web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Use 10.0.2.2 for Android emulator
    } else {
      return 'http://localhost:3000'; // Use localhost for other platforms
    }
  }
}
