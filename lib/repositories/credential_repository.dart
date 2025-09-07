import 'package:convert/convert.dart';
import 'package:fauth/api/fido_api.dart';
import 'package:fauth/models/credential.dart';
import 'package:fido2/fido2.dart';
import 'dart:typed_data';

import 'package:fauth/common/app_logger.dart';

class _ApiCtapDevice extends CtapDevice {
  final Future<Uint8List> Function(Uint8List) _transceive;

  _ApiCtapDevice(this._transceive);

  @override
  Future<CtapResponse<List<int>>> transceive(List<int> ctapCommand) {
    final apduCommand = [
      0x80,
      0x10,
      0x00,
      0x00,
      ctapCommand.length,
      ...ctapCommand,
      0x00,
    ];
    final commandBytes = Uint8List.fromList(apduCommand);
    AppLogger.debug('--> APDU Command (hex): ${hex.encode(commandBytes)}');

    return _transceive(commandBytes).then((responseBytes) {
      AppLogger.debug('<-- APDU Response (hex): ${hex.encode(responseBytes)}');

      if (responseBytes.length < 2) {
        throw Exception('APDU response is too short.');
      }
      final sw1 = responseBytes[responseBytes.length - 2];
      final sw2 = responseBytes[responseBytes.length - 1];
      final apduStatus = (sw1 << 8) | sw2;

      if (apduStatus != 0x9000) {
        throw Exception(
          'APDU command failed with status: 0x${apduStatus.toRadixString(16)}',
        );
      }

      final ctapPayload = responseBytes.sublist(0, responseBytes.length - 2);
      if (ctapPayload.isEmpty) {
        return CtapResponse(0x00, []);
      }

      final ctapStatus = ctapPayload[0];
      final cborData = ctapPayload.sublist(1);
      AppLogger.debug(
        '<-- CTAP Status: 0x${ctapStatus.toRadixString(16)}, CBOR Length: ${cborData.length}',
      );
      return CtapResponse(ctapStatus, cborData);
    });
  }
}

class CredentialRepository {
  final FidoApi _fidoApi;
  Ctap2? _ctap2Client;

  CredentialRepository(this._fidoApi);

  Future<void> connect() async {
    try {
      await _fidoApi.connect();
      final device = _ApiCtapDevice(_fidoApi.transceive);
      _ctap2Client = await Ctap2.create(device);
    } catch (e, st) {
      AppLogger.error('Connect failed: $e', e, st);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _fidoApi.disconnect();
    } finally {
      _ctap2Client = null;
    }
  }

  Future<AuthenticatorInfo> getAuthenticatorInfo() async {
    try {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }
      return _ctap2Client!.info;
    } catch (e, st) {
      AppLogger.error('Get authenticator info failed: $e', e, st);
      rethrow;
    }
  }

  Future<List<Credential>> getCredentials(String pin) async {
    try {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }
      if (!CredentialManagement.isSupported(_ctap2Client!.info)) {
        throw Exception(
          'This authenticator does not support credential management.',
        );
      }

      // Create a fresh CredentialManagement client for this operation using the provided PIN
      final PinProtocol pinProtocol =
          (_ctap2Client!.info.pinUvAuthProtocols?.contains(2) ?? false)
          ? PinProtocolV2()
          : PinProtocolV1();
      final clientPin = ClientPin(_ctap2Client!, pinProtocol: pinProtocol);
      final pinToken = await clientPin.getPinToken(
        pin,
        permissions: [ClientPinPermission.credentialManagement],
      );
      final credMgmtClient = CredentialManagement(
        _ctap2Client!,
        pinProtocol,
        pinToken,
      );

      final List<Credential> allCredentials = [];
      late final List rps; // dynamic list; library types hidden
      try {
        rps = await credMgmtClient.enumerateRPs();
      } on CtapError catch (ce) {
        if (ce.status == CtapStatusCode.ctap2ErrNoCredentials) {
          AppLogger.info('No credentials present on authenticator (RP list).');
          return const <Credential>[];
        }
        rethrow;
      }
      for (var rp in rps) {
        late final List creds; // dynamic list of credential entries
        try {
          creds = await credMgmtClient.enumerateCredentials(rp.rpIdHash);
        } on CtapError catch (ce) {
          if (ce.status == CtapStatusCode.ctap2ErrNoCredentials) {
            AppLogger.info('No credentials for RP ${rp.rp.id}. Skipping.');
            continue; // move to next RP
          }
          rethrow;
        }
        for (var cred in creds) {
          allCredentials.add(
            Credential(
              rpId: rp.rp.id,
              userName: cred.user.name,
              userId: String.fromCharCodes(cred.user.id),
            ),
          );
        }
      }
      return allCredentials;
    } catch (e, st) {
      AppLogger.error('Get credentials failed: $e', e, st);
      rethrow;
    }
  }

  Future<void> deleteCredential(String userId, String pin) async {
    try {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }
      if (!CredentialManagement.isSupported(_ctap2Client!.info)) {
        throw Exception(
          'This authenticator does not support credential management.',
        );
      }

      // Fresh CredentialManagement per operation using the provided PIN
      final PinProtocol pinProtocol =
          (_ctap2Client!.info.pinUvAuthProtocols?.contains(2) ?? false)
          ? PinProtocolV2()
          : PinProtocolV1();
      final clientPin = ClientPin(_ctap2Client!, pinProtocol: pinProtocol);
      final pinToken = await clientPin.getPinToken(
        pin,
        permissions: [ClientPinPermission.credentialManagement],
      );
      final credMgmtClient = CredentialManagement(
        _ctap2Client!,
        pinProtocol,
        pinToken,
      );

      final rps = await credMgmtClient.enumerateRPs();
      for (final rp in rps) {
        final creds = await credMgmtClient.enumerateCredentials(rp.rpIdHash);
        for (final cred in creds) {
          final candidateUserId = String.fromCharCodes(cred.user.id);
          if (candidateUserId == userId) {
            AppLogger.info(
              'Deleting credential userId=$userId rpId=${rp.rp.id}',
            );
            await credMgmtClient.deleteCredential(cred.credentialId);
            AppLogger.info('Deleted credential userId=$userId');
            return;
          }
        }
      }
      throw Exception('Credential not found for userId: $userId');
    } catch (e, st) {
      AppLogger.error('Delete credential failed: $e', e, st);
      rethrow;
    }
  }
}
