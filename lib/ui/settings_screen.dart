import 'package:flutter/material.dart';
import '../sfx.dart';
import '../storage.dart';
import 'how_to_play.dart';
import 'theme.dart';
import 'widgets.dart';

/// Set by the build server (run number) so you can tell which test build is installed.
const _build = String.fromEnvironment('BUILD', defaultValue: 'dev');

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.storage, required this.onReset});
  final Storage storage;
  final VoidCallback onReset;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cocoa,
        title: const Text('Reset all progress?'),
        content: const Text('Scores, cleared levels and unlocks on this device will be erased.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      await widget.storage.resetAll();
      widget.onReset();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
        children: [
          Text('Settings', style: displayFont.copyWith(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: lantern,
              title: const Text('Haptic feedback', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Gentle vibration when you pick up and land a peg.', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
              value: widget.storage.haptics,
              onChanged: (v) async {
                await widget.storage.setHaptics(v);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: lantern,
              title: const Text('Sound effects', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Soft sounds for jumps, undo and unlocks.', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
              value: widget.storage.sound,
              onChanged: (v) async {
                await widget.storage.setSound(v);
                Sfx.enabled = v;
                if (v) Sfx.play('select');
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(children: [
              const Icon(Icons.accessibility_new_rounded, color: lantern),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Animations turn themselves off when "Remove animations" is enabled in your phone\'s accessibility settings.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: Colors.white.withValues(alpha: 0.75)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(children: [
              const Icon(Icons.shield_moon_rounded, color: lantern),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Hopstone works fully offline. No account, no ads, no tracking.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: Colors.white.withValues(alpha: 0.75))),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          PillButton(
            label: 'How to play',
            icon: Icons.help_outline_rounded,
            onTap: () => Navigator.of(context).push(softRoute(HowToPlayScreen(onDone: () => Navigator.pop(context)))),
          ),
          const SizedBox(height: 12),
          PillButton(label: 'Reset progress', icon: Icons.delete_outline_rounded, danger: true, onTap: _confirmReset),
          const SizedBox(height: 18),
          Center(child: Text('Hopstone  ·  build $_build', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)))),
        ],
      );
}
