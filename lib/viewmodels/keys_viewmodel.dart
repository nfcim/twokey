import 'package:fauth/repositories/credential_repository.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/foundation.dart';

class KeysViewModel extends ChangeNotifier {
  final CredentialRepository _repository;
  AuthenticatorInfo? authenticatorInfo;
  bool isLoading = false;
  String? errorMessage;

  bool _isConnected = false;

  KeysViewModel(this._repository);

  @override
  void dispose() {
    _repository.disconnect();
    super.dispose();
  }

  Future<void> fetchAuthenticatorInfo() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (!_isConnected) {
        await _repository.connect();
        _isConnected = true;
      }
      authenticatorInfo = await _repository.getAuthenticatorInfo();
    } catch (e) {
      errorMessage = e.toString();
      // On error, reset connection state to allow retry.
      _isConnected = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
