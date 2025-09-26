import 'dart:async';
import 'package:twokey/models/credential.dart';
import 'package:twokey/service/authenticator.dart';
import 'package:fido2/fido2.dart';
import 'package:flutter/foundation.dart';

class KeysViewModel extends ChangeNotifier {
  final AuthenticatorService _repository;
  AuthenticatorInfo? authenticatorInfo;
  List<Credential> credentials = [];
  bool isLoading = false;
  String? errorMessage;
  bool pinRequired = false; // signal UI to request PIN
  String? testResult; // registration / verification result text
  bool waitingForTouch = false;

  bool _isConnected = false;
  Completer<String>? _pinCompleter; // waits for user PIN entry
  bool _hasLoaded = false; // guards initial data loading

  KeysViewModel(this._repository);

  // Exception used to signal that the user cancelled PIN entry
  // This allows in-flight operations awaiting a PIN to terminate gracefully.
  static final PinCancelledException _pinCancelled = PinCancelledException();

  @override
  void dispose() {
    _repository.disconnect();
    super.dispose();
  }

  Future<bool> fetchCredentials() async =>
      _runWithPinPerOperation<List<Credential>>(
        (pin) => _repository.getCredentials(pin),
        onSuccess: (data) => credentials = data,
      );

  Future<bool> fetchAuthenticatorInfo() async =>
      _runWithPinLoopValue<AuthenticatorInfo>(
        () => _repository.getAuthenticatorInfo(),
        onSuccess: (info) => authenticatorInfo = info,
      );

  Future<bool> deleteCredential(String userId) async =>
      _runWithPinPerOperation<void>(
        (pin) => _repository.deleteCredential(userId, pin),
        onSuccess: (_) {
          credentials.removeWhere((c) => c.userId == userId);
        },
      );

  Future<bool> deleteCredentialByModel(Credential credential) async =>
      deleteCredential(credential.userId);

  /// Ensures authenticator info and credentials are loaded
  /// Returns true if data is available or loaded successfully.
  Future<bool> ensureLoaded() async {
    if (_hasLoaded && authenticatorInfo != null && credentials.isNotEmpty) {
      return true;
    }
    // Try to load authenticator info (no PIN needed, loop handles connection and PIN retries)
    final infoOk = await fetchAuthenticatorInfo();
    if (!infoOk) {
      return false;
    }
    // Load credentials once; this may require PIN
    final credsOk = await fetchCredentials();
    if (credsOk) {
      _hasLoaded = true;
    }
    return credsOk;
  }

  Future<bool> testRegister({
    required String username,
    required String displayName,
  }) async => _runWithPinPerOperation<String>(
    (pin) => _repository.testRegister(
      username: username,
      displayName: displayName,
      pin: pin,
      onUserPresence: (w) {
        waitingForTouch = w;
        notifyListeners();
      },
    ),
    onSuccess: (msg) => testResult = msg,
  );

  Future<bool> testVerify() async => _runWithPinPerOperation<String>(
    (pin) => _repository.testVerify(
      pin: pin,
      onUserPresence: (w) {
        waitingForTouch = w;
        notifyListeners();
      },
    ),
    onSuccess: (msg) => testResult = msg,
  );

  // --- Internal helpers (loop + PIN) ---
  Future<bool> _connectIfNeeded() async {
    if (_isConnected) return true;
    try {
      await _repository.connect();
      _isConnected = true;
      pinRequired = false;
      return true;
    } on CtapError catch (e) {
      errorMessage = e.toString();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<void> submitPin(String pin) async {
    if (pin.isEmpty) return;
    pinRequired = false;
    errorMessage = null;
    notifyListeners();
    if (_pinCompleter != null && !_pinCompleter!.isCompleted) {
      _pinCompleter!.complete(pin.trim());
      _pinCompleter = null;
    }
  }

  /// Cancels the current PIN request, if any, and terminates the awaiting
  /// operation by completing the PIN future with a cancellation error.
  void cancelPinRequest() {
    pinRequired = false;
    errorMessage = null;
    if (_pinCompleter != null && !_pinCompleter!.isCompleted) {
      _pinCompleter!.completeError(_pinCancelled);
      _pinCompleter = null;
    }
    notifyListeners();
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
        try {
          await _awaitPin();
        } catch (e) {
          if (identical(e, _pinCancelled) || e is PinCancelledException) {
            isLoading = false;
            notifyListeners();
            return false;
          }
          rethrow;
        }
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
          _isConnected = false;
          try {
            await _awaitPin();
          } catch (e) {
            if (identical(e, _pinCancelled) || e is PinCancelledException) {
              isLoading = false;
              notifyListeners();
              return false;
            }
            rethrow;
          }
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

  Future<bool> _runWithPinPerOperation<T>(
    Future<T> Function(String pin) op, {
    void Function(T value)? onSuccess,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    while (true) {
      final connected = await _connectIfNeeded();
      if (!connected) {
        isLoading = false;
        notifyListeners();
        return false;
      }
      String pin;
      try {
        pin = await _awaitPin();
      } catch (e) {
        if (identical(e, _pinCancelled) || e is PinCancelledException) {
          isLoading = false;
          notifyListeners();
          return false;
        }
        rethrow;
      }
      try {
        final value = await op(pin);
        onSuccess?.call(value);
        isLoading = false;
        notifyListeners();
        return true;
      } on CtapError catch (e) {
        if (e.status == CtapStatusCode.ctap2ErrPinAuthInvalid) {
          // Ask for PIN again immediately and retry
          await Future<void>.delayed(Duration(milliseconds: 0));
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

class PinCancelledException implements Exception {
  @override
  String toString() => 'PIN entry cancelled by user';
}
