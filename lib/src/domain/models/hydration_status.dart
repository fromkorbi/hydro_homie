enum HydrationLevel { red, yellow, green }

class HydrationStatus {
  final int totalMl;
  final double percentage;
  final HydrationLevel level;

  const HydrationStatus({required this.totalMl, required this.percentage, required this.level});

  static HydrationStatus fromValues(int totalMl, int targetMl) {
    final pct = targetMl <= 0 ? 0.0 : (totalMl / targetMl).clamp(0.0, 1.0);
    final percentage = (pct * 100).toDouble();
    HydrationLevel level;
    if (percentage < 40.0) {
      level = HydrationLevel.red;
    } else if (percentage < 100.0) {
      level = HydrationLevel.yellow;
    } else {
      level = HydrationLevel.green;
    }
    return HydrationStatus(totalMl: totalMl, percentage: percentage, level: level);
  }
}
