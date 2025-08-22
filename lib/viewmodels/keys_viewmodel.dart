import 'package:fauth/models/credential.dart';
import 'package:fauth/repositories/credential_repository.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/foundation.dart';
import 'package:fauth/core/result/result.dart';
import 'package:fauth/core/error/failure.dart';

class KeysViewModel extends ChangeNotifier {
  final CredentialRepository _repository;
  AuthenticatorInfo? authenticatorInfo;
  List<Credential> credentials = [];
  bool isLoading = false;
  String? errorMessage;
  bool pinRequired = false; // signal UI to request PIN

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

    if (!_isConnected) {
      final connectRes = await _repository.connect(
        pin: '123456',
      ); // TODO: replace with user input
      if (connectRes is Err<void, Failure>) {
        final failure = connectRes.error;
        if (failure is PinRequiredFailure) {
          pinRequired = true;
        } else {
          errorMessage = failure.message;
        }
        isLoading = false;
        _isConnected = false;
        notifyListeners();
        return;
      }
      pinRequired = false;
      _isConnected = true;
    }

    final result = await _repository.getCredentials();
    result.match(
      ok: (data) {
        credentials = data;
      },
      err: (f) {
        if (f is PinRequiredFailure) {
          pinRequired = true;
          _isConnected = false; // force reconnection with new PIN
        } else {
          errorMessage = f.message;
          if (f is ConnectionFailure) _isConnected = false;
        }
      },
    );
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAuthenticatorInfo() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    if (!_isConnected) {
      final connectRes = await _repository.connect(pin: '123456');
      if (connectRes is Err<void, Failure>) {
        final failure = connectRes.error;
        if (failure is PinRequiredFailure) {
          pinRequired = true;
        } else {
          errorMessage = failure.message;
        }
        isLoading = false;
        _isConnected = false;
        notifyListeners();
        return;
      }
      pinRequired = false;
      _isConnected = true;
    }

    final result = await _repository.getAuthenticatorInfo();
    result.match(
      ok: (info) => authenticatorInfo = info,
      err: (f) {
        if (f is PinRequiredFailure) {
          pinRequired = true;
          _isConnected = false;
        } else {
          errorMessage = f.message;
          if (f is ConnectionFailure) _isConnected = false;
        }
      },
    );
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCredential(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.deleteCredential(userId);
    result.match(
      ok: (_) => credentials.removeWhere((cred) => cred.userId == userId),
      err: (f) {
        if (f is PinRequiredFailure) {
          pinRequired = true;
          _isConnected = false;
        } else {
          errorMessage = f.message;
        }
      },
    );
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCredentialByModel(Credential credential) async {
    await deleteCredential(credential.userId);
  }
}
