import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/hydration_state.dart';
import '../domain/models/drink_type.dart';
import '../domain/models/hydration_status.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Color _colorForLevel(BuildContext context, int level) {
    switch (level) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.yellow[700]!;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HydrationState>();
    final status = state.status;
    final levelIndex = status.level == HydrationLevel.red
      ? 0
      : (status.level == HydrationLevel.yellow ? 1 : 2);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydro Homie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug info
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reminder: ${state.settings.reminderIntervalMinutes ?? "OFF"} min', style: const TextStyle(fontSize: 12)),
                  Text('WorkManager: ${state.settings.useWorkManager}', style: const TextStyle(fontSize: 12)),
                  Text('Inexact: ${state.settings.useInexact}', style: const TextStyle(fontSize: 12)),
                  Text('LastNotif: ${state.lastNativeNotification?.timestamp ?? "none"}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.lastNativeNotification != null)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.lastNativeNotification!.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              state.lastNativeNotification!.body,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            Text(
                              state.lastNativeNotification!.timestamp.toLocal().toString().split('.')[0],
                              style: const TextStyle(fontSize: 11, color: Colors.black38),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('${state.dailyTotal} / ${state.settings.dailyTargetMl} ml', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: state.percentage),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 20, height: 20, decoration: BoxDecoration(color: _colorForLevel(context, levelIndex), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('${status.percentage.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Quick log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (ctx, i) {
                  final dt = state.favorites[i];
                  return ElevatedButton(
                    onPressed: () => state.addDrink(dt),
                    child: Text('${dt.name} • ${dt.defaultSizeMl}ml'),
                  );
                },
                separatorBuilder: (BuildContext ctx, int idx) => const SizedBox(width: 8),
                itemCount: state.favorites.length,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: state.entries.length,
                itemBuilder: (ctx, i) {
                  final e = state.entries[i];
                  final dt = state.drinkTypes.firstWhere((d) => d.id == e.drinkTypeId, orElse: () => DrinkType(id: e.drinkTypeId, name: e.drinkTypeId, defaultSizeMl: e.sizeMl));
                  return ListTile(
                    title: Text('${dt.name} • ${e.sizeMl} ml'),
                    subtitle: Text('${e.timestamp.toLocal()}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await state.resetToday();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
