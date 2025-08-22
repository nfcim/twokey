import 'package:convert/convert.dart';
import 'package:fauth/api/fido_api.dart';
import 'package:fauth/models/credential.dart';
import 'package:fido2/fido2.dart';
import 'dart:typed_data';

import 'package:fauth/core/logging/app_logger.dart';
import 'package:fauth/core/result/result.dart';
import 'package:fauth/core/error/failure.dart';

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
  CredentialManagement? _credMgmtClient;

  CredentialRepository(this._fidoApi);

  Failure _failureFrom(Object e, StackTrace st) {
    final msg = e.toString();
    if (e is CtapError) {
      // 0x33 = ctap2ErrPinAuthInvalid -> treat as needing fresh PIN entry
      if (e.status == CtapStatusCode.ctap2ErrPinAuthInvalid) {
        return PinRequiredFailure(cause: e, stackTrace: st);
      }
    }
    if (msg.contains('No reader')) {
      return DeviceNotFoundFailure(cause: e, stackTrace: st);
    }
    if (msg.contains('not support credential management')) {
      return const UnsupportedFailure('credential management');
    }
    if (msg.contains('PIN')) {
      return PinRequiredFailure(cause: e, stackTrace: st);
    }
    if (msg.contains('Not connected')) {
      return ConnectionFailure(msg, cause: e, stackTrace: st);
    }
    if (msg.contains('Credential not found')) {
      return OperationFailure(msg, cause: e, stackTrace: st);
    }
    return UnknownFailure(cause: e, stackTrace: st);
  }

  Future<Result<void, Failure>> connect({String pin = ''}) async {
    try {
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
      return const Ok(null);
    } catch (e, st) {
      final failure = _failureFrom(e, st);
      AppLogger.error('Connect failed: ${failure.message}', e, st);
      return Err(failure);
    }
  }

  Future<void> disconnect() async {
    try {
      await _fidoApi.disconnect();
    } finally {
      _ctap2Client = null;
      _credMgmtClient = null;
    }
  }

  Future<Result<AuthenticatorInfo, Failure>> getAuthenticatorInfo() async {
    try {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }
      return Ok(_ctap2Client!.info);
    } catch (e, st) {
      final failure = _failureFrom(e, st);
      AppLogger.error(
        'Get authenticator info failed: ${failure.message}',
        e,
        st,
      );
      return Err(failure);
    }
  }

  Future<Result<List<Credential>, Failure>> getCredentials() async {
    try {
      if (_credMgmtClient == null) {
        if (_ctap2Client == null) {
          throw Exception('Not connected. Call connect() first.');
        }
        throw Exception(
          'This authenticator does not support credential management.',
        );
      }

      final List<Credential> allCredentials = [];
      late final List rps; // dynamic list; library types hidden
      try {
        rps = await _credMgmtClient!.enumerateRPs();
      } on CtapError catch (ce) {
        if (ce.status == CtapStatusCode.ctap2ErrNoCredentials) {
          AppLogger.info('No credentials present on authenticator (RP list).');
          return const Ok(<Credential>[]);
        }
        rethrow;
      }
      for (var rp in rps) {
        late final List creds; // dynamic list of credential entries
        try {
          creds = await _credMgmtClient!.enumerateCredentials(rp.rpIdHash);
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
      return Ok(allCredentials);
    } catch (e, st) {
      final failure = _failureFrom(e, st);
      AppLogger.error('Get credentials failed: ${failure.message}', e, st);
      return Err(failure);
    }
  }

  Future<Result<void, Failure>> deleteCredential(String userId) async {
    try {
      if (_credMgmtClient == null) {
        if (_ctap2Client == null) {
          throw Exception('Not connected. Call connect() first.');
        }
        throw Exception(
          'This authenticator does not support credential management.',
        );
      }

      final rps = await _credMgmtClient!.enumerateRPs();
      for (final rp in rps) {
        final creds = await _credMgmtClient!.enumerateCredentials(rp.rpIdHash);
        for (final cred in creds) {
          final candidateUserId = String.fromCharCodes(cred.user.id);
          if (candidateUserId == userId) {
            AppLogger.info(
              'Deleting credential userId=$userId rpId=${rp.rp.id}',
            );
            await _credMgmtClient!.deleteCredential(cred.credentialId);
            AppLogger.info('Deleted credential userId=$userId');
            return const Ok(null);
          }
        }
      }
      throw Exception('Credential not found for userId: $userId');
    } catch (e, st) {
      final failure = _failureFrom(e, st);
      AppLogger.error('Delete credential failed: ${failure.message}', e, st);
      return Err(failure);
    }
  }
}
