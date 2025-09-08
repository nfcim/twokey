import 'package:convert/convert.dart';
import 'package:fauth/api/fido_api.dart';
import 'package:fauth/models/credential.dart';
import 'package:fido2/fido2.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:cbor/cbor.dart' as cbor;
import 'package:crypto/crypto.dart';
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

    return _transceive(commandBytes).then((firstResponse) async {
      AppLogger.debug('<-- APDU Response (hex): ${hex.encode(firstResponse)}');

      if (firstResponse.length < 2) {
        throw Exception('APDU response is too short.');
      }

      // Accumulate response data across GET RESPONSE loops when SW=0x61xx
      final fullData = <int>[];
      var resp = firstResponse;
      while (true) {
        final sw1 = resp[resp.length - 2];
        final sw2 = resp[resp.length - 1];
        final apduStatus = (sw1 << 8) | sw2;

        // Append data portion from this APDU
        if (resp.length > 2) {
          fullData.addAll(resp.sublist(0, resp.length - 2));
        }

        if (apduStatus == 0x9000) {
          break; // complete
        }

        if (sw1 == 0x61) {
          // More data available; issue GET RESPONSE
          var le = sw2;
          if (le == 0x00) {
            le = 0x100; // 256 bytes when Le=0
          }
          final getResponse = Uint8List.fromList([
            0x00,
            0xC0,
            0x00,
            0x00,
            le & 0xFF,
          ]);
          AppLogger.debug('--> GET RESPONSE Le=$le');
          resp = await _transceive(getResponse);
          AppLogger.debug('<-- GET RESPONSE (hex): ${hex.encode(resp)}');
          continue;
        }

        if (sw1 == 0x6C) {
          // Wrong length, retry GET RESPONSE with exact length
          final le = sw2;
          final getResponse = Uint8List.fromList([
            0x00,
            0xC0,
            0x00,
            0x00,
            le & 0xFF,
          ]);
          AppLogger.debug('--> GET RESPONSE (retry) Le=$le');
          resp = await _transceive(getResponse);
          AppLogger.debug(
            '<-- GET RESPONSE (retry) (hex): ${hex.encode(resp)}',
          );
          continue;
        }

        // Any other status is an error
        throw Exception(
          'APDU command failed with status: 0x${apduStatus.toRadixString(16)}',
        );
      }

      if (fullData.isEmpty) {
        return CtapResponse(0x00, []);
      }
      final ctapStatus = fullData[0];
      final cborData = fullData.sublist(1);
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

  // Simple in-memory storage for a test credential (registration + verification)
  // These are only for demonstration/testing purposes.
  final String _rpId = 'localhost';
  final String _rpName = 'Fauth Test';
  late final Fido2Server _server = Fido2Server(
    Fido2Config(rpId: _rpId, rpName: _rpName),
  );
  Uint8List? _testCredentialId;
  cbor.CborMap? _testCredentialPublicKey;
  int _testSignCount = 0;

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

  // --- Test flows: registration and verification ---
  Future<String> testRegister({
    required String username,
    required String displayName,
    required String pin,
    void Function(bool waiting)? onUserPresence,
  }) async {
    try {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }

      // 1) Server options
      final regOptions = _server.generateRegistrationOptions(
        username,
        displayName,
      );
      final String challengeB64 = regOptions['challenge'] as String;

      // 2) clientDataJSON and hash
      final clientDataJson = jsonEncode({
        'type': 'webauthn.create',
        'challenge': challengeB64,
        'origin': 'https://$_rpId',
      });
      final clientDataHash = sha256.convert(utf8.encode(clientDataJson)).bytes;

      // 3) Prepare PIN/UV
      final PinProtocol pinProtocol =
          (_ctap2Client!.info.pinUvAuthProtocols?.contains(2) ?? false)
          ? PinProtocolV2()
          : PinProtocolV1();
      final clientPin = ClientPin(_ctap2Client!, pinProtocol: pinProtocol);
      final pinToken = await clientPin.getPinToken(
        pin,
        permissions: [ClientPinPermission.makeCredential],
        permissionsRpId: _rpId,
      );
      final pinAuth = await pinProtocol.authenticate(pinToken, clientDataHash);

      // 4) Build makeCredential request
      final rp = PublicKeyCredentialRpEntity(id: _rpId);
      final user = PublicKeyCredentialUserEntity(
        id: utf8.encode(username),
        name: username,
        displayName: displayName,
      );
      final pubKeyCredParams = [
        {'type': 'public-key', 'alg': -7}, // ES256
        {'type': 'public-key', 'alg': -8}, // EdDSA
      ];
      final req = MakeCredentialRequest(
        clientDataHash: clientDataHash,
        rp: rp,
        user: user,
        pubKeyCredParams: pubKeyCredParams,
        options: {'rk': true, 'up': true},
        pinAuth: pinAuth,
        pinProtocol: pinProtocol.version,
      );

      onUserPresence?.call(true);
      final CtapResponse<List<int>> res;
      try {
        res = await _ctap2Client!.device.transceive(req.encode());
      } finally {
        onUserPresence?.call(false);
      }
      if (res.status != 0) {
        throw CtapError.fromCode(res.status);
      }
      final makeCred = MakeCredentialResponse.decode(res.data);

      // 5) Build attestationObject (CBOR Map) with proper CBOR types and let server verify
      final attestationMap = cbor.CborMap.fromEntries([
        MapEntry(cbor.CborString('fmt'), cbor.CborString(makeCred.fmt)),
        MapEntry(
          cbor.CborString('authData'),
          cbor.CborBytes(makeCred.authData),
        ),
        MapEntry(cbor.CborString('attStmt'), cbor.CborValue(makeCred.attStmt)),
      ]);
      final attestationBytes = cbor.cbor.encode(attestationMap);
      final clientDataB64 = base64Url.encode(utf8.encode(clientDataJson));
      final attestationB64 = base64Url.encode(attestationBytes);
      final registration = _server.completeRegistration(
        clientDataB64,
        attestationB64,
        challengeB64,
      );

      // Persist in-memory for test verification
      _testCredentialId = registration.credentialId;
      _testCredentialPublicKey = registration.credentialPublicKey;
      _testSignCount = 0; // start from 0; will be updated after first assertion

      return 'Registration OK\ncredId=${hex.encode(_testCredentialId!)}\nalg set';
    } catch (e, st) {
      AppLogger.error('Test registration failed: $e', e, st);
      rethrow;
    }
  }

  Future<String> testVerify({
    required String pin,
    void Function(bool waiting)? onUserPresence,
  }) async {
    try {
      if (_ctap2Client == null) {
        throw Exception('Not connected. Call connect() first.');
      }
      if (_testCredentialId == null || _testCredentialPublicKey == null) {
        throw Exception('No test credential registered yet.');
      }

      // 1) Server options
      final verOptions = _server.generateVerificationOptions();
      final String challengeB64 = verOptions['challenge'] as String;

      // 2) clientDataJSON and hash
      final clientDataJson = jsonEncode({
        'type': 'webauthn.get',
        'challenge': challengeB64,
        'origin': 'https://$_rpId',
      });
      final clientDataHash = sha256.convert(utf8.encode(clientDataJson)).bytes;

      // 3) Prepare PIN/UV
      final PinProtocol pinProtocol =
          (_ctap2Client!.info.pinUvAuthProtocols?.contains(2) ?? false)
          ? PinProtocolV2()
          : PinProtocolV1();
      final clientPin = ClientPin(_ctap2Client!, pinProtocol: pinProtocol);
      final pinToken = await clientPin.getPinToken(
        pin,
        permissions: [ClientPinPermission.getAssertion],
        permissionsRpId: _rpId,
      );
      final pinAuth = await pinProtocol.authenticate(pinToken, clientDataHash);

      // 4) Build getAssertion request (allowList constrains to our test credential)
      final allow = [
        PublicKeyCredentialDescriptor(
          type: 'public-key',
          id: _testCredentialId!.toList(),
        ),
      ];
      final req = GetAssertionRequest(
        rpId: _rpId,
        clientDataHash: clientDataHash,
        allowList: allow,
        options: {'up': true, 'uv': true},
        pinAuth: pinAuth,
        pinProtocol: pinProtocol.version,
      );

      onUserPresence?.call(true);
      final CtapResponse<List<int>> res;
      try {
        res = await _ctap2Client!.device.transceive(req.encode());
      } finally {
        onUserPresence?.call(false);
      }
      if (res.status != 0) {
        throw CtapError.fromCode(res.status);
      }
      final assertion = GetAssertionResponse.decode(res.data);

      // 5) Server-side verification
      final clientDataB64 = base64Url.encode(utf8.encode(clientDataJson));
      final authDataB64 = base64Url.encode(
        Uint8List.fromList(assertion.authData),
      );
      final signatureB64 = base64Url.encode(
        Uint8List.fromList(assertion.signature),
      );

      final verification = await _server.completeVerification(
        clientDataB64,
        authDataB64,
        signatureB64,
        challengeB64,
        _testCredentialPublicKey!,
        _testSignCount,
      );

      _testSignCount = verification.signCount;

      return 'Assertion OK\nuserPresent=${verification.userPresent}\nsignCount=${verification.signCount}';
    } catch (e, st) {
      AppLogger.error('Test verification failed: $e', e, st);
      rethrow;
    }
  }
}
