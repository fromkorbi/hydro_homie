import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/hydration_state.dart';

class LogDrinkPage extends StatelessWidget {
  const LogDrinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HydrationState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Log Drink')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select drink to log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: state.drinkTypes.length,
                itemBuilder: (ctx, i) {
                  final dt = state.drinkTypes[i];
                  return ListTile(
                    title: Text('${dt.name} • ${dt.defaultSizeMl} ml'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await state.addDrink(dt);
                        navigator.pop();
                      },
                      child: const Text('Log'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
