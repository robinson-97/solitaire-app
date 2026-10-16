import 'package:flutter/material.dart';
import '../game/worlds.dart';
import '../storage.dart';
import 'background.dart';
import 'collection_screen.dart';
import 'settings_screen.dart';
import 'widgets.dart';
import 'how_to_play.dart';
import 'play_screen.dart';

/// Root screen: animated scenery plus the three main tabs.
class Shell extends StatefulWidget {
  const Shell({super.key, required this.storage});
  final Storage storage;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  late bool intro = !widget.storage.seenIntro;
  final ValueNotifier<World> worldNotifier = ValueNotifier(worlds.first);

  @override
  void dispose() {
    worldNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (intro) {
      return HowToPlayScreen(onDone: () async {
        await widget.storage.setSeenIntro();
        if (mounted) setState(() => intro = false);
      });
    }
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: SceneBackground(world: 'menu')),
        SafeArea(
          bottom: false,
          child: IndexedStack(index: tab, children: [
            PlayPage(storage: widget.storage, worldNotifier: worldNotifier),
            CollectionPage(storage: widget.storage),
            SettingsPage(storage: widget.storage, onReset: () => setState(() {})),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: GlassNavBar(index: tab, onChanged: (i) => setState(() => tab = i)),
          ),
        ),
      ]),
    );
  }
}
