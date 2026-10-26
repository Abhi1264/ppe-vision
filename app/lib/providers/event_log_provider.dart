import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/site_log.dart';

final eventLogProvider = NotifierProvider<EventLogNotifier, SiteLog>(
  EventLogNotifier.new,
);

class EventLogNotifier extends Notifier<SiteLog> {
  static const _key = 'siteLog';
  int _unsavedFrames = 0;

  @override
  SiteLog build() {
    Future<void>(() async {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      state = SiteLog.decode(prefs.getString(_key) ?? '');
    });
    return SiteLog.empty;
  }

  void addFrames(int people, int compliant) {
    if (people <= 0) return;
    state = state.copyWith(
      personFrames: state.personFrames + people,
      compliantFrames: state.compliantFrames + compliant,
    );
    _unsavedFrames += 1;
    if (_unsavedFrames >= 20) unawaited(_save());
  }

  void addEvents(List<SiteEvent> events) {
    if (events.isEmpty) return;
    final next = [...events, ...state.events];
    state = state.copyWith(
      events: next.length > 200 ? next.sublist(0, 200) : next,
    );
    unawaited(_save());
  }

  Future<void> _save() async {
    _unsavedFrames = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.encode());
  }
}
