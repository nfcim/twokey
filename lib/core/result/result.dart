/// Generic Result type representing success (Ok) or failure (Err).
/// Prefer using small, descriptive Failure subclasses for the error side.
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  R match<R>({required R Function(T) ok, required R Function(E) err}) {
    final self = this;
    if (self is Ok<T, E>) return ok(self.value);
    return err((self as Err<T, E>).error);
  }

  T? get okOrNull => switch (this) {
    Ok(:final value) => value,
    _ => null,
  };
  E? get errOrNull => switch (this) {
    Err(:final error) => error,
    _ => null,
  };

  Result<U, E> map<U>(U Function(T value) transform) =>
      match(ok: (v) => Ok(transform(v)), err: (e) => Err(e));

  Result<T, F> mapErr<F>(F Function(E error) transform) =>
      match(ok: (v) => Ok(v), err: (e) => Err(transform(e)));
}

class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
  @override
  String toString() => 'Ok($value)';
}

class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
  @override
  String toString() => 'Err($error)';
}
