class AppConstants {
  static const String appName = 'PPE Vision';
  static const String appSubtitle = 'Helmet & Safety Vest Detection';
  static const String appDescription =
      'Live computer vision for site PPE compliance. '
      'The camera feed is analyzed for people, helmets, and safety vests, '
      'then each person is scored as compliant or in violation.';
  static const String aboutBlurb = 'Computer Vision Demo';
}

enum DetectionBackend { mock, model }

abstract final class AppStrings {
  static const siteEyebrow = 'SITE SAFETY MONITOR';
  static const startDetection = 'Start Detection';
  static const detectionHistory = 'Detection History';
  static const settings = 'Settings';
  static const capture = 'Capture';
  static const back = 'Back';
  static const mockModeBadge = 'Mock detections · no model required';
  static const modelModeBadge = 'Model provider selected';
  static const captureSaved = 'Saved to detection history';
  static const demoPreview = 'DEMO PREVIEW';
  static const detectionActive = 'Detection active';
  static const detectionIdle = 'Detection idle';
  static const startingCamera = 'Starting camera…';
  static const demoPreviewStatus = 'Demo preview';
  static const cameraUnavailable =
      'Camera unavailable. Showing demo preview with mock detections.';
  static const modelUnimplemented = 'Model detection is not implemented.';
  static const inferenceFailed = 'Detection failed for this frame.';
  static const peopleDetectedSuffix = 'People Detected';
  static const today = 'Today';
  static const yesterday = 'Yesterday';
  static const emptyHistoryTitle = 'No captures yet';
  static const emptyHistoryBody =
      'Use Capture on the detection screen to save a snapshot of the current compliance counts.';
  static const detectionSection = 'Detection';
  static const performanceSection = 'Performance';
  static const aboutSection = 'About';
  static const confidenceThreshold = 'Confidence threshold';
  static const detectionProvider = 'Detection provider';
  static const providerMock = 'Mock';
  static const providerMockSubtitle = 'Functional demo detections';
  static const providerModel = 'Model';
  static const providerModelSubtitle =
      'Not implemented — awaiting TFLite model';
  static const enableOverlay = 'Enable detection overlay';
  static const showConfidence = 'Show confidence scores';
  static const targetInferenceFps = 'Target inference FPS';
  static const showFps = 'Show FPS';
  static const showInferenceTime = 'Show inference time';
  static const people = 'People';
  static const helmets = 'Helmets';
  static const vests = 'Vests';
  static const compliant = 'Compliant';
  static const violations = 'Violations';
  static const noPeopleHeadline = 'NO PEOPLE DETECTED';
  static const compliantHeadline = 'PPE COMPLIANT';
  static const violationHeadline = 'PPE VIOLATION';
  static const waitingForPerson = 'Waiting for a person in frame';
  static const allPpeDetected = 'All required PPE detected';
  static const allPeopleCompliant = 'All detected people are wearing required PPE';
}

abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const hero = 28.0;
  static const screen = 32.0;
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
  static const xl = 14.0;
  static const xxl = 16.0;
}

abstract final class AppLayout {
  static const minTouchTarget = 48.0;
  static const contentMaxWidth = 480.0;
  static const contentBreakpoint = 520.0;
  static const brandMarkSize = 56.0;
  static const overlayStrokePerson = 2.4;
  static const overlayStrokeObject = 2.0;
  static const overlayCorner = 4.0;
  static const overlayLabelPadH = 6.0;
  static const overlayLabelPadV = 4.0;
}

abstract final class AppDurations {
  static const captureToast = Duration(milliseconds: 1400);
}

abstract final class AppPerf {
  static const fpsEmaPrevious = 0.75;
  static const fpsEmaCurrent = 0.25;
}
