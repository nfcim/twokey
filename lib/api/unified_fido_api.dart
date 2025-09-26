import 'dart:typed_data';
import 'package:twokey/api/fido_api.dart';
import 'package:twokey/api/ccid_fido_api.dart';
import 'package:twokey/api/nfc_fido_api.dart';
import 'package:twokey/common/app_logger.dart';
import 'package:ccid/ccid.dart';

enum FidoDeviceType {
  ccid,
  nfc,
}

class FidoDeviceInfo {
  final FidoDeviceType type;
  final String name;
  final String description;

  FidoDeviceInfo({
    required this.type,
    required this.name,
    required this.description,
  });
}

/// A unified API that can work with both CCID readers and NFC tags
/// It automatically detects available devices and allows selection
class UnifiedFidoApi implements FidoApi {
  FidoApi? _activeApi;
  FidoDeviceType? _selectedDeviceType;

  @override
  Future<void> connect() async {
    if (_selectedDeviceType == null) {
      // Auto-detect and connect to the first available device
      final availableDevices = await getAvailableDevices();
      if (availableDevices.isEmpty) {
        throw Exception('No FIDO2 devices found. Please ensure your key is connected or near the device.');
      }
      
      // Prefer CCID over NFC for stability if both are available
      final preferredDevice = availableDevices.firstWhere(
        (device) => device.type == FidoDeviceType.ccid,
        orElse: () => availableDevices.first,
      );
      
      await connectToDevice(preferredDevice.type);
    } else {
      await connectToDevice(_selectedDeviceType!);
    }
  }

  Future<void> connectToDevice(FidoDeviceType deviceType) async {
    await disconnect(); // Ensure clean state

    switch (deviceType) {
      case FidoDeviceType.ccid:
        _activeApi = CcidFidoApi();
        break;
      case FidoDeviceType.nfc:
        _activeApi = NfcFidoApi();
        break;
    }

    _selectedDeviceType = deviceType;
    await _activeApi!.connect();
    AppLogger.info('Connected to ${deviceType.name} device');
  }

  @override
  Future<void> disconnect() async {
    if (_activeApi != null) {
      await _activeApi!.disconnect();
      _activeApi = null;
    }
    _selectedDeviceType = null;
  }

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    if (_activeApi == null) {
      throw Exception('No device connected. Call connect() first.');
    }

    // For NFC, we need to handle transient connections
    if (_selectedDeviceType == FidoDeviceType.nfc) {
      // For NFC, we might need to re-establish connection for each transaction
      // due to the transient nature of NFC communication
      try {
        return await _activeApi!.transceive(command);
      } catch (e) {
        AppLogger.debug('NFC transaction failed, attempting to reconnect: $e');
        // Try to reconnect once
        try {
          await _activeApi!.disconnect();
          await _activeApi!.connect();
          return await _activeApi!.transceive(command);
        } catch (reconnectError) {
          AppLogger.error('NFC reconnection failed: $reconnectError');
          rethrow;
        }
      }
    }

    return await _activeApi!.transceive(command);
  }

  /// Get all available FIDO2 devices
  Future<List<FidoDeviceInfo>> getAvailableDevices() async {
    final devices = <FidoDeviceInfo>[];

    // Check for CCID readers
    try {
      final ccid = Ccid();
      final readers = await ccid.listReaders();
      if (readers.isNotEmpty) {
        for (final reader in readers) {
          devices.add(FidoDeviceInfo(
            type: FidoDeviceType.ccid,
            name: reader,
            description: 'CCID Smart Card Reader',
          ));
        }
      }
    } catch (e) {
      AppLogger.debug('Error checking CCID readers: $e');
    }

    // Check for NFC availability
    try {
      if (await NfcFidoApi.isAvailable()) {
        devices.add(FidoDeviceInfo(
          type: FidoDeviceType.nfc,
          name: 'NFC',
          description: 'Near Field Communication',
        ));
      }
    } catch (e) {
      AppLogger.debug('Error checking NFC availability: $e');
    }

    return devices;
  }

  /// Set preferred device type for connection
  void setPreferredDeviceType(FidoDeviceType deviceType) {
    _selectedDeviceType = deviceType;
  }

  /// Get currently connected device type
  FidoDeviceType? get connectedDeviceType => _selectedDeviceType;

  /// Check if currently connected
  bool get isConnected => _activeApi != null;
}