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
