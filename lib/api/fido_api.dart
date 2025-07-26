import 'dart:typed_data';

abstract class FidoApi {
  Future<Uint8List> transceive(Uint8List command);

  Future<void> connect();

  Future<void> disconnect();
}
