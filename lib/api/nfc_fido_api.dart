import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:twokey/api/fido_api.dart';
import 'package:twokey/common/app_logger.dart';
import 'package:twokey/common/system.dart' as system;

/// NFC implementation of the FIDO API using flutter_nfc_kit.
/// 
/// This class provides FIDO2 communication over NFC using the flutter_nfc_kit
/// package. It handles the transient nature of NFC connections by implementing
/// automatic reconnection strategies and proper lifecycle management.
/// 
/// Key features:
/// - Automatic NFC tag detection and FIDO2 application selection
/// - Robust error handling for transient connections
/// - Platform-aware availability checking (mobile devices only)
/// - Enhanced reconnection capabilities for lost connections
class NfcFidoApi implements FidoApi {
  NFCTag? _tag;

  @override
  Future<void> connect() async {
    // Check if NFC is available
    final availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      throw Exception('NFC is not available on this device');
    }

    // Poll for NFC tags
    AppLogger.debug('Polling for NFC tags...');
    try {
      _tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple FIDO2 keys detected",
        iosAlertMessage: "Hold your FIDO2 key near the device",
      );
    } catch (e) {
      AppLogger.error('Failed to poll NFC tags: $e');
      throw Exception('Failed to detect NFC tag. Please ensure your FIDO2 key is near the device and try again.');
    }

    if (_tag == null) {
      throw Exception('No NFC tag found. Please hold your FIDO2 key near the device.');
    }

    AppLogger.debug('NFC tag detected: ${_tag!.type}, ID: ${_tag!.id}');

    // Try to select the FIDO2 application
    const fidoAid = 'A0000006472F0001';
    final selectApdu = '00A4040008$fidoAid';
    AppLogger.debug('--> SELECT FIDO App: $selectApdu');
    
    final response = await FlutterNfcKit.transceive(selectApdu);
    AppLogger.debug('<-- SELECT Response: $response');

    if (response == null || !response.endsWith('9000')) {
      await disconnect(); // Clean up the connection
      throw Exception(
        'Failed to select FIDO2 application. Response: $response',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_tag != null) {
      await FlutterNfcKit.finish();
      _tag = null;
      AppLogger.debug('NFC connection closed');
    }
  }

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    if (_tag == null) {
      throw Exception('NFC tag not connected');
    }

    try {
      final commandHex = hex.encode(command);
      AppLogger.debug('--> NFC Command: $commandHex');
      
      final responseHex = await FlutterNfcKit.transceive(commandHex);
      if (responseHex == null) {
        throw Exception('Received null response from NFC tag');
      }
      
      AppLogger.debug('<-- NFC Response: $responseHex');
      return Uint8List.fromList(hex.decode(responseHex));
    } catch (e) {
      AppLogger.error('NFC transceive error: $e');
      // For NFC, connection might be lost, so we should mark as disconnected
      _tag = null;
      rethrow;
    }
  }

  /// Re-establish NFC connection if it was lost
  Future<void> _reconnectIfNeeded() async {
    if (_tag == null) {
      await connect();
    }
  }

  /// Enhanced transceive with automatic reconnection for transient NFC
  Future<Uint8List> transceiveWithReconnect(Uint8List command) async {
    try {
      return await transceive(command);
    } catch (e) {
      AppLogger.debug('NFC transaction failed, attempting to reconnect: $e');
      // Try to reconnect once for transient NFC connections
      try {
        await _reconnectIfNeeded();
        return await transceive(command);
      } catch (reconnectError) {
        AppLogger.error('NFC reconnection failed: $reconnectError');
        rethrow;
      }
    }
  }

  /// Check if NFC is available on the current device
  static Future<bool> isAvailable() async {
    try {
      // NFC is primarily available on mobile devices
      if (!system.isMobile()) {
        AppLogger.debug('NFC not available: not a mobile platform');
        return false;
      }
      
      final availability = await FlutterNfcKit.nfcAvailability;
      final isAvailable = availability == NFCAvailability.available;
      AppLogger.debug('NFC availability check: $availability (available: $isAvailable)');
      return isAvailable;
    } catch (e) {
      AppLogger.debug('Error checking NFC availability: $e');
      return false;
    }
  }

  /// Poll for NFC tags without connecting to FIDO application
  /// Useful for checking if tags are available
  static Future<bool> hasTagsAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        return false;
      }
      
      // Quick poll to see if any tags are available
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 1));
      if (tag != null) {
        await FlutterNfcKit.finish(); // Clean up
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.debug('Error checking for NFC tags: $e');
      return false;
    }
  }
}