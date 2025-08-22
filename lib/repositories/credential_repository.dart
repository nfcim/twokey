import 'package:convert/convert.dart';
import 'package:fauth/api/fido_api.dart';
import 'package:fauth/models/credential.dart';
import 'package:fido2/fido2.dart';
import 'dart:typed_data';

import 'package:logger/logger.dart';

class _ApiCtapDevice extends CtapDevice {
  final Future<Uint8List> Function(Uint8List) _transceive;
  final _logger = Logger(printer: SimplePrinter());

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
    _logger.d('--> APDU Command (hex): ${hex.encode(commandBytes)}');

    return _transceive(commandBytes).then((responseBytes) {
      _logger.d('<-- APDU Response (hex): ${hex.encode(responseBytes)}');

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
      _logger.d(
        '<-- CTAP Status: 0x${ctapStatus.toRadixString(16)}, CBOR Length: ${cborData.length}',
      );
      return CtapResponse(ctapStatus, cborData);
    });
  }
}

class CredentialRepository {
  final FidoApi _fidoApi;
  Ctap2? _ctap2Client;
  CredentialManagement? _credMgmtClient;
  final _logger = Logger(printer: SimplePrinter());

  CredentialRepository(this._fidoApi);

  Future<void> connect({String pin = ''}) async {
    await _fidoApi.connect();
    final device = _ApiCtapDevice(_fidoApi.transceive);
    _ctap2Client = await Ctap2.create(device);

    if (CredentialManagement.isSupported(_ctap2Client!.info)) {
      PinProtocol pinProtocol;
      final protocols = _ctap2Client!.info.pinUvAuthProtocols;
      if (protocols != null && protocols.contains(2)) {
        pinProtocol = PinProtocolV2();
      } else {
        pinProtocol = PinProtocolV1();
      }

      final clientPin = ClientPin(_ctap2Client!, pinProtocol: pinProtocol);
      final pinToken = await clientPin.getPinToken(
        pin,
        permissions: [ClientPinPermission.credentialManagement],
      );
      _credMgmtClient = CredentialManagement(
        _ctap2Client!,
        pinProtocol,
        pinToken,
      );
    }
  }

  Future<void> disconnect() async {
    await _fidoApi.disconnect();
    _ctap2Client = null;
    _credMgmtClient = null;
  }

  Future<AuthenticatorInfo> getAuthenticatorInfo() async {
    if (_ctap2Client == null) {
      throw Exception('Not connected. Call connect() first.');
    }
    // Now we use the existing client instance.
    return _ctap2Client!.info;
  }

  Future<List<Credential>> getCredentials() async {
    if (_credMgmtClient == null) {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }
      throw Exception(
        'This authenticator does not support credential management.',
      );
    }

    final List<Credential> allCredentials = [];
    final rps = await _credMgmtClient!.enumerateRPs();
    for (var rp in rps) {
      final credentials = await _credMgmtClient!.enumerateCredentials(
        rp.rpIdHash,
      );
      for (var cred in credentials) {
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
  }

  Future<void> deleteCredential(String userId) async {
    if (_credMgmtClient == null) {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }
      throw Exception(
        'This authenticator does not support credential management.',
      );
    }

    try {
      // Re-enumerate RPs and credentials to locate the target credential.
      final rps = await _credMgmtClient!.enumerateRPs();
      for (final rp in rps) {
        final creds = await _credMgmtClient!.enumerateCredentials(rp.rpIdHash);
        for (final cred in creds) {
          final candidateUserId = String.fromCharCodes(cred.user.id);
          if (candidateUserId == userId) {
            _logger.i('Deleting credential userId=$userId rpId=${rp.rp.id}');
            await _credMgmtClient!.deleteCredential(cred.credentialId);
            _logger.i('Deleted credential userId=$userId');
            return;
          }
        }
      }
      throw Exception('Credential not found for userId: $userId');
    } catch (e) {
      _logger.e('Failed to delete credential: $e');
      rethrow;
    }
  }
}
