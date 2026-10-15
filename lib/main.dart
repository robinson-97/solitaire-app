import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await Storage.open();
  runApp(GlimmerwoodApp(storage: storage));
}

class GlimmerwoodApp extends StatelessWidget {
  const GlimmerwoodApp({super.key, required this.storage});
  final Storage storage;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Glimmerwood',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: HomeScreen(storage: storage),
      );
}
