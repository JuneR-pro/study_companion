import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class OverlayService {
  static const _channel = MethodChannel('study_companion/overlay');

  static Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<void> startOverlay({required String subject}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startOverlay', {'subject': subject});
    } catch (_) {}
  }

  static Future<void> updateOverlay({
    required String time,
    String? subject,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('updateOverlay', {
        'time': time,
        if (subject != null) 'subject': subject,
      });
    } catch (_) {}
  }

  static Future<void> stopOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopOverlay');
    } catch (_) {}
  }

  static Future<bool> isOverlayRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isOverlayRunning') ?? false;
    } catch (_) {
      return false;
    }
  }
}
