import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import '../services/api/ppe_api.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _type = '';
  final _camera = TextEditingController();
  final _day = TextEditingController();
  bool _loading = true;
  String? _error;
  List<PpeEvent> _events = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _camera.dispose();
    _day.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final day = _day.text.trim();
    try {
      final events = await const PpeApi().events(
        base: ref.read(settingsProvider).serverUrl,
        violationType: _type.isEmpty ? null : _type,
        cameraId: _camera.text.trim().isEmpty ? null : _camera.text.trim(),
        start: day.isEmpty ? null : '${day}T00:00:00',
        end: day.isEmpty ? null : '${day}T23:59:59',
      );
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _events = const [];
      });
    }
  }

  Future<void> _copyCsv() async {
    try {
      final csv = await const PpeApi().csv(ref.read(settingsProvider).serverUrl);
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied events CSV')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event log'),
        actions: [
          IconButton(
            tooltip: 'Copy CSV',
            onPressed: _copyCsv,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Violation'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All types')),
                    DropdownMenuItem(value: 'missing_hardhat', child: Text('Missing hardhat')),
                    DropdownMenuItem(value: 'missing_vest', child: Text('Missing vest')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? ''),
                ),
                TextField(
                  controller: _camera,
                  decoration: const InputDecoration(labelText: 'Camera id'),
                ),
                TextField(
                  controller: _day,
                  decoration: const InputDecoration(labelText: 'Day (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: _load, child: const Text('Apply')),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No violation events for this filter. An event is logged after the same track is missing required PPE for the configured number of frames.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = _events[index];
        return ListTile(
          tileColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(event.violationType),
          subtitle: Text(
            'track ${event.trackId} · camera ${event.cameraId}\n${event.startTime} → ${event.endTime ?? 'open'}',
          ),
          isThreeLine: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EventDetailScreen(event: event),
              ),
            );
          },
        );
      },
    );
  }
}

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final PpeEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(settingsProvider).serverUrl;
    return Scaffold(
      appBar: AppBar(title: Text('Event ${event.id}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (event.hasSnapshot)
            FutureBuilder<Uint8List>(
              future: const PpeApi().snapshot(base, event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text('Snapshot unavailable. ${snapshot.error ?? ''}');
                }
                return Image.memory(snapshot.data!);
              },
            )
          else
            const Text('No snapshot was saved for this event.'),
          const SizedBox(height: 16),
          Text('Type: ${event.violationType}'),
          Text('Track: ${event.trackId}'),
          Text('Camera: ${event.cameraId}'),
          Text('Confidence: ${event.confidence}'),
          Text('Logged: ${event.timestamp}'),
          Text('Started: ${event.startTime}'),
          Text('Ended: ${event.endTime ?? 'still open'}'),
        ],
      ),
    );
  }
}
