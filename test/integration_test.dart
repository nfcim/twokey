import 'package:flutter_test/flutter_test.dart';
import 'package:twokey/api/fido_api.dart';
import 'package:twokey/api/nfc_fido_api.dart';
import 'package:twokey/api/ccid_fido_api.dart';
import 'package:twokey/api/unified_fido_api.dart';
import 'package:twokey/service/authenticator.dart';

void main() {
  group('NFC Integration Tests', () {
    test('NfcFidoApi should implement FidoApi interface', () {
      final nfcApi = NfcFidoApi();
      expect(nfcApi, isA<FidoApi>());
    });

    test('UnifiedFidoApi should work with AuthenticatorService', () {
      final unifiedApi = UnifiedFidoApi();
      final service = AuthenticatorService(unifiedApi);
      expect(service, isA<AuthenticatorService>());
    });

    test('AuthenticatorService should support device enumeration', () async {
      final unifiedApi = UnifiedFidoApi();
      final service = AuthenticatorService(unifiedApi);
      
      // This should not throw even if no devices are available
      final devices = await service.getAvailableDevices();
      expect(devices, isA<List<FidoDeviceInfo>>());
    });

    test('UnifiedFidoApi should handle device type preferences', () {
      final unifiedApi = UnifiedFidoApi();
      
      // Should not throw when setting preferences
      unifiedApi.setPreferredDeviceType(FidoDeviceType.nfc);
      unifiedApi.setPreferredDeviceType(FidoDeviceType.ccid);
      
      expect(unifiedApi.isConnected, isFalse);
    });
  });

  group('Device Type Validation', () {
    test('FidoDeviceType enum should have expected values', () {
      expect(FidoDeviceType.values.length, equals(2));
      expect(FidoDeviceType.values, contains(FidoDeviceType.ccid));
      expect(FidoDeviceType.values, contains(FidoDeviceType.nfc));
    });

    test('FidoDeviceInfo should properly represent device information', () {
      final ccidDevice = FidoDeviceInfo(
        type: FidoDeviceType.ccid,
        name: 'Test CCID Reader',
        description: 'Test CCID Description',
      );

      final nfcDevice = FidoDeviceInfo(
        type: FidoDeviceType.nfc,
        name: 'Test NFC Device',
        description: 'Test NFC Description',
      );

      expect(ccidDevice.type, equals(FidoDeviceType.ccid));
      expect(nfcDevice.type, equals(FidoDeviceType.nfc));
      expect(ccidDevice.name, equals('Test CCID Reader'));
      expect(nfcDevice.name, equals('Test NFC Device'));
    });
  });
}