import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/water_provider.dart';
import '../widgets/water_visualizer.dart';

class WaterTrackerScreen extends StatelessWidget {
  const WaterTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: WaterVisualizer(
            progress: water.progress,
            currentMl: water.todaysTotalMl,
            goalMl: water.dailyGoalMl,
            onTap: () => water.addWater(250),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap the bottle to log 250 ml',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 24),
        Text('Quick Add', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [100, 200, 250, 330, 500].map((ml) {
            return ActionChip(
              avatar: const Icon(Icons.water_drop, size: 18),
              label: Text('$ml ml'),
              onPressed: () => water.addWater(ml),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Log", style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _confirmReset(context, water),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Reset'),
            ),
          ],
        ),
        if (water.todaysEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No water logged yet today.'),
          )
        else
          ...water.todaysEntries.map((e) => ListTile(
                leading: const Icon(Icons.local_drink, color: Colors.blue),
                title: Text('${e.amountMl} ml'),
                subtitle: Text(DateFormat('h:mm a').format(e.timestamp)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => water.removeEntry(e.id),
                ),
              )),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminder Settings',
                    style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hydration reminders'),
                  value: water.remindersEnabled,
                  onChanged: (v) => water.setRemindersEnabled(v),
                ),
                if (water.remindersEnabled)
                  Row(
                    children: [
                      const Text('Every'),
                      Expanded(
                        child: Slider(
                          value: water.reminderIntervalMinutes.toDouble(),
                          min: 30,
                          max: 180,
                          divisions: 5,
                          label: '${water.reminderIntervalMinutes} min',
                          onChanged: (v) =>
                              water.setReminderInterval(v.round()),
                        ),
                      ),
                      Text('${water.reminderIntervalMinutes} min'),
                    ],
                  ),
                Row(
                  children: [
                    const Text('Daily goal'),
                    Expanded(
                      child: Slider(
                        value: water.dailyGoalMl.toDouble(),
                        min: 1000,
                        max: 5000,
                        divisions: 8,
                        label: '${water.dailyGoalMl} ml',
                        onChanged: (v) => water.setDailyGoal(v.round()),
                      ),
                    ),
                    Text('${water.dailyGoalMl} ml'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmReset(BuildContext context, WaterProvider water) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset today's water log?"),
        content: const Text('This will remove all entries logged today.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              water.resetToday();
              Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
