import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/event_log_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _type = '';
  final _camera = TextEditingController();
  final _day = TextEditingController();

  @override
  void dispose() {
    _camera.dispose();
    _day.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref
        .watch(eventLogProvider)
        .where(type: _type, camera: _camera.text.trim(), day: _day.text.trim());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event log'),
        actions: [
          IconButton(
            tooltip: 'Copy CSV',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: ref.read(eventLogProvider).toCsv()),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied events CSV')),
              );
            },
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type, camera, and day',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Violation type',
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All types')),
                    DropdownMenuItem(
                      value: 'missing_hardhat',
                      child: Text('Missing hardhat'),
                    ),
                    DropdownMenuItem(
                      value: 'missing_vest',
                      child: Text('Missing vest'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? ''),
                ),
                TextField(
                  controller: _camera,
                  decoration: const InputDecoration(
                    labelText: 'Camera',
                    hintText: 'front or back',
                  ),
                  onSubmitted: (_) => setState(() {}),
                ),
                TextField(
                  controller: _day,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    hintText: 'YYYY-MM-DD',
                  ),
                  onSubmitted: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No events for this filter. An event is logged after required gear stays missing for the number of frames set in Settings.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListTile(
                        tileColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.hairline),
                        ),
                        title: Text(_label(event.type)),
                        subtitle: Text('${event.camera} · ${_stamp(event.at)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _label(String type) {
  return switch (type) {
    'missing_hardhat' => 'Missing hardhat',
    'missing_vest' => 'Missing vest',
    _ => type,
  };
}

String _stamp(DateTime at) {
  final local = at.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
