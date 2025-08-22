/// Base Failure hierarchy for domain & data layer errors.
/// Keep messages user-neutral; UI decides localization.
sealed class Failure {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  const Failure(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

class DeviceNotFoundFailure extends Failure {
  const DeviceNotFoundFailure({Object? cause, StackTrace? stackTrace})
    : super('Device not found', cause: cause, stackTrace: stackTrace);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message, {super.cause, super.stackTrace});
}

class UnsupportedFailure extends Failure {
  const UnsupportedFailure(String feature, {super.cause, super.stackTrace})
    : super('Unsupported: $feature');
}

class PinRequiredFailure extends Failure {
  const PinRequiredFailure({super.cause, super.stackTrace})
    : super('PIN required');
}

class OperationFailure extends Failure {
  const OperationFailure(super.message, {super.cause, super.stackTrace});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.cause, super.stackTrace})
    : super('Unknown error');
}
