import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class Log {
  static const bool isLog = kDebugMode;
  static final logger = Logger();

  static void t(dynamic message) {
    if (isLog) logger.t(message);
  }

  static void d(dynamic message) {
    if (isLog) logger.d(message);
  }

  static void i(dynamic message) {
    if (isLog) logger.i(message);
  }

  static void w(dynamic message) {
    if (isLog) logger.w(message);
  }

  static void e(dynamic message) {
    if (isLog) logger.e(message);
  }
}
