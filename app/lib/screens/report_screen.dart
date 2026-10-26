import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import '../services/api/ppe_api.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _loading = true;
  String? _error;
  PpeStats? _stats;
  String _report = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final base = ref.read(settingsProvider).serverUrl;
    try {
      final stats = await const PpeApi().stats(base);
      final report = await const PpeApi().report(base);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _report = report;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
        actions: [
          IconButton(
            tooltip: 'Copy report',
            onPressed: _report.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: _report));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied report')),
                    );
                  },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final stats = _stats!;
    final days = stats.byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final hours = stats.byHour.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Events: ${stats.events}'),
        const SizedBox(height: 8),
        Text(
          stats.complianceRate == null
              ? 'Compliance rate: not available yet. It needs person frames from a running camera.'
              : 'Compliance rate: ${stats.compliantFrames}/${stats.personFrames} person-frames (${stats.complianceRate})',
        ),
        const SizedBox(height: 16),
        const Text('By type'),
        if (stats.byType.isEmpty) const Text('None'),
        for (final entry in stats.byType.entries) Text('${entry.key}: ${entry.value}'),
        const SizedBox(height: 16),
        const Text('By day'),
        if (days.isEmpty) const Text('None'),
        for (final entry in days) Text('${entry.key}: ${entry.value}'),
        const SizedBox(height: 16),
        const Text('By hour'),
        if (hours.isEmpty) const Text('None'),
        for (final entry in hours) Text('${entry.key}: ${entry.value}'),
        const SizedBox(height: 16),
        const Text('Repeat tracks'),
        if (stats.tracks.isEmpty) const Text('None'),
        for (final track in stats.tracks)
          Text(
            'camera ${track['camera_id']} track ${track['track_id']}: ${track['events']} events',
          ),
        const SizedBox(height: 12),
        const Text(
          'A track id is the tracker\'s number for a person in one session. It is not an identity.',
        ),
      ],
    );
  }
}
