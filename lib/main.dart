import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sfx.dart';
import 'purchase.dart';
import 'storage.dart';
import 'ui/shaders.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await Storage.open();
  Sfx.enabled = storage.sound;
  await Sfx.init();
  await Gfx.init();
  unawaited(Purchases.init(storage));
  runApp(HopstoneApp(storage: storage));
}

class HopstoneApp extends StatelessWidget {
  const HopstoneApp({super.key, required this.storage});
  final Storage storage;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Hopstone',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Shell(storage: storage),
      );
}
