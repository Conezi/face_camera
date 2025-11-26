import 'package:flutter/material.dart';

void logError(String message, [String? code]) {
  if (code != null) {
    debugPrint('Face Camera Error: $code\nError Message: $message');
  } else {
    debugPrint('Face Camera Error: $code');
  }
}
