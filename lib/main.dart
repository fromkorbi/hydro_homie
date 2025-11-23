import 'src/presentation/main.dart' as app;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> initTimeZones() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
}
Future<void> main() async {
  await initTimeZones();
  await app.main();
}

