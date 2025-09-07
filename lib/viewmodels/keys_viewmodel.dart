import 'dart:async';
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
  bool pinRequired = false; // signal UI to request PIN

  bool _isConnected = false;
  String? _pin; // current PIN (valid for session)
  Completer<String>? _pinCompleter; // waits for user PIN entry

  KeysViewModel(this._repository);

  @override
  void dispose() {
    _repository.disconnect();
    super.dispose();
  }

  Future<bool> fetchCredentials() async =>
      _runWithPinLoopValue<List<Credential>>(
        () => _repository.getCredentials(),
        onSuccess: (data) => credentials = data,
      );

  Future<bool> fetchAuthenticatorInfo() async =>
      _runWithPinLoopValue<AuthenticatorInfo>(
        () => _repository.getAuthenticatorInfo(),
        onSuccess: (info) => authenticatorInfo = info,
      );

  Future<bool> deleteCredential(String userId) async => _runWithPinLoopVoid(
    () => _repository.deleteCredential(userId),
    onSuccess: () {
      credentials.removeWhere((c) => c.userId == userId);
    },
  );

  Future<bool> deleteCredentialByModel(Credential credential) async =>
      deleteCredential(credential.userId);

  // --- Internal helpers (loop + PIN) ---
  Future<bool> _connectIfNeeded() async {
    if (_isConnected) return true;
    while (_pin == null) {
      await _awaitPin();
    }
    try {
      await _repository.connect(pin: _pin!);
      _isConnected = true;
      pinRequired = false;
      return true;
    } on CtapError catch (e) {
      // Treat invalid PIN as retryable
      if (e.status == CtapStatusCode.ctap2ErrPinAuthInvalid) {
        _pin = null;
        _isConnected = false;
        return _connectIfNeeded();
      }
      errorMessage = e.toString();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<void> submitPin(String pin) async {
    if (pin.isEmpty) return;
    _pin = pin.trim();
    pinRequired = false;
    errorMessage = null;
    notifyListeners();
    if (_pinCompleter != null && !_pinCompleter!.isCompleted) {
      _pinCompleter!.complete(_pin);
      _pinCompleter = null;
    }
  }

  Future<bool> connectWithCurrentPin() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final ok = await _connectIfNeeded();
    isLoading = false;
    notifyListeners();
    return ok;
  }

  Future<String> _awaitPin() {
    if (_pinCompleter != null && !_pinCompleter!.isCompleted) {
      return _pinCompleter!.future;
    }
    pinRequired = true;
    notifyListeners();
    _pinCompleter = Completer<String>();
    return _pinCompleter!.future;
  }

  Future<bool> _runWithPinLoopValue<T>(
    Future<T> Function() op, {
    void Function(T value)? onSuccess,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    while (true) {
      final connected = await _connectIfNeeded();
      if (!connected) {
        if (errorMessage != null && !pinRequired) {
          isLoading = false;
          notifyListeners();
          return false;
        }
        await _awaitPin();
        continue;
      }
      try {
        final value = await op();
        onSuccess?.call(value);
        isLoading = false;
        notifyListeners();
        return true;
      } on CtapError catch (e) {
        if (e.status == CtapStatusCode.ctap2ErrPinAuthInvalid) {
          _pin = null;
          _isConnected = false;
          await _awaitPin();
          continue;
        }
        errorMessage = e.toString();
        // If connection-level issue, mark disconnected on generic catch below if needed
        isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  Future<bool> _runWithPinLoopVoid(
    Future<void> Function() op, {
    void Function()? onSuccess,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    while (true) {
      final connected = await _connectIfNeeded();
      if (!connected) {
        if (errorMessage != null && !pinRequired) {
          isLoading = false;
          notifyListeners();
          return false;
        }
        await _awaitPin();
        continue;
      }
      try {
        await op();
        onSuccess?.call();
        isLoading = false;
        notifyListeners();
        return true;
      } on CtapError catch (e) {
        if (e.status == CtapStatusCode.ctap2ErrPinAuthInvalid) {
          _pin = null;
          _isConnected = false;
          await _awaitPin();
          continue;
        }
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }
}
