// Screens outside the bar: the flame alert (full screen, cannot be turned off) and "I can't see the greenhouse".
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

class FireScreen extends StatelessWidget {
  const FireScreen({super.key, required this.onAck});
  final VoidCallback onAck;
  @override
  Widget build(BuildContext context) {
    final g = (store.me?['greenhouse'] as J?) ?? {};
    final phone = (g['contact_phone'] as String?) ?? '';
    return Material(color: C.flame, child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(26, 40, 26, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(alignment: Alignment.centerLeft, child: Transform.rotate(angle: -.07, child: Container(width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.white, borderRadius: leaf(30, 8)), alignment: Alignment.center,
              child: const Ic('flame', size: 46, color: C.flame)))),
          const SizedBox(height: 26),
          Text('A flame in the greenhouse.', style: sora(36, w: FontWeight.w800, color: Colors.white, height: 1.1)),
          const SizedBox(height: 16),
          Text('The alarm is sounding on site. The pump and the fan are cut.', style: nunito(19, color: Colors.white)),
          const Spacer(),
          Btn("I saw it, I'm checking", kind: BtnKind.white, onTap: onAck),
          if (phone.isNotEmpty) LinkText('Call ${g['contact_name'] ?? 'the contact'}', light: true,
              onTap: () => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')))),
        ]))));
  }
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = store.st?['sensors'] as J?;
    return Material(color: C.kraft, child: SafeArea(child: Pad(scroll: false, children: [
      const SizedBox(height: 30),
      svg(offlineSvg, height: 120),
      const SizedBox(height: 20),
      Text("I can't see the greenhouse anymore.", style: sora(30, w: FontWeight.w800, height: 1.12)),
      const SizedBox(height: 12),
      Text("Last news: ${s == null ? '–' : hm(s['timestamp'])}. Check that this phone is on the greenhouse's Wi-Fi.", style: nunito(17, color: C.ink2)),
      if (s != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(
          'At ${hm(s['timestamp'])}: soil ${pct(s['soil_pct'])} %, tank ${pct(s['water_level_pct'])} %, air ${pct(s['air_temp'])} °C.',
          style: nunito(17, color: C.ink2))),
      const Spacer(),
      Text('The flame alarm still sounds on site.', textAlign: TextAlign.center, style: nunito(14, color: C.ink2)),
      const SizedBox(height: 10),
      Btn('Try again', kind: BtnKind.forest, onTap: store.reconnect),
    ])));
  }
}
