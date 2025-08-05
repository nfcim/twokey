import 'package:fauth/models/credential.dart';
import 'package:fauth/repositories/credential_repository.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/foundation.dart';

class KeysViewModel extends ChangeNotifier {
  final CredentialRepository _repository;
  AuthenticatorInfo? authenticatorInfo;
  List<Credential> credentials = [];
  bool isLoading = false;
  String? errorMessage;

  bool _isConnected = false;

  KeysViewModel(this._repository);

  @override
  void dispose() {
    _repository.disconnect();
    super.dispose();
  }

  Future<void> fetchCredentials() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (!_isConnected) {
        // TODO: Prompt user for PIN
        await _repository.connect(pin: '123456');
        _isConnected = true;
      }
      credentials = await _repository.getCredentials();
    } catch (e) {
      errorMessage = e.toString();
      _isConnected = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAuthenticatorInfo() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (!_isConnected) {
        // TODO: Prompt user for PIN
        await _repository.connect(pin: '123456');
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

  Future<void> deleteCredential(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCredential(userId);
      credentials.removeWhere((cred) => cred.userId == userId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
