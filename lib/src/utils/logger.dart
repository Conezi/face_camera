import 'package:flutter/material.dart';

void logError(String message, [String? code]) {
  if (code != null) {
    debugPrint('Error: $code\nError Message: $message');
  } else {
    debugPrint('Error: $code');
  }
}
