import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/hydration_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();
  bool _reminderEnabled = false;
  bool _useWorkManager = false;
  bool _useInexact = false;
  bool _showOngoing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<HydrationState>();
    _controller.text = state.settings.dailyTargetMl.toString();
    final minutes = state.settings.reminderIntervalMinutes;
    if (minutes != null) {
      _reminderEnabled = true;
      _reminderController.text = minutes.toString();
    } else {
      _reminderEnabled = false;
      _reminderController.text = '';
    }
    _useWorkManager = state.settings.useWorkManager;
    _useInexact = state.settings.useInexact;
    _showOngoing = state.settings.showOngoingNotification;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HydrationState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily target (ml)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reminderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reminder interval (minutes)'),
                    enabled: _reminderEnabled,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text('Enable'),
                    Switch(
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: const Text('Use WorkManager (recommended)')),
                Switch(value: _useWorkManager, onChanged: (v) => setState(() => _useWorkManager = v)),
              ],
            ),
            Row(
              children: [
                Expanded(child: const Text('Use inexact AlarmManager')),
                Switch(value: _useInexact, onChanged: (v) => setState(() => _useInexact = v)),
              ],
            ),
            Row(
              children: [
                Expanded(child: const Text('Show persistent status notification')),
                Switch(value: _showOngoing, onChanged: (v) => setState(() => _showOngoing = v)),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(_controller.text) ?? state.settings.dailyTargetMl;
                state.setDailyTarget(value);
                final minutes = int.tryParse(_reminderController.text);
                if (_reminderEnabled && minutes != null && minutes > 0) {
                  state.setReminderInterval(minutes);
                } else if (!_reminderEnabled) {
                  state.setReminderInterval(null);
                }
                state.setUseWorkManager(_useWorkManager);
                state.setUseInexact(_useInexact);
                state.setShowOngoingNotification(_showOngoing);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
