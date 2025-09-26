import 'package:flutter_test/flutter_test.dart';
import 'package:twokey/api/unified_fido_api.dart';
import 'package:twokey/api/ccid_fido_api.dart';
import 'package:twokey/api/nfc_fido_api.dart';

void main() {
  group('UnifiedFidoApi', () {
    late UnifiedFidoApi unifiedApi;

    setUp(() {
      unifiedApi = UnifiedFidoApi();
    });

    test('should create instance successfully', () {
      expect(unifiedApi, isA<UnifiedFidoApi>());
      expect(unifiedApi.isConnected, isFalse);
      expect(unifiedApi.connectedDeviceType, isNull);
    });

    test('should set preferred device type', () {
      unifiedApi.setPreferredDeviceType(FidoDeviceType.nfc);
      // Note: We can't directly test the private field, but this ensures the method exists
    });

    test('should handle device type enum values', () {
      expect(FidoDeviceType.ccid, isA<FidoDeviceType>());
      expect(FidoDeviceType.nfc, isA<FidoDeviceType>());
    });

    test('should create FidoDeviceInfo properly', () {
      final deviceInfo = FidoDeviceInfo(
        type: FidoDeviceType.ccid,
        name: 'Test Reader',
        description: 'Test Description',
      );

      expect(deviceInfo.type, equals(FidoDeviceType.ccid));
      expect(deviceInfo.name, equals('Test Reader'));
      expect(deviceInfo.description, equals('Test Description'));
    });

    test('should disconnect when not connected', () async {
      // Should not throw when disconnecting while not connected
      await unifiedApi.disconnect();
      expect(unifiedApi.isConnected, isFalse);
    });

    test('should throw when transceiving without connection', () async {
      expect(
        () async => await unifiedApi.transceive([0x00, 0x00, 0x00, 0x00]),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No device connected'),
        )),
      );
    });
  });

  group('FidoDeviceInfo', () {
    test('should create device info for CCID', () {
      final info = FidoDeviceInfo(
        type: FidoDeviceType.ccid,
        name: 'CCID Reader',
        description: 'Smart Card Reader',
      );

      expect(info.type, equals(FidoDeviceType.ccid));
      expect(info.name, equals('CCID Reader'));
      expect(info.description, equals('Smart Card Reader'));
    });

    test('should create device info for NFC', () {
      final info = FidoDeviceInfo(
        type: FidoDeviceType.nfc,
        name: 'NFC',
        description: 'Near Field Communication',
      );

      expect(info.type, equals(FidoDeviceType.nfc));
      expect(info.name, equals('NFC'));
      expect(info.description, equals('Near Field Communication'));
    });
  });
}