import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class OverlayService {
  static const _channel = MethodChannel('study_companion/overlay');

  static Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('canDrawOverlays');
      print('[OverlayService] canDrawOverlays: $result');
      return result ?? false;
    } catch (e) {
      print('[OverlayService] canDrawOverlays error: $e');
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    try {
      print('[OverlayService] requestOverlayPermission called');
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print('[OverlayService] requestOverlayPermission error: $e');
    }
  }

  static Future<void> startOverlay({required String subject}) async {
    if (!Platform.isAndroid) return;
    try {
      print('[OverlayService] startOverlay called with subject: $subject');
      await _channel.invokeMethod('startOverlay', {'subject': subject});
      print('[OverlayService] startOverlay success');
    } catch (e) {
      print('[OverlayService] startOverlay error: $e');
    }
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
    } catch (e) {
      print('[OverlayService] updateOverlay error: $e');
    }
  }

  static Future<void> stopOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      print('[OverlayService] stopOverlay called');
      await _channel.invokeMethod('stopOverlay');
    } catch (e) {
      print('[OverlayService] stopOverlay error: $e');
    }
  }

  static Future<bool> isOverlayRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayRunning');
      print('[OverlayService] isOverlayRunning: $result');
      return result ?? false;
    } catch (e) {
      print('[OverlayService] isOverlayRunning error: $e');
      return false;
    }
  }
}
