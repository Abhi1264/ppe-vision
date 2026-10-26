import 'dart:convert';

class SiteEvent {
  const SiteEvent({
    required this.type,
    required this.camera,
    required this.at,
  });

  final String type;
  final String camera;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'type': type,
    'camera': camera,
    'at': at.toIso8601String(),
  };

  factory SiteEvent.fromJson(Map<String, dynamic> json) {
    return SiteEvent(
      type: json['type'] as String,
      camera: json['camera'] as String,
      at: DateTime.parse(json['at'] as String),
    );
  }
}

class SiteLog {
  const SiteLog({
    this.events = const [],
    this.personFrames = 0,
    this.compliantFrames = 0,
  });

  static const empty = SiteLog();

  final List<SiteEvent> events;
  final int personFrames;
  final int compliantFrames;

  double? get complianceRate =>
      personFrames == 0 ? null : compliantFrames / personFrames;

  SiteLog copyWith({
    List<SiteEvent>? events,
    int? personFrames,
    int? compliantFrames,
  }) {
    return SiteLog(
      events: events ?? this.events,
      personFrames: personFrames ?? this.personFrames,
      compliantFrames: compliantFrames ?? this.compliantFrames,
    );
  }

  List<SiteEvent> where({String type = '', String camera = '', String day = ''}) {
    return [
      for (final event in events)
        if ((type.isEmpty || event.type == type) &&
            (camera.isEmpty || event.camera.contains(camera)) &&
            (day.isEmpty || _day(event.at) == day))
          event,
    ];
  }

  Map<String, int> counts(String Function(SiteEvent event) key) {
    final out = <String, int>{};
    for (final event in events) {
      final name = key(event);
      out[name] = (out[name] ?? 0) + 1;
    }
    return out;
  }

  String toCsv() {
    final lines = <String>['at,type,camera'];
    for (final event in events) {
      lines.add('${event.at.toIso8601String()},${event.type},${event.camera}');
    }
    return lines.join('\n');
  }

  String encode() => jsonEncode({
    'events': [for (final event in events) event.toJson()],
    'personFrames': personFrames,
    'compliantFrames': compliantFrames,
  });

  factory SiteLog.decode(String raw) {
    if (raw.isEmpty) return SiteLog.empty;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return SiteLog.empty;
      final events = json['events'];
      return SiteLog(
        events: [
          if (events is List)
            for (final item in events)
              if (item is Map)
                SiteEvent.fromJson(Map<String, dynamic>.from(item)),
        ],
        personFrames: json['personFrames'] as int? ?? 0,
        compliantFrames: json['compliantFrames'] as int? ?? 0,
      );
    } catch (_) {
      return SiteLog.empty;
    }
  }
}

String _day(DateTime at) {
  final local = at.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
