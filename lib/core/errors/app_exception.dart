class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class CameraPermissionDeniedException extends AppException {
  const CameraPermissionDeniedException([
    super.message =
        'Camera permission was denied. Enable it in system settings to run live detection.',
  ]);
}

class CameraUnavailableException extends AppException {
  const CameraUnavailableException([
    super.message = 'No camera is available on this device.',
  ]);
}

class CameraInitializationException extends AppException {
  const CameraInitializationException([
    super.message = 'The camera could not be initialized.',
    Object? cause,
  ]) : super(cause: cause);
}

class ModelUnavailableException extends AppException {
  const ModelUnavailableException([
    super.message =
        'The detection model is not available yet. Switch to Mock in Settings.',
  ]);
}

class ModelInitializationException extends AppException {
  const ModelInitializationException([
    super.message = 'The detection model failed to initialize.',
    Object? cause,
  ]) : super(cause: cause);
}

class InferenceException extends AppException {
  const InferenceException([
    super.message = 'Detection failed for this frame.',
    Object? cause,
  ]) : super(cause: cause);
}

class InvalidFrameException extends AppException {
  const InvalidFrameException([
    super.message = 'The camera frame could not be processed.',
    Object? cause,
  ]) : super(cause: cause);
}
