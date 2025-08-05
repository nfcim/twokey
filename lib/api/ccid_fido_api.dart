import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:ccid/ccid.dart';
import 'package:fauth/api/fido_api.dart';
import 'package:logger/logger.dart';

class CcidFidoApi implements FidoApi {
  CcidCard? _card;
  final _logger = Logger(printer: SimplePrinter());

  @override
  Future<void> connect() async {
    // Re-create the context on every connect call to ensure it's always valid.
    final ccid = Ccid();

    final readers = await ccid.listReaders();
    if (readers.isEmpty) {
      throw Exception('No reader found. Please ensure your key is connected.');
    }
    _card = await ccid.connect(readers.first);

    const fidoAid = 'A0000006472F0001';
    final selectApdu = '00A4040008$fidoAid';
    _logger.d('--> SELECT FIDO App: $selectApdu');
    final response = await _card!.transceive(selectApdu);
    _logger.d('<-- SELECT Response: $response');

    if (response == null || !response.endsWith('9000')) {
      throw Exception(
        'Failed to select FIDO2 application. Response: $response',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_card != null) {
      // The CcidCard object handles its own context disconnection.
      await _card!.disconnect();
      _card = null;
    }
  }

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    if (_card == null) {
      throw Exception('Card not connected');
    }
    final commandHex = hex.encode(command);
    final responseHex = await _card!.transceive(commandHex);
    if (responseHex == null) {
      throw Exception('Received null response from card');
    }
    return Uint8List.fromList(hex.decode(responseHex));
  }
}
