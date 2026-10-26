import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LiveTrack {
  const LiveTrack({
    required this.trackId,
    required this.confidence,
    required this.person,
    this.hardhat,
    this.vest,
    required this.missing,
  });

  final int trackId;
  final double confidence;
  final List<double> person;
  final List<double>? hardhat;
  final List<double>? vest;
  final List<String> missing;

  factory LiveTrack.fromJson(Map<String, dynamic> json) {
    return LiveTrack(
      trackId: json['track_id'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      person: _box(json['person']),
      hardhat: json['hardhat'] == null ? null : _box(json['hardhat']),
      vest: json['vest'] == null ? null : _box(json['vest']),
      missing: [for (final item in json['missing'] as List) item as String],
    );
  }
}

class LiveView {
  const LiveView({
    required this.cameraId,
    required this.width,
    required this.height,
    required this.tracks,
    required this.opened,
    this.jpeg,
  });

  final String cameraId;
  final int width;
  final int height;
  final List<LiveTrack> tracks;
  final List<Map<String, dynamic>> opened;
  final Uint8List? jpeg;

  factory LiveView.fromJson(Map<String, dynamic> json) {
    final encoded = json['jpeg_base64'] as String?;
    return LiveView(
      cameraId: json['camera_id'] as String,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      tracks: [
        for (final item in json['tracks'] as List)
          LiveTrack.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      opened: [
        for (final item in json['opened'] as List? ?? const [])
          Map<String, dynamic>.from(item as Map),
      ],
      jpeg: encoded == null ? null : base64Decode(encoded),
    );
  }
}

class PpeEvent {
  const PpeEvent({
    required this.id,
    required this.timestamp,
    required this.trackId,
    required this.violationType,
    required this.confidence,
    required this.startTime,
    required this.endTime,
    required this.cameraId,
    required this.hasSnapshot,
  });

  final int id;
  final String timestamp;
  final int trackId;
  final String violationType;
  final double confidence;
  final String startTime;
  final String? endTime;
  final String cameraId;
  final bool hasSnapshot;

  factory PpeEvent.fromJson(Map<String, dynamic> json) {
    final path = json['snapshot_path'] as String?;
    return PpeEvent(
      id: json['id'] as int,
      timestamp: json['timestamp'] as String,
      trackId: json['track_id'] as int,
      violationType: json['violation_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      cameraId: json['camera_id'] as String,
      hasSnapshot: path != null && path.isNotEmpty,
    );
  }
}

class PpeStats {
  const PpeStats({
    required this.events,
    required this.byType,
    required this.byHour,
    required this.byDay,
    required this.tracks,
    required this.personFrames,
    required this.compliantFrames,
    required this.complianceRate,
  });

  final int events;
  final Map<String, int> byType;
  final Map<String, int> byHour;
  final Map<String, int> byDay;
  final List<Map<String, dynamic>> tracks;
  final int personFrames;
  final int compliantFrames;
  final double? complianceRate;

  factory PpeStats.fromJson(Map<String, dynamic> json) {
    return PpeStats(
      events: json['events'] as int,
      byType: _counts(json['by_type']),
      byHour: _counts(json['by_hour']),
      byDay: _counts(json['by_day']),
      tracks: [
        for (final item in json['tracks'] as List)
          Map<String, dynamic>.from(item as Map),
      ],
      personFrames: json['person_frames'] as int,
      compliantFrames: json['compliant_frames'] as int,
      complianceRate: (json['compliance_rate'] as num?)?.toDouble(),
    );
  }
}

class PpeApi {
  const PpeApi();

  Future<String> healthError(String base) async {
    final body = await _json(base, '/health', timeout: const Duration(seconds: 3));
    if (body['ok'] == true) return '';
    return (body['error'] as String?) ?? 'Model is not loaded';
  }

  Future<void> startJob({
    required String base,
    required String source,
    required String cameraId,
    required String required,
    required int confirmFrames,
    required double conf,
  }) async {
    await _send(
      () => http.post(
        _uri(base, '/jobs'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'source': source,
          'camera_id': cameraId,
          'required': required,
          'confirm_frames': confirmFrames,
          'conf': conf,
        }),
      ),
    );
  }

  Future<void> stopJob(String base) async {
    try {
      await _send(() => http.post(_uri(base, '/jobs/stop')));
    } on ApiException {
      // Stopping a server that is already gone is not a failure.
    }
  }

  Future<LiveView> live(String base, String cameraId) async {
    final body = await _json(
      base,
      '/live',
      query: {'camera_id': cameraId, 'image': '1'},
    );
    return LiveView.fromJson(body);
  }

  Future<LiveView> postFrame({
    required String base,
    required Uint8List rgb,
    required int width,
    required int height,
    required String cameraId,
    required String required,
    required int confirmFrames,
    required double conf,
  }) async {
    final request = http.MultipartRequest('POST', _uri(base, '/frames'));
    request.fields.addAll({
      'camera_id': cameraId,
      'required': required,
      'confirm_frames': '$confirmFrames',
      'conf': '$conf',
      'encoding': 'rgb',
      'width': '$width',
      'height': '$height',
    });
    request.files.add(
      http.MultipartFile.fromBytes('file', rgb, filename: 'frame.rgb'),
    );
    final response = await _timed(request.send().then(http.Response.fromStream));
    final body = _decode(response);
    return LiveView.fromJson(body);
  }

  Future<List<PpeEvent>> events({
    required String base,
    String? violationType,
    String? cameraId,
    String? start,
    String? end,
  }) async {
    final body = await _send(
      () => http.get(
        _uri(base, '/events', {
          if (violationType != null && violationType.isNotEmpty)
            'violation_type': violationType,
          if (cameraId != null && cameraId.isNotEmpty) 'camera_id': cameraId,
          if (start != null && start.isNotEmpty) 'start': start,
          if (end != null && end.isNotEmpty) 'end': end,
        }),
      ),
    );
    final decoded = jsonDecode(body);
    if (decoded is! List) throw const ApiException('Event list was not a list');
    return [
      for (final item in decoded)
        PpeEvent.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<Uint8List> snapshot(String base, int id) async {
    final response = await _timed(http.get(_uri(base, '/events/$id/snapshot')));
    if (response.statusCode != 200) {
      throw ApiException('Snapshot failed (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  Future<PpeStats> stats(String base, {String? cameraId}) async {
    final body = await _json(
      base,
      '/stats',
      query: {if (cameraId != null && cameraId.isNotEmpty) 'camera_id': cameraId},
    );
    return PpeStats.fromJson(body);
  }

  Future<String> report(String base) async {
    final response = await _timed(http.get(_uri(base, '/report')));
    if (response.statusCode != 200) {
      throw ApiException('Report failed (${response.statusCode})');
    }
    return response.body;
  }

  Future<String> csv(String base) async {
    final response = await _timed(http.get(_uri(base, '/events.csv')));
    if (response.statusCode != 200) {
      throw ApiException('CSV failed (${response.statusCode})');
    }
    return response.body;
  }

  Future<Map<String, dynamic>> _json(
    String base,
    String path, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final response = await _timed(http.get(_uri(base, path, query)), timeout);
    return _decode(response);
  }

  Future<String> _send(Future<http.Response> Function() call) async {
    final response = await _timed(call());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_error(response));
    }
    return response.body;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_error(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const ApiException('Unexpected response');
    return Map<String, dynamic>.from(decoded);
  }

  String _error(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return 'Server responded ${response.statusCode}';
  }

  Future<T> _timed<T>(Future<T> future, [Duration timeout = const Duration(seconds: 8)]) {
    return future.timeout(
      timeout,
      onTimeout: () => throw const ApiException('Server timed out'),
    );
  }
}

Uri _uri(String base, String path, [Map<String, String>? query]) {
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return Uri.parse('$root$path').replace(queryParameters: query);
}

List<double> _box(Object? raw) {
  final values = raw as List;
  return [for (final value in values) (value as num).toDouble()];
}

Map<String, int> _counts(Object? raw) {
  final map = Map<String, dynamic>.from(raw as Map? ?? const {});
  return {for (final entry in map.entries) entry.key: entry.value as int};
}
