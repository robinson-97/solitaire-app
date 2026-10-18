import 'package:flutter/material.dart';
import '../purchase.dart';
import '../storage.dart';
import 'scenes/scene_view.dart';
import 'theme.dart';
import 'widgets.dart';

/// Offer to unlock the whole game with the one-time purchase.
class PaywallCard extends StatelessWidget {
  const PaywallCard({super.key, this.accent = lantern});
  final Color accent;

  @override
  Widget build(BuildContext context) => GlassCard(
        glow: accent.withValues(alpha: 0.5),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_open_rounded, size: 38, color: accent),
          const SizedBox(height: 10),
          Text('Unlock the full game', textAlign: TextAlign.center, style: displayFont.copyWith(fontSize: 22)),
          const SizedBox(height: 10),
          Text(
            'The first 10 levels are free. Unlock all 400 levels in 20 stages.\nOne payment, no ads, no subscription. Works offline.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: Purchases.product,
            builder: (_, p, _) => SizedBox(
              width: double.infinity,
              child: PillButton(label: p == null ? 'Unlock full game' : 'Unlock full game  ·  ${p.price}', icon: Icons.lock_open_rounded, primary: true, onTap: Purchases.buy),
            ),
          ),
          TextButton(onPressed: Purchases.restore, child: Text('Restore purchase', style: TextStyle(color: Colors.white.withValues(alpha: 0.7)))),
          ValueListenableBuilder<String?>(
            valueListenable: Purchases.message,
            builder: (_, m, _) => m == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(m, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: lantern))),
          ),
        ]),
      );
}

/// Full screen version, opened when someone taps a level that is not free.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.storage});
  final Storage storage;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    Storage.changed.addListener(_check);
  }

  void _check() {
    if (mounted && widget.storage.fullVersion) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    Storage.changed.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(fit: StackFit.expand, children: [
          const SceneBackground(world: 'menu'),
          SafeArea(
            child: Column(children: [
              Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded))),
              Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: const PaywallCard()))),
            ]),
          ),
        ]),
      );
}
