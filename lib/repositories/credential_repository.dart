import 'package:convert/convert.dart';
import 'package:fauth/api/fido_api.dart';
import 'package:fido2/fido2.dart';
import 'package:fido2/src/ctap.dart';
import 'dart:typed_data';

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
    print('--> APDU Command (hex): ${hex.encode(commandBytes)}');

    return _transceive(commandBytes).then((responseBytes) {
      print('<-- APDU Response (hex): ${hex.encode(responseBytes)}');

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
      print(
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
    await _fidoApi.connect();
    final device = _ApiCtapDevice(_fidoApi.transceive);
    _ctap2Client = await Ctap2.create(device);
  }

  Future<void> disconnect() async {
    await _fidoApi.disconnect();
    _ctap2Client = null;
  }

  Future<AuthenticatorInfo> getAuthenticatorInfo() async {
    if (_ctap2Client == null) {
      throw Exception('Not connected. Call connect() first.');
    }
    // Now we use the existing client instance.
    return _ctap2Client!.info;
  }
}
